"""Unit tests for scripts.lib.alibaba.

Uses a captured HTML fixture so no network calls happen.
"""
from __future__ import annotations

from pathlib import Path

import pytest

from scripts.lib import alibaba

FIXTURE_HTML = Path(__file__).parent / "fixtures" / "alibaba_coding_plan.html"
FIXTURE_MD = Path(__file__).parent / "fixtures" / "alibaba_coding_plan.md"


def load_fixture_html() -> str:
    return FIXTURE_HTML.read_text()


def load_fixture_md() -> str:
    return FIXTURE_MD.read_text()


def test_extract_recommended_models_from_real_html():
    """The HTML fixture is the legacy direct-fetch shape (qwen3.5-plus era)."""
    html = load_fixture_html()
    names = alibaba.extract_recommended_models(html)
    assert names == ["qwen3.5-plus", "kimi-k2.5", "glm-5", "MiniMax-M2.5"]


def test_extract_recommended_models_from_real_markdown():
    """The markdown fixture is the Jina-proxy shape (current qwen3.6-plus)."""
    md = load_fixture_md()
    names = alibaba.extract_recommended_models(md)
    assert names == ["qwen3.6-plus", "kimi-k2.5", "glm-5", "MiniMax-M2.5"]


def test_extract_recommended_returns_empty_when_marker_missing():
    html = "<html><body><p>No models here.</p></body></html>"
    assert alibaba.extract_recommended_models(html) == []


def test_extract_recommended_handles_strong_alternative():
    html = (
        "<html><body><p>Recommended: <strong>foo</strong>, <strong>bar</strong></p></body></html>"
    )
    assert alibaba.extract_recommended_models(html) == ["foo", "bar"]


def test_extract_recommended_handles_models_phrase_variation():
    """The page now says 'Recommended models:' (with an extra word)."""
    html = (
        "<html><body><p>Recommended models: <b>a</b>, <b>b</b></p></body></html>"
    )
    assert alibaba.extract_recommended_models(html) == ["a", "b"]


def test_extract_markdown_filters_plan_labels():
    """Jina-rendered markdown puts 'Pro' in bold near the model line; ignore."""
    md = (
        "Title: x\n\n"
        "Markdown Content:\n"
        "**Pro**\n"
        "Supported models Recommended models: **qwen3.6-plus**, **kimi-k2.5**\n"
    )
    assert alibaba.extract_recommended_models(md) == ["qwen3.6-plus", "kimi-k2.5"]


def test_looks_like_markdown_detects_jina_preamble():
    md = "Title: foo\n\nMarkdown Content:\n# Heading\n"
    assert alibaba.looks_like_markdown(md) is True


def test_looks_like_markdown_recognizes_html():
    html = "<!DOCTYPE html><html><body>...</body></html>"
    assert alibaba.looks_like_markdown(html) is False


def test_build_v2_payload_basic_html():
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


def test_build_v2_payload_basic_markdown():
    """End-to-end on the Jina-proxy fixture: should yield qwen3.6-plus."""
    md = load_fixture_md()
    out = alibaba.build_v2_payload(fetch_html=lambda url: md)
    ids = {m["id"] for m in out["models"]}
    assert ids == {"qwen3.6-plus", "kimi-k2.5", "glm-5", "minimax-m2.5"}


def test_build_v2_payload_marks_both_protocols():
    html = load_fixture_html()
    out = alibaba.build_v2_payload(fetch_html=lambda url: html)
    for m in out["models"]:
        assert "openai" in m["protocols"]
        assert "anthropic" in m["protocols"]


def test_build_v2_payload_family_latest_html():
    html = load_fixture_html()
    out = alibaba.build_v2_payload(fetch_html=lambda url: html)
    fl = out["family_latest"]
    assert fl["qwen"] == "qwen3.5-plus"
    assert fl["kimi"] == "kimi-k2.5"
    assert fl["glm"] == "glm-5"
    assert fl["minimax"] == "minimax-m2.5"


def test_build_v2_payload_family_latest_markdown():
    md = load_fixture_md()
    out = alibaba.build_v2_payload(fetch_html=lambda url: md)
    fl = out["family_latest"]
    assert fl["qwen"] == "qwen3.6-plus"
    assert fl["kimi"] == "kimi-k2.5"
    assert fl["glm"] == "glm-5"
    assert fl["minimax"] == "minimax-m2.5"


def test_build_v2_payload_empty_html_yields_empty_models():
    out = alibaba.build_v2_payload(fetch_html=lambda url: "<html></html>")
    assert out["models"] == []
    assert out["family_latest"] == {}
