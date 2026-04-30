"""Alibaba Cloud Coding Plan model catalog scraper.

Parses the public coding-plan docs page and extracts the recommended
models marked in bold, then composes a schema v2 payload.

Cache-bust strategy: the alibaba CDN aggressively serves stale content
to non-Chinese-region clients (no Cache-Control / ETag / Last-Modified
in responses). Direct curl from US-West edges sees content days behind
what users in-browser see. To work around this we route the fetch
through r.jina.ai's reader proxy, which egresses from a different
region and returns fresh content (verified empirically). The reader
returns markdown rather than HTML; we parse both formats.

Direct HTML fetch is kept as a fallback for the case where the
proxy is unreachable.
"""
from __future__ import annotations

import datetime as _dt
import re
from typing import Callable, List

from . import classify as _classify

DEFAULT_PAGE_URL = "https://www.alibabacloud.com/help/en/model-studio/coding-plan"
DEFAULT_PROXY_URL = "https://r.jina.ai/" + DEFAULT_PAGE_URL
DEFAULT_OPENAI_ENDPOINT = "https://coding-intl.dashscope.aliyuncs.com/v1"
DEFAULT_ANTHROPIC_ENDPOINT = "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic"

VENDOR_SHORT = "alibaba"
API_KEY_VAR = "LLM_ALIBABA_API_KEY"
SIGNUP_URL = "https://www.alibabacloud.com/campaign/benefits?referral_code=A92LUX"

# Markers used by both parsers to locate the "Recommended models" line.
# Tolerate "Recommended:" (legacy phrasing) and "Recommended models:" (current).
_RECOMMENDED_PREFIX_RE = re.compile(r"recommended(?:\s+models)?\s*:", re.IGNORECASE)


def live_fetch_html(url: str = DEFAULT_PAGE_URL) -> str:
    """Fetch the coding-plan docs page.

    Tries the Jina reader proxy first (returns markdown, but reflects
    the freshest content). Falls back to direct HTML fetch if the
    proxy is unreachable.

    Returns the response body as a string. Caller must inspect format
    via :func:`looks_like_markdown` and dispatch to the right parser.
    """
    import requests  # noqa: WPS433

    proxy_url = "https://r.jina.ai/" + url
    try:
        resp = requests.get(
            proxy_url,
            timeout=30,
            headers={"User-Agent": "llm-env-scraper/1.0"},
        )
        resp.raise_for_status()
        return resp.text
    except Exception:  # noqa: BLE001
        # Direct fetch fallback. May be stale but better than empty.
        resp = requests.get(
            url, timeout=30, headers={"User-Agent": "llm-env-scraper/1.0"},
        )
        resp.raise_for_status()
        return resp.text


def looks_like_markdown(text: str) -> bool:
    """Heuristic: does this look like markdown rather than HTML?

    The Jina reader emits a ``Title:``/``URL Source:``/``Markdown Content:``
    preamble that's a strong signal. Falls back to checking for
    ``<html>``/``<body>`` markers.
    """
    head = text[:500].lower()
    if "markdown content:" in head or "url source:" in head:
        return True
    if "<html" in head or "<body" in head:
        return False
    # Count rough density of HTML tags vs markdown bold markers.
    html_tags = len(re.findall(r"<[a-z][^>]*>", text[:2000], re.IGNORECASE))
    md_bolds = len(re.findall(r"\*\*[^*]+\*\*", text[:2000]))
    return md_bolds > html_tags


def extract_recommended_models(text: str) -> List[str]:
    """Return the list of recommended-model names from the page text.

    Dispatches to the markdown or HTML parser based on the input shape.
    Returns an empty list if the "Recommended models" marker is
    missing or the parser can't extract any names.
    """
    if looks_like_markdown(text):
        return _extract_from_markdown(text)
    return _extract_from_html(text)


def _extract_from_markdown(text: str) -> List[str]:
    """Extract bolded names from a markdown line that begins with
    "Recommended models:" (or "Recommended:" — legacy phrasing).
    """
    for line in text.splitlines():
        if not _RECOMMENDED_PREFIX_RE.search(line):
            continue
        # Skip lines that are obviously navigation links rather than
        # the recommended-models content.
        if line.lstrip().startswith(("*", "-", "[")) and "**" not in line:
            continue
        names = re.findall(r"\*\*([^*]+)\*\*", line)
        # Filter out the "Pro"/"Lite" plan-name bolds that may appear
        # earlier on the same line in the markdown rendering.
        names = [n.strip() for n in names if n.strip() and not _looks_like_plan_label(n)]
        if names:
            return names
    return []


def _looks_like_plan_label(s: str) -> bool:
    """Reject common alibaba doc-page bolds that are NOT model names."""
    return s.strip().lower() in {"pro", "lite", "plan details", "supported models"}


def _extract_from_html(html: str) -> List[str]:
    """HTML parser. Locates the paragraph by its "Recommended" prefix
    and returns every <b>/<strong> child."""
    try:
        from bs4 import BeautifulSoup  # noqa: WPS433
    except ImportError:
        return []

    soup = BeautifulSoup(html, "html.parser")
    for p in soup.find_all(["p", "div", "li", "span"]):
        text = (p.get_text() or "").strip()
        if not _RECOMMENDED_PREFIX_RE.search(text[:60]):
            continue
        names: List[str] = []
        for bold in p.find_all(["b", "strong"]):
            name = (bold.get_text() or "").strip()
            if name and not _looks_like_plan_label(name):
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
