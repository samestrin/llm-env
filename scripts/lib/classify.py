"""Deterministic model-id classifier with optional AI fallback.

Given a model id like ``hf:zai-org/GLM-5.1`` or ``Qwen3-Coder-480B-A35B-Instruct``,
classify produces ``{family, subtype, version, size_b, confidence}``.

Confidence is ``high`` when both family and version match deterministic
regexes, ``low`` otherwise. Callers can wrap the result in
:func:`classify_with_fallback` to invoke :func:`ai_classify` (a thin
wrapper around synthetic's chat-completions endpoint) for low-confidence
cases.

The module also exposes helpers for quantization suppression
(:func:`is_quantization_variant`), chat-only filtering
(:func:`is_non_chat`), id normalization (:func:`normalize_id`),
effective family computation (:func:`effective_family`), and "pick
latest" tie-breaking (:func:`pick_latest`).
"""
from __future__ import annotations

import os
import re
from typing import Optional

# --- Public surface -------------------------------------------------------

KNOWN_FAMILIES = (
    "kimi",
    "glm",
    "minimax",
    "deepseek",
    "qwen",
    "gpt-oss",
    "nemotron",
    "llama",
)

# Subtypes recognized after the version token. "instruct" is intentionally
# omitted: nearly every chat model is "instruct"-tuned, so it adds no
# discrimination value as a subtype.
SUBTYPES = ("coder", "thinking", "flash")

# Quantization suffixes applied by upstream hosts. Stripped before classification
# and treated as suppression-worthy by is_quantization_variant.
QUANT_SUFFIX_RE = re.compile(
    r"-(?:nvfp4|fp8|fp16|int8|int4|awq|gptq)$",
    re.IGNORECASE,
)

# Substrings that mark a model as not chat-capable.
NON_CHAT_TOKENS = (
    "embed",          # text-embedding-*, openai-embed-*
    "embedding",
    "whisper",        # speech-to-text
    "tts",            # text-to-speech
    "dall-e",         # image generation
    "vision-only",    # vision-only marker
)


def is_quantization_variant(name: str) -> bool:
    """Return True if name carries a quantization suffix like -NVFP4."""
    return bool(QUANT_SUFFIX_RE.search(name))


def is_non_chat(name: str) -> bool:
    """Return True if the model id looks like a non-chat (embed/audio/vision) model."""
    lower = name.lower()
    return any(token in lower for token in NON_CHAT_TOKENS)


def normalize_id(raw: str) -> str:
    """Lowercase, strip ``hf:`` prefix and any owner/ org segment.

    Examples:
        ``hf:moonshotai/Kimi-K2.5`` -> ``kimi-k2.5``
        ``hf:Qwen/Qwen3-Coder-480B-A35B-Instruct`` -> ``qwen3-coder-480b-a35b-instruct``
        ``MiniMax-M2.5`` -> ``minimax-m2.5``
    """
    s = raw.strip()
    if s.lower().startswith("hf:"):
        s = s[3:]
    if "/" in s:
        s = s.split("/", 1)[1]
    return s.lower()


# --- Deterministic family/version regex tables ----------------------------
#
# Each entry: family name -> compiled pattern. The first capture group, when
# present, is the version token. Patterns operate on the *normalized* id
# (lowercase, no org prefix). Patterns are applied in order, so disambiguating
# entries (gpt-oss before gpt) come first.

_FAMILY_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("gpt-oss",  re.compile(r"\bgpt-oss\b")),
    ("nemotron", re.compile(r"\bnemotron-?(\d+)?\b")),
    ("kimi",     re.compile(r"\bkimi-?k?(\d+(?:\.\d+)?)\b")),
    ("minimax",  re.compile(r"\bminimax-?m?(\d+(?:\.\d+)?)\b")),
    ("glm",      re.compile(r"\bglm-?(\d+(?:\.\d+)?)\b")),
    ("deepseek", re.compile(r"\bdeepseek-?[vr]?(\d+(?:\.\d+)?)\b")),
    ("qwen",     re.compile(r"\bqwen-?(\d+(?:\.\d+)?)\b")),
    ("llama",    re.compile(r"\bllama-?(\d+(?:\.\d+)?)\b")),
)

_SUBTYPE_RE = re.compile(r"\b(" + "|".join(SUBTYPES) + r")\b", re.IGNORECASE)
_DEEPSEEK_R_RE = re.compile(r"\bdeepseek-?r(\d+)?\b", re.IGNORECASE)
_SIZE_RE = re.compile(r"\b(\d+)b\b", re.IGNORECASE)


