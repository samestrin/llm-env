"""Unit tests for scripts.lib.alibaba.

Uses a captured HTML fixture so no network calls happen.
"""
from __future__ import annotations

from pathlib import Path

import pytest

from scripts.lib import alibaba

FIXTURE = Path(__file__).parent / "fixtures" / "alibaba_coding_plan.html"


def load_fixture_html() -> str:
    return FIXTURE.read_text()


def test_extract_recommended_models_from_real_html():
    html = load_fixture_html()
    names = alibaba.extract_recommended_models(html)
    # The captured page lists exactly these four bolded models.
    assert names == ["qwen3.5-plus", "kimi-k2.5", "glm-5", "MiniMax-M2.5"]


def test_extract_recommended_returns_empty_when_marker_missing():
    html = "<html><body><p>No models here.</p></body></html>"
    assert alibaba.extract_recommended_models(html) == []


def test_extract_recommended_handles_strong_alternative():
    html = (
        "<html><body><p>Recommended: <strong>foo</strong>, <strong>bar</strong></p></body></html>"
    )
    assert alibaba.extract_recommended_models(html) == ["foo", "bar"]


def test_build_v2_payload_basic():
    html = load_fixture_html()
    out = alibaba.build_v2_payload(fetch_html=lambda url: html)

    assert out["schema_version"] == "2"
    assert out["source"] == "alibaba"
    assert out["vendor_short"] == "alibaba"
    assert out["api_key_var"] == "LLM_ALIBABA_API_KEY"
    assert out["endpoints"]["openai"] == "https://coding-intl.dashscope.aliyuncs.com/v1"
    assert out["endpoints"]["anthropic"] == "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic"

    ids = {m["id"] for m in out["models"]}
    assert ids == {"qwen3.5-plus", "kimi-k2.5", "glm-5", "minimax-m2.5"}


def test_build_v2_payload_marks_both_protocols():
    html = load_fixture_html()
    out = alibaba.build_v2_payload(fetch_html=lambda url: html)
    for m in out["models"]:
        assert "openai" in m["protocols"]
        assert "anthropic" in m["protocols"]


def test_build_v2_payload_family_latest():
    html = load_fixture_html()
    out = alibaba.build_v2_payload(fetch_html=lambda url: html)
    fl = out["family_latest"]
    assert fl["qwen"] == "qwen3.5-plus"
    assert fl["kimi"] == "kimi-k2.5"
    assert fl["glm"] == "glm-5"
    assert fl["minimax"] == "minimax-m2.5"


def test_build_v2_payload_empty_html_yields_empty_models():
    out = alibaba.build_v2_payload(fetch_html=lambda url: "<html></html>")
    assert out["models"] == []
    assert out["family_latest"] == {}
