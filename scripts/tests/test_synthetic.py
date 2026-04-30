"""Unit tests for scripts.lib.synthetic.

Tests inject fixture HTTP responses via dependency injection (the
``fetch`` and ``probe_anthropic`` callables passed into
``build_v2_payload``), so no real network calls happen.
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.lib import synthetic

FIXTURE = Path(__file__).parent / "fixtures" / "synthetic_models.json"


def load_fixture() -> dict:
    with FIXTURE.open() as fh:
        return json.load(fh)


# --- Helpers ---------------------------------------------------------------


def fake_fetch_returning(payload):
    def _fetch(url: str) -> dict:
        return payload
    return _fetch


def fake_probe_all_supported():
    def _probe(model_id: str) -> bool:
        return True
    return _probe


def fake_probe_none_supported():
    def _probe(model_id: str) -> bool:
        return False
    return _probe


# --- Core fixture-driven test ----------------------------------------------


def test_build_v2_payload_basic():
    """The pasted-list fixture should yield 14 models after quant suppression."""
    raw = load_fixture()
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=fake_probe_all_supported(),
    )

    assert out["schema_version"] == "2"
    assert out["source"] == "synthetic"
    assert out["vendor_short"] == "synth"
    assert out["api_key_var"] == "LLM_SYNTHETIC_API_KEY"
    assert out["endpoints"]["openai"] == "https://api.synthetic.new/openai/v1"
    assert out["endpoints"]["anthropic"] == "https://api.synthetic.new/anthropic/v1"

    # Quantization variants suppressed: -NVFP4 entries dropped.
    ids = {m["id"] for m in out["models"]}
    assert "kimi-k2.5" in ids
    assert "kimi-k2.5-nvfp4" not in ids
    assert not any("nvfp4" in i for i in ids)
    assert not any("fp8" in i for i in ids)

    # 14 models = 16 raw - 2 quantization variants
    assert len(out["models"]) == 14


def test_build_v2_payload_protocols_marked_correctly():
    raw = load_fixture()
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=fake_probe_all_supported(),
    )
    for m in out["models"]:
        assert "openai" in m["protocols"]
        assert "anthropic" in m["protocols"]


def test_build_v2_payload_drops_anthropic_when_probe_says_no():
    raw = load_fixture()
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=fake_probe_none_supported(),
    )
    for m in out["models"]:
        assert m["protocols"] == ["openai"]


def test_build_v2_payload_per_model_probe_decisions():
    """Anthropic protocol included for some models and not others."""
    raw = load_fixture()

    def selective_probe(model_id: str) -> bool:
        return "kimi" in model_id

    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=selective_probe,
    )
    # Find the kimi entry vs a glm entry.
    kimi = next(m for m in out["models"] if m["id"] == "kimi-k2.5")
    glm = next(m for m in out["models"] if m["id"] == "glm-5.1")
    assert kimi["protocols"] == ["openai", "anthropic"]
    assert glm["protocols"] == ["openai"]


def test_build_v2_payload_family_latest_picks_correctly():
    raw = load_fixture()
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=fake_probe_all_supported(),
    )
    fl = out["family_latest"]
    # GLM 5.1 beats 4.7 and 5
    assert fl["glm"] == "glm-5.1"
    # GLM Flash family-latest
    assert fl["glm-flash"] == "glm-4.7-flash"
    # Kimi has only k2.5
    assert fl["kimi"] == "kimi-k2.5"
    # MiniMax has only m2.5
    assert fl["minimax"] == "minimax-m2.5"
    # DeepSeek V-line: V3.2 beats V3
    assert fl["deepseek"] == "deepseek-v3.2"
    # DeepSeek R-line: only one
    assert fl["deepseek-r"] == "deepseek-r1-0528"
    # gpt-oss
    assert fl["gpt-oss"] == "gpt-oss-120b"
    # Llama
    assert fl["llama"] == "llama-3.3-70b-instruct"
    # Qwen-coder, Qwen-thinking, Qwen base — all distinct effective families
    assert fl["qwen-coder"] == "qwen3-coder-480b-a35b-instruct"
    assert fl["qwen-thinking"] == "qwen3-235b-a22b-thinking-2507"
    assert fl["qwen"] == "qwen3.5-397b-a17b"


def test_build_v2_payload_filters_non_chat():
    """An embedding/whisper model in the upstream list must be dropped."""
    payload = {
        "object": "list",
        "data": [
            {"id": "hf:moonshotai/Kimi-K2.5"},
            {"id": "hf:openai/text-embedding-3"},
            {"id": "hf:openai/whisper-large-v3"},
        ],
    }
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(payload),
        probe_anthropic=fake_probe_all_supported(),
    )
    ids = {m["id"] for m in out["models"]}
    assert ids == {"kimi-k2.5"}


def test_build_v2_payload_drops_unclassifiable_models():
    """A model the deterministic classifier and AI fallback both reject."""
    payload = {
        "object": "list",
        "data": [
            {"id": "hf:moonshotai/Kimi-K2.5"},
            {"id": "totally-unknown-vendor-model-9000"},
        ],
    }

    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(payload),
        probe_anthropic=fake_probe_all_supported(),
        ai_classify=lambda name: None,  # AI also can't classify
    )
    ids = {m["id"] for m in out["models"]}
    assert "kimi-k2.5" in ids
    assert "totally-unknown-vendor-model-9000" not in ids


def test_build_v2_payload_dedupes_repeated_ids():
    payload = {
        "object": "list",
        "data": [
            {"id": "hf:moonshotai/Kimi-K2.5"},
            {"id": "hf:another-source/Kimi-K2.5"},  # different upstream, same normalized id
        ],
    }
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(payload),
        probe_anthropic=fake_probe_all_supported(),
    )
    kimi = [m for m in out["models"] if m["id"] == "kimi-k2.5"]
    assert len(kimi) == 1


def test_build_v2_payload_empty_input_yields_empty_models():
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning({"data": []}),
        probe_anthropic=fake_probe_all_supported(),
    )
    assert out["models"] == []
    assert out["family_latest"] == {}


def test_build_v2_payload_validates_output_shape():
    """The payload must be self-consistent: every family_latest target exists in models[]."""
    raw = load_fixture()
    out = synthetic.build_v2_payload(
        fetch=fake_fetch_returning(raw),
        probe_anthropic=fake_probe_all_supported(),
    )
    model_ids = {m["id"] for m in out["models"]}
    for fam, target in out["family_latest"].items():
        assert target in model_ids, f"family_latest[{fam}]={target} not in models[]"
