"""Unit tests for scripts.lib.classify.

Covers deterministic family/version/subtype classification, quantization
suppression, and chat-only filtering. AI fallback is mocked.
"""
import pytest

from scripts.lib import classify


# --- Quantization suppression ----------------------------------------------


@pytest.mark.parametrize(
    "name",
    [
        "Kimi-K2.5-NVFP4",
        "kimi-k2.5-nvfp4",
        "Some-Model-FP8",
        "weird-INT8",
        "another-int4",
        "model-AWQ",
        "model-gptq",
    ],
)
def test_is_quantization_variant_true(name):
    assert classify.is_quantization_variant(name) is True


@pytest.mark.parametrize(
    "name",
    [
        "Kimi-K2.5",
        "GLM-5.1",
        "qwen3-coder-480b-a35b-instruct",
        "DeepSeek-V3.2",
        "Llama-3.3-70B-Instruct",
    ],
)
def test_is_quantization_variant_false(name):
    assert classify.is_quantization_variant(name) is False


# --- Chat-only filter ------------------------------------------------------


@pytest.mark.parametrize(
    "name",
    [
        "text-embedding-3",
        "openai-embed-large",
        "whisper-large-v3",
        "tts-1",
        "dall-e-3",
        "vision-only-foo",
    ],
)
def test_is_non_chat_true(name):
    assert classify.is_non_chat(name) is True


@pytest.mark.parametrize(
    "name",
    [
        "kimi-k2.5",
        "glm-5.1",
        "deepseek-v3.2",
        "qwen3-coder",
        "llama-3.3-70b-instruct",
    ],
)
def test_is_non_chat_false(name):
    assert classify.is_non_chat(name) is False


# --- Deterministic family/version/subtype classification --------------------


@pytest.mark.parametrize(
    "name,expected",
    [
        # Each tuple: (input_id, {family, subtype, version, confidence})
        ("MiniMax-M2.5", {"family": "minimax", "subtype": None, "version": "2.5"}),
        ("Kimi-K2.5", {"family": "kimi", "subtype": None, "version": "2.5"}),
        ("Kimi-K2", {"family": "kimi", "subtype": None, "version": "2"}),
        ("GLM-4.7", {"family": "glm", "subtype": None, "version": "4.7"}),
        ("GLM-4.7-Flash", {"family": "glm", "subtype": "flash", "version": "4.7"}),
        ("GLM-5", {"family": "glm", "subtype": None, "version": "5"}),
        ("GLM-5.1", {"family": "glm", "subtype": None, "version": "5.1"}),
        ("DeepSeek-V3.2", {"family": "deepseek", "subtype": None, "version": "3.2"}),
        ("DeepSeek-V3", {"family": "deepseek", "subtype": None, "version": "3"}),
        ("DeepSeek-R1-0528", {"family": "deepseek", "subtype": "r", "version": "1"}),
        ("gpt-oss-120b", {"family": "gpt-oss", "subtype": None, "version": "0"}),
        (
            "Qwen3-Coder-480B-A35B-Instruct",
            {"family": "qwen", "subtype": "coder", "version": "3"},
        ),
        (
            "Qwen3-235B-A22B-Thinking-2507",
            {"family": "qwen", "subtype": "thinking", "version": "3"},
        ),
        ("Qwen3.5-397B-A17B", {"family": "qwen", "subtype": None, "version": "3.5"}),
        ("Llama-3.3-70B-Instruct", {"family": "llama", "subtype": None, "version": "3.3"}),
        (
            "NVIDIA-Nemotron-3-Super-120B-A12B",
            {"family": "nemotron", "subtype": None, "version": "3"},
        ),
    ],
)
def test_classify_known_models(name, expected):
    result = classify.classify(name)
    assert result["family"] == expected["family"]
    assert result["subtype"] == expected["subtype"]
    assert result["version"] == expected["version"]
    assert result["confidence"] == "high"


def test_classify_unknown_returns_low_confidence():
    result = classify.classify("totally-unknown-model-9000")
    assert result["confidence"] == "low"


def test_classify_strips_org_prefix():
    # org/Model form, common in upstream payloads
    result = classify.classify("moonshotai/Kimi-K2.5")
    assert result["family"] == "kimi"
    assert result["version"] == "2.5"


def test_classify_strips_hf_prefix():
    result = classify.classify("hf:zai-org/GLM-5.1")
    assert result["family"] == "glm"
    assert result["version"] == "5.1"


