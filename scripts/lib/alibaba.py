"""Alibaba Cloud Coding Plan model catalog scraper.

Parses the public coding-plan docs page and extracts the recommended
models marked in bold, then composes a schema v2 payload. Uses
BeautifulSoup for robust HTML handling.
"""
from __future__ import annotations

import datetime as _dt
from typing import Callable, List

from . import classify as _classify

DEFAULT_PAGE_URL = "https://www.alibabacloud.com/help/en/model-studio/coding-plan"
DEFAULT_OPENAI_ENDPOINT = "https://coding-intl.dashscope.aliyuncs.com/v1"
DEFAULT_ANTHROPIC_ENDPOINT = "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic"

VENDOR_SHORT = "alibaba"
API_KEY_VAR = "LLM_ALIBABA_API_KEY"
SIGNUP_URL = "https://www.alibabacloud.com/campaign/benefits?referral_code=A92LUX"


def live_fetch_html(url: str = DEFAULT_PAGE_URL) -> str:
    """Fetch the coding-plan docs page. Raises on transport error."""
    import requests  # noqa: WPS433

    resp = requests.get(url, timeout=30, headers={"User-Agent": "llm-env-scraper/1.0"})
    resp.raise_for_status()
    return resp.text


def extract_recommended_models(html: str) -> List[str]:
    """Return the list of recommended-model names from the HTML.

    The coding-plan page contains a paragraph of the form:

        Recommended: <b>qwen3.5-plus</b> (vision), <b>kimi-k2.5</b>...

    We locate the paragraph by its leading "Recommended:" text, then
    extract every <b> or <strong> child as a candidate model name.
    Returns an empty list if the marker is missing.
    """
    try:
        from bs4 import BeautifulSoup  # noqa: WPS433
    except ImportError:
        return []

    soup = BeautifulSoup(html, "html.parser")
    for p in soup.find_all(["p", "div", "li", "span"]):
        text = (p.get_text() or "").strip()
        if not text.lower().startswith("recommended"):
            continue
        names: List[str] = []
        for bold in p.find_all(["b", "strong"]):
            name = (bold.get_text() or "").strip()
            if name:
                names.append(name)
        if names:
            return names
    return []


def _now_utc_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _description_for(name: str) -> str:
    return f"{name} - Recommended coding model from Alibaba Cloud Coding Plan"


def build_v2_payload(
    *,
    fetch_html: Callable[[str], str] = live_fetch_html,
    page_url: str = DEFAULT_PAGE_URL,
) -> dict:
    """Compose a schema v2 payload from the alibaba coding-plan page."""
    html = fetch_html(page_url)
    names = extract_recommended_models(html)

    seen_ids: set[str] = set()
    candidates: list[dict] = []

    for upstream in names:
        result = _classify.classify(upstream)
        if result.get("family") is None or result.get("version") is None:
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

    models_out: list[dict] = []
    for cand in candidates:
        models_out.append({
            "id": cand["id"],
            "family": cand["family"],
            "version": cand["version"],
            "description": _description_for(cand["upstream_id"]),
            "protocols": ["openai", "anthropic"],
            "upstream_id": cand["upstream_id"],
        })

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
        "source": "alibaba",
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