def classify(raw_id: str) -> dict:
    """Classify a model id into ``{family, subtype, version, size_b, confidence}``.

    ``raw_id`` may be in any of the upstream forms (with hf: prefix, with
    owner/, mixed case). Internally normalizes for matching.
    """
    norm = normalize_id(raw_id)

    # Family match
    family: Optional[str] = None
    version: Optional[str] = None
    for fam, pattern in _FAMILY_PATTERNS:
        m = pattern.search(norm)
        if m is None:
            continue
        family = fam
        if m.lastindex:
            version = m.group(1)
        break

    # Subtype: deepseek's "R" goes via a separate regex because it bears
    # the version directly (R1, R2, ...). Other subtypes are word tokens.
    subtype: Optional[str] = None
    if family == "deepseek":
        rmatch = _DEEPSEEK_R_RE.search(norm)
        if rmatch is not None:
            subtype = "r"
            if rmatch.lastindex and rmatch.group(1):
                version = rmatch.group(1)
    if subtype is None:
        sm = _SUBTYPE_RE.search(norm)
        if sm is not None:
            subtype = sm.group(1).lower()

    # Size in B parameters, used as tie-breaker only.
    size_b: Optional[int] = None
    sizem = _SIZE_RE.search(norm)
    if sizem is not None:
        try:
            size_b = int(sizem.group(1))
        except ValueError:
            size_b = None

    # gpt-oss has no semantic version, just a size. Pin version to "0" so
    # downstream "pick latest" treats them as comparable; size becomes the
    # real differentiator.
    if family == "gpt-oss" and version is None:
        version = "0"

    confidence = "high" if (family is not None and version is not None) else "low"

    return {
        "family": family,
        "subtype": subtype,
        "version": version,
        "size_b": size_b,
        "confidence": confidence,
    }


def effective_family(family: Optional[str], subtype: Optional[str]) -> Optional[str]:
    """Combine family and subtype into a single key for ``family_latest`` lookup.

    Examples:
        ("glm", None) -> "glm"
        ("glm", "flash") -> "glm-flash"
        ("qwen", "coder") -> "qwen-coder"
        ("deepseek", "r") -> "deepseek-r"
    """
    if family is None:
        return None
    if subtype is None:
        return family
    return f"{family}-{subtype}"


def compare_versions(a: str, b: str) -> int:
    """Compare two dotted-version strings; return -1, 0, or 1.

    Components are integers when possible, lexicographic otherwise.
    """
    def parts(v: str) -> list:
        out: list = []
        for token in v.split("."):
            try:
                out.append((0, int(token)))
            except ValueError:
                out.append((1, token))
        return out

    pa, pb = parts(a), parts(b)
    if pa < pb:
        return -1
    if pa > pb:
        return 1
    return 0


def pick_latest(candidates: list[dict]) -> Optional[dict]:
    """Pick the "latest" entry from a list of candidates.

    Each candidate must carry ``version`` (string) and ``size_b``
    (int or None). Higher version wins; size_b is the tie-breaker only
    when versions are exactly equal. Stable: preserves input order
    on full ties.
    """
    if not candidates:
        return None
    best = candidates[0]
    for cand in candidates[1:]:
        cmp_v = compare_versions(cand["version"], best["version"])
        if cmp_v > 0:
            best = cand
        elif cmp_v == 0:
            cur = cand.get("size_b") or 0
            top = best.get("size_b") or 0
            if cur > top:
                best = cand
    return best


# --- AI fallback ----------------------------------------------------------


def ai_classify(name: str) -> Optional[dict]:
    """Ask a synthetic-hosted model to classify an unknown id.

    Returns ``{family, subtype, version, confidence: "ai"}`` on success
    or ``None`` if the API key is missing, the call fails, or the
    response is unparseable. Network calls live behind ``requests``;
    tests should monkeypatch this function directly rather than mocking
    HTTP.
    """
    api_key = os.environ.get("LLM_SYNTHETIC_API_KEY")
    if not api_key:
        return None

    try:
        import json
        import requests  # imported lazily so unit tests don't need it
    except ImportError:
        return None

    prompt = (
        "Classify this LLM model id. Reply with ONLY a JSON object of the form "
        '{"family": str, "subtype": str|null, "version": str}. '
        f"family must be one of {list(KNOWN_FAMILIES)}. "
        "subtype must be one of [\"coder\", \"thinking\", \"flash\", \"r\", null]. "
        f"Model id: {name}"
    )

    for model in ("hf:zai-org/GLM-4.7-Flash", "hf:zai-org/GLM-4.7"):
        try:
            resp = requests.post(
                "https://api.synthetic.new/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 100,
                    "temperature": 0,
                },
                timeout=20,
            )
            resp.raise_for_status()
            content = resp.json()["choices"][0]["message"]["content"]
            # Tolerate code fences around the JSON.
            text = content.strip().strip("`").strip()
            if text.startswith("json"):
                text = text[4:].strip()
            data = json.loads(text)
        except Exception:
            continue

        family = data.get("family")
        if family not in KNOWN_FAMILIES:
            continue
        subtype = data.get("subtype")
        if subtype is not None and subtype not in SUBTYPES + ("r",):
            subtype = None
        version = data.get("version")
        if not isinstance(version, str):
            continue
        return {
            "family": family,
            "subtype": subtype,
            "version": version,
            "size_b": None,
            "confidence": "ai",
        }

    return None


def classify_with_fallback(raw_id: str) -> dict:
    """Run :func:`classify`, and if confidence is low, ask the AI helper.

    On AI failure, returns the original low-confidence result rather
    than raising. Callers downstream decide whether to skip
    low-confidence models.
    """
    result = classify(raw_id)
    if result["confidence"] == "high":
        return result
    ai = ai_classify(raw_id)
    if ai is None:
        return result
    return ai