# --- normalize_id ----------------------------------------------------------


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("hf:moonshotai/Kimi-K2.5", "kimi-k2.5"),
        ("hf:zai-org/GLM-5.1", "glm-5.1"),
        ("hf:Qwen/Qwen3-Coder-480B-A35B-Instruct", "qwen3-coder-480b-a35b-instruct"),
        ("hf:openai/gpt-oss-120b", "gpt-oss-120b"),
        ("MiniMax-M2.5", "minimax-m2.5"),
        ("MoonshotAI/kimi-k2.5", "kimi-k2.5"),
    ],
)
def test_normalize_id(raw, expected):
    assert classify.normalize_id(raw) == expected


# --- Effective family ------------------------------------------------------


@pytest.mark.parametrize(
    "family,subtype,expected",
    [
        ("kimi", None, "kimi"),
        ("glm", None, "glm"),
        ("glm", "flash", "glm-flash"),
        ("qwen", "coder", "qwen-coder"),
        ("qwen", "thinking", "qwen-thinking"),
        ("deepseek", None, "deepseek"),
        ("deepseek", "r", "deepseek-r"),
    ],
)
def test_effective_family(family, subtype, expected):
    assert classify.effective_family(family, subtype) == expected


# --- Version comparison ----------------------------------------------------


@pytest.mark.parametrize(
    "a,b,expected",
    [
        ("5.1", "5", 1),     # 5.1 > 5
        ("5", "5.1", -1),    # 5 < 5.1
        ("5.1", "5.1", 0),   # equal
        ("4.7", "5", -1),
        ("3.5", "3", 1),
        ("2.5", "2", 1),
    ],
)
def test_compare_versions(a, b, expected):
    assert classify.compare_versions(a, b) == expected


# --- pick_latest -----------------------------------------------------------


def test_pick_latest_chooses_highest_version():
    candidates = [
        {"id": "glm-4.7", "version": "4.7", "size_b": 100},
        {"id": "glm-5", "version": "5", "size_b": 100},
        {"id": "glm-5.1", "version": "5.1", "size_b": 100},
    ]
    assert classify.pick_latest(candidates)["id"] == "glm-5.1"


def test_pick_latest_size_tiebreaker_only_when_versions_equal():
    candidates = [
        {"id": "qwen3-coder-235b", "version": "3", "size_b": 235},
        {"id": "qwen3-coder-480b", "version": "3", "size_b": 480},
    ]
    assert classify.pick_latest(candidates)["id"] == "qwen3-coder-480b"


def test_pick_latest_ignores_size_when_versions_differ():
    # Higher version wins even if smaller size.
    candidates = [
        {"id": "model-3.5-100b", "version": "3.5", "size_b": 100},
        {"id": "model-3-1000b", "version": "3", "size_b": 1000},
    ]
    assert classify.pick_latest(candidates)["id"] == "model-3.5-100b"


# --- AI fallback (mocked) --------------------------------------------------


def test_ai_fallback_invoked_only_for_low_confidence(monkeypatch):
    calls = []

    def fake_ai_classify(name):
        calls.append(name)
        return {"family": "kimi", "subtype": None, "version": "9.9", "confidence": "ai"}

    monkeypatch.setattr(classify, "ai_classify", fake_ai_classify)

    high_conf = classify.classify_with_fallback("Kimi-K2.5")
    assert high_conf["family"] == "kimi"
    assert calls == [], "AI must not be called for high-confidence results"

    low_conf = classify.classify_with_fallback("totally-unknown-foo")
    assert calls == ["totally-unknown-foo"]
    assert low_conf["family"] == "kimi"
    assert low_conf["confidence"] == "ai"


def test_ai_fallback_failure_leaves_low_confidence(monkeypatch):
    monkeypatch.setattr(classify, "ai_classify", lambda name: None)
    result = classify.classify_with_fallback("totally-unknown-foo")
    assert result["confidence"] == "low"


# --- Adversarial -----------------------------------------------------------


def test_compare_versions_with_non_numeric_tokens():
    # Lexicographic fallback for non-integer parts. Numeric < non-numeric.
    assert classify.compare_versions("1", "1.beta") == -1
    assert classify.compare_versions("1.beta", "1") == 1
    assert classify.compare_versions("1.alpha", "1.beta") == -1


def test_pick_latest_empty_returns_none():
    assert classify.pick_latest([]) is None


def test_pick_latest_single_returns_entry():
    only = {"id": "x", "version": "1", "size_b": None}
    assert classify.pick_latest([only]) is only


def test_pick_latest_stable_on_full_tie():
    a = {"id": "a", "version": "1", "size_b": 10}
    b = {"id": "b", "version": "1", "size_b": 10}
    # First in list wins on full tie.
    assert classify.pick_latest([a, b])["id"] == "a"
    assert classify.pick_latest([b, a])["id"] == "b"


def test_classify_handles_unicode_id_without_crash():
    # Should not raise; low-confidence result is acceptable.
    result = classify.classify("天空-model-1")
    assert result["confidence"] in ("low", "high")
