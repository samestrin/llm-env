"""Tests for the scraper orchestrator (scripts/update_quickstart.py)."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts import update_quickstart


@pytest.fixture(autouse=True)
def allow_no_key(monkeypatch):
    """Bypass the LLM_SYNTHETIC_API_KEY gate for these unit tests."""
    monkeypatch.setenv("LLM_ENV_SCRAPER_ALLOW_NO_KEY", "1")
    monkeypatch.delenv("LLM_SYNTHETIC_API_KEY", raising=False)


# --- Helpers ---------------------------------------------------------------


def _minimal_synthetic_payload() -> dict:
    return {
        "schema_version": "2",
        "generated_at": "2026-04-30T00:00:00Z",
        "source": "synthetic",
        "vendor_short": "synth",
        "endpoints": {
            "openai": "https://api.synthetic.new/openai/v1",
            "anthropic": "https://api.synthetic.new/anthropic/v1",
        },
        "api_key_var": "LLM_SYNTHETIC_API_KEY",
        "signup_url": "https://example/",
        "models": [
            {
                "id": "kimi-k2.5",
                "family": "kimi",
                "version": "2.5",
                "description": "Kimi K2.5",
                "protocols": ["openai", "anthropic"],
                "upstream_id": "hf:moonshotai/Kimi-K2.5",
            }
        ],
        "family_latest": {"kimi": "kimi-k2.5"},
    }


def _minimal_alibaba_payload() -> dict:
    return {
        "schema_version": "2",
        "generated_at": "2026-04-30T00:00:00Z",
        "source": "alibaba",
        "vendor_short": "alibaba",
        "endpoints": {
            "openai": "https://coding-intl.dashscope.aliyuncs.com/v1",
            "anthropic": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
        },
        "api_key_var": "LLM_ALIBABA_API_KEY",
        "signup_url": "https://example/",
        "models": [
            {
                "id": "qwen3.5-plus",
                "family": "qwen",
                "version": "3.5",
                "description": "Qwen",
                "protocols": ["openai", "anthropic"],
                "upstream_id": "qwen3.5-plus",
            }
        ],
        "family_latest": {"qwen": "qwen3.5-plus"},
    }


# --- validate_payload ------------------------------------------------------


def test_validate_payload_accepts_minimal_valid():
    update_quickstart.validate_payload(_minimal_synthetic_payload())


def test_validate_payload_rejects_wrong_schema_version():
    p = _minimal_synthetic_payload()
    p["schema_version"] = "1"
    with pytest.raises(update_quickstart.ValidationError):
        update_quickstart.validate_payload(p)


def test_validate_payload_rejects_missing_top_level_field():
    for field in ("vendor_short", "api_key_var", "endpoints", "models", "family_latest"):
        p = _minimal_synthetic_payload()
        del p[field]
        with pytest.raises(update_quickstart.ValidationError):
            update_quickstart.validate_payload(p)


def test_validate_payload_rejects_empty_models():
    p = _minimal_synthetic_payload()
    p["models"] = []
    with pytest.raises(update_quickstart.ValidationError):
        update_quickstart.validate_payload(p)


def test_validate_payload_rejects_family_latest_pointing_at_missing_model():
    p = _minimal_synthetic_payload()
    p["family_latest"] = {"kimi": "ghost"}
    with pytest.raises(update_quickstart.ValidationError):
        update_quickstart.validate_payload(p)


def test_validate_payload_rejects_endpoint_without_openai():
    p = _minimal_synthetic_payload()
    del p["endpoints"]["openai"]
    with pytest.raises(update_quickstart.ValidationError):
        update_quickstart.validate_payload(p)


# --- write_payload preserves last-known-good on validation failure ---------


def test_write_payload_writes_when_valid(tmp_path):
    target = tmp_path / "quickstart-synthetic.json"
    update_quickstart.write_payload(_minimal_synthetic_payload(), target)
    assert target.exists()
    written = json.loads(target.read_text())
    assert written["schema_version"] == "2"


def test_write_payload_preserves_last_known_good_on_invalid(tmp_path):
    target = tmp_path / "quickstart-synthetic.json"
    # Seed a known-good file.
    good = _minimal_synthetic_payload()
    target.write_text(json.dumps(good))

    bad = _minimal_synthetic_payload()
    bad["schema_version"] = "9"
    with pytest.raises(update_quickstart.ValidationError):
        update_quickstart.write_payload(bad, target)

    # File still contains good payload.
    still = json.loads(target.read_text())
    assert still["schema_version"] == "2"


# --- run() orchestrator ----------------------------------------------------


def test_run_writes_both_files(tmp_path, monkeypatch):
    syn_target = tmp_path / "quickstart-synthetic.json"
    ali_target = tmp_path / "quickstart-alibaba.json"

    def fake_synth_build(**kwargs):
        return _minimal_synthetic_payload()

    def fake_ali_build(**kwargs):
        return _minimal_alibaba_payload()

    monkeypatch.setattr(update_quickstart.synthetic, "build_v2_payload", fake_synth_build)
    monkeypatch.setattr(update_quickstart.alibaba, "build_v2_payload", fake_ali_build)

    rc = update_quickstart.run(output_dir=tmp_path)
    assert rc == 0
    assert syn_target.exists()
    assert ali_target.exists()


def test_run_partial_failure_preserves_good_source(tmp_path, monkeypatch):
    syn_target = tmp_path / "quickstart-synthetic.json"
    ali_target = tmp_path / "quickstart-alibaba.json"

    # Seed both targets with good payloads.
    syn_target.write_text(json.dumps(_minimal_synthetic_payload()))
    ali_target.write_text(json.dumps(_minimal_alibaba_payload()))

    # Synthetic succeeds; Alibaba blows up.
    def fake_synth_build(**kwargs):
        return _minimal_synthetic_payload()

    def broken_ali_build(**kwargs):
        raise RuntimeError("alibaba site down")

    monkeypatch.setattr(update_quickstart.synthetic, "build_v2_payload", fake_synth_build)
    monkeypatch.setattr(update_quickstart.alibaba, "build_v2_payload", broken_ali_build)

    rc = update_quickstart.run(output_dir=tmp_path)
    assert rc != 0  # surfaces partial failure
    # Synthetic refreshed (still valid)
    assert syn_target.exists()
    # Alibaba untouched: file still parses to the seeded good payload.
    assert json.loads(ali_target.read_text())["source"] == "alibaba"


def test_run_refuses_without_synthetic_api_key(tmp_path, monkeypatch):
    """Without the key, the anthropic probe degrades silently — refuse."""
    monkeypatch.delenv("LLM_SYNTHETIC_API_KEY", raising=False)
    monkeypatch.delenv("LLM_ENV_SCRAPER_ALLOW_NO_KEY", raising=False)
    rc = update_quickstart.run(output_dir=tmp_path)
    assert rc == 2


def test_run_proceeds_when_api_key_present(tmp_path, monkeypatch):
    monkeypatch.setenv("LLM_SYNTHETIC_API_KEY", "test-key")
    monkeypatch.delenv("LLM_ENV_SCRAPER_ALLOW_NO_KEY", raising=False)
    monkeypatch.setattr(
        update_quickstart.synthetic, "build_v2_payload", lambda **kw: _minimal_synthetic_payload(),
    )
    monkeypatch.setattr(
        update_quickstart.alibaba, "build_v2_payload", lambda **kw: _minimal_alibaba_payload(),
    )
    rc = update_quickstart.run(output_dir=tmp_path)
    assert rc == 0


def test_run_returns_nonzero_when_source_emits_invalid(tmp_path, monkeypatch):
    target = tmp_path / "quickstart-synthetic.json"
    target.write_text(json.dumps(_minimal_synthetic_payload()))

    def bad_build(**kwargs):
        p = _minimal_synthetic_payload()
        p["schema_version"] = "1"  # invalid
        return p

    monkeypatch.setattr(update_quickstart.synthetic, "build_v2_payload", bad_build)
    monkeypatch.setattr(update_quickstart.alibaba, "build_v2_payload", lambda **kw: _minimal_alibaba_payload())

    rc = update_quickstart.run(output_dir=tmp_path)
    assert rc != 0
    # Existing file unchanged.
    assert json.loads(target.read_text())["schema_version"] == "2"
