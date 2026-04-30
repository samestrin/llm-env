"""Synthetic.new model catalog scraper.

Builds a schema v2 quickstart payload from synthetic's /openai/v1/models
endpoint. Per-model anthropic-protocol availability is decided by a
probe callable. Both ``fetch`` and ``probe_anthropic`` are passed in
to keep the pure transformation logic testable.
"""
from __future__ import annotations

import datetime as _dt
import os
from typing import Callable, Iterable, Optional

from . import classify as _classify

DEFAULT_MODELS_URL = "https://api.synthetic.new/openai/v1/models"
DEFAULT_OPENAI_ENDPOINT = "https://api.synthetic.new/openai/v1"
DEFAULT_ANTHROPIC_ENDPOINT = "https://api.synthetic.new/anthropic/v1"
DEFAULT_ANTHROPIC_PROBE_URL = "https://api.synthetic.new/anthropic/v1/messages"

VENDOR_SHORT = "synth"
API_KEY_VAR = "LLM_SYNTHETIC_API_KEY"
SIGNUP_URL = "https://synthetic.new/?referral=ugceNlJ08A3Eeww"


# --- Live fetch / probe (production callables) ------------------------------


def live_fetch(url: str = DEFAULT_MODELS_URL) -> dict:
    """Fetch the synthetic /models payload. Raises on transport error."""
    import requests  # noqa: WPS433  - imported lazily

    api_key = os.environ.get(API_KEY_VAR, "")
    headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}
    resp = requests.get(url, headers=headers, timeout=30)
    resp.raise_for_status()
    return resp.json()


def live_probe_anthropic(model_id: str) -> bool:
    """Probe whether ``model_id`` is reachable via the anthropic endpoint.

    Sends a 1-token messages request. Returns True for 2xx and for 4xx
    responses that are *not* "model not found"-shaped (e.g. 401 means
    the model exists but auth failed, which is fine — we only care
    about whether the route resolves the model). Returns False on
    404 / model-not-found / connection failure.
    """
    import requests  # noqa: WPS433

    api_key = os.environ.get(API_KEY_VAR)
    if not api_key:
        return False

    try:
        resp = requests.post(
            DEFAULT_ANTHROPIC_PROBE_URL,
            headers={
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": model_id,
                "max_tokens": 1,
                "messages": [{"role": "user", "content": "ping"}],
            },
            timeout=20,
        )
    except Exception:
        return False

    if 200 <= resp.status_code < 300:
        return True
    # 404 or messages mentioning model issues → unsupported.
    text = (resp.text or "").lower()
    if resp.status_code == 404:
        return False
    if "model" in text and ("not found" in text or "unknown" in text or "not available" in text):
        return False
    # Any other 4xx (rate limit, auth) means the route resolves the
    # model — count it as supported.
    return True


# --- Pure transformation ----------------------------------------------------


def _now_utc_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _description_for(family: str, version: str, subtype: Optional[str], upstream: str) -> str:
    fam = family.upper() if family in ("glm",) else family.capitalize()
    parts = [fam]
    if version and version != "0":
        parts.append(version)
    if subtype:
        parts.append(subtype.capitalize())
    return f"{' '.join(parts)} from synthetic.new"


def build_v2_payload(
    *,
    fetch: Callable[[str], dict] = live_fetch,
    probe_anthropic: Callable[[str], bool] = live_probe_anthropic,
    ai_classify: Callable[[str], Optional[dict]] = None,
    models_url: str = DEFAULT_MODELS_URL,
) -> dict:
    """Fetch synthetic's catalog and produce a schema v2 payload.

    The ``fetch``, ``probe_anthropic``, and ``ai_classify`` callables
    are dependency-injected so unit tests run offline. Production
    callers can omit them to use the live HTTP wrappers.

    ``ai_classify`` is invoked for any model the deterministic
    classifier rates "low" confidence. Pass a no-op
    (``lambda name: None``) to disable AI fallback.
    """
    raw = fetch(models_url)
    if not isinstance(raw, dict):
        raise ValueError("synthetic /models payload was not a dict")
    raw_models: Iterable[dict] = raw.get("data", []) or []

    seen_ids: set[str] = set()
    candidates: list[dict] = []

    for entry in raw_models:
        upstream = entry.get("id")
        if not isinstance(upstream, str) or not upstream.strip():
            continue

        # Drop quantization variants outright.
        if _classify.is_quantization_variant(upstream):
            continue

        # Drop non-chat models.
        if _classify.is_non_chat(upstream):
            continue

        # Classify deterministically; fall back to AI if low confidence.
        result = _classify.classify(upstream)
        if result["confidence"] != "high" and ai_classify is not None:
            ai = ai_classify(upstream)
            if ai is not None:
                result = ai
        elif result["confidence"] != "high":
            # Default fallback path uses classify_with_fallback's logic
            # but lets caller skip AI by passing ai_classify=lambda _: None
            ai = _classify.ai_classify(upstream)
            if ai is not None:
                result = ai

        if result.get("family") is None or result.get("version") is None:
            # Couldn't classify — drop rather than emit garbage.
            continue

        norm_id = _classify.normalize_id(upstream)
        if norm_id in seen_ids:
            continue
        seen_ids.add(norm_id)

        candidates.append({
            "id": norm_id,
            "family": result["family"],
            "subtype": result.get("subtype"),
            "version": result["version"],
            "size_b": result.get("size_b"),
            "upstream_id": upstream,
        })

    # Probe anthropic per model.
    models_out: list[dict] = []
    for cand in candidates:
        protocols = ["openai"]
        if probe_anthropic(cand["upstream_id"]):
            protocols.append("anthropic")
        models_out.append({
            "id": cand["id"],
            "family": cand["family"],
            "version": cand["version"],
            "description": _description_for(
                cand["family"], cand["version"], cand.get("subtype"), cand["upstream_id"],
            ),
            "protocols": protocols,
            "upstream_id": cand["upstream_id"],
        })

    # Build family_latest by picking the highest-version model per
    # effective family.
    by_family: dict[str, list[dict]] = {}
    for cand in candidates:
        fam_key = _classify.effective_family(cand["family"], cand.get("subtype"))
        if fam_key is None:
            continue
        by_family.setdefault(fam_key, []).append(cand)

    family_latest: dict[str, str] = {}
    for fam_key, group in by_family.items():
        winner = _classify.pick_latest(group)
        if winner is not None:
            family_latest[fam_key] = winner["id"]

    return {
        "schema_version": "2",
        "generated_at": _now_utc_iso(),
        "source": "synthetic",
        "vendor_short": VENDOR_SHORT,
        "endpoints": {
            "openai": DEFAULT_OPENAI_ENDPOINT,
            "anthropic": DEFAULT_ANTHROPIC_ENDPOINT,
        },
        "api_key_var": API_KEY_VAR,
        "signup_url": SIGNUP_URL,
        "models": models_out,
        "family_latest": family_latest,
    }
