#!/usr/bin/env python3
"""Daily quickstart-JSON refresher.

Fetches synthetic and alibaba model catalogs, builds schema v2 payloads,
validates them, and writes ``quickstart-{synthetic,alibaba}.json`` to
the repository root (or ``--output-dir``).

Designed to be invoked from CI (see ``.github/workflows/update-quickstart.yml``).
Each source is processed independently: a partial failure leaves the
last-known-good file in place but the script exits nonzero so the
workflow goes red.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Optional

from scripts.lib import alibaba, synthetic


class ValidationError(ValueError):
    """Raised when a generated payload fails the v2 schema gate."""


REQUIRED_TOP_LEVEL = (
    "schema_version",
    "source",
    "vendor_short",
    "api_key_var",
    "endpoints",
    "models",
    "family_latest",
)

REQUIRED_MODEL_FIELDS = (
    "id",
    "family",
    "version",
    "description",
    "protocols",
    "upstream_id",
)


def validate_payload(payload: dict) -> None:
    """Validate a v2 payload. Raises :class:`ValidationError` on any defect."""
    if not isinstance(payload, dict):
        raise ValidationError("payload is not a dict")

    for key in REQUIRED_TOP_LEVEL:
        if key not in payload:
            raise ValidationError(f"missing required top-level field: {key}")

    if payload["schema_version"] != "2":
        raise ValidationError(f"schema_version must be '2', got {payload['schema_version']!r}")

    endpoints = payload["endpoints"]
    if not isinstance(endpoints, dict) or "openai" not in endpoints:
        raise ValidationError("endpoints must be a dict containing at least 'openai'")

    models = payload["models"]
    if not isinstance(models, list) or not models:
        raise ValidationError("models must be a non-empty list")

    seen_ids: set[str] = set()
    for i, model in enumerate(models):
        if not isinstance(model, dict):
            raise ValidationError(f"models[{i}] is not a dict")
        for field in REQUIRED_MODEL_FIELDS:
            if field not in model:
                raise ValidationError(f"models[{i}] missing field: {field}")
        if model["id"] in seen_ids:
            raise ValidationError(f"duplicate model id: {model['id']!r}")
        seen_ids.add(model["id"])
        if not isinstance(model["protocols"], list) or not model["protocols"]:
            raise ValidationError(f"models[{i}].protocols must be a non-empty list")
        for proto in model["protocols"]:
            if proto not in ("openai", "anthropic"):
                raise ValidationError(f"unknown protocol {proto!r} in models[{i}]")

    family_latest = payload["family_latest"]
    if not isinstance(family_latest, dict):
        raise ValidationError("family_latest must be a dict")
    for fam, target in family_latest.items():
        if target not in seen_ids:
            raise ValidationError(
                f"family_latest[{fam!r}] points at unknown model {target!r}"
            )


def write_payload(payload: dict, target: Path) -> None:
    """Validate ``payload`` then atomically write it to ``target``.

    On validation failure the existing file at ``target`` is left
    untouched. On success the write is atomic (write to .tmp, rename).
    """
    validate_payload(payload)
    tmp = target.with_suffix(target.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2) + "\n")
    tmp.replace(target)


def _process_source(
    name: str,
    builder,
    target: Path,
) -> int:
    """Run one source through build → validate → write. Return 0 on success, 1 on failure."""
    print(f"[{name}] fetching and building payload...", file=sys.stderr)
    try:
        payload = builder()
    except Exception as exc:  # noqa: BLE001  -- we want to swallow any source-side error
        print(f"[{name}] FAILED to build: {exc}", file=sys.stderr)
        return 1

    try:
        write_payload(payload, target)
    except ValidationError as exc:
        print(f"[{name}] FAILED validation: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"[{name}] FAILED to write {target}: {exc}", file=sys.stderr)
        return 1

    print(
        f"[{name}] wrote {target} "
        f"({len(payload['models'])} models, "
        f"{len(payload['family_latest'])} family_latest entries)",
        file=sys.stderr,
    )
    return 0


def run(output_dir: Path, *, dry_run: bool = False) -> int:
    """Run both scrapers; return 0 if both succeed, nonzero otherwise.

    On partial failure (one source ok, one not) the successful file is
    written but the return code reflects the failure.

    Refuses to run without ``LLM_SYNTHETIC_API_KEY`` set, since without
    it the per-model anthropic-protocol probe returns False for every
    model and we'd silently emit JSON files with no anthropic providers
    or groups. Pass ``LLM_ENV_SCRAPER_ALLOW_NO_KEY=1`` in the env to
    override (used by tests and for debugging).
    """
    import os as _os
    if not _os.environ.get("LLM_SYNTHETIC_API_KEY") and not _os.environ.get(
        "LLM_ENV_SCRAPER_ALLOW_NO_KEY"
    ):
        print(
            "ERROR: LLM_SYNTHETIC_API_KEY is not set. The anthropic-protocol "
            "probe requires it; without the key, every model would be marked "
            "openai-only and groups would not be emitted. Refusing to run.",
            file=sys.stderr,
        )
        return 2

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    syn_target = output_dir / "quickstart-synthetic.json"
    ali_target = output_dir / "quickstart-alibaba.json"

    if dry_run:
        # In dry-run mode we still produce, validate, and report — but
        # write to .tmp targets only so reviewers can diff.
        syn_target = syn_target.with_suffix(".json.dryrun")
        ali_target = ali_target.with_suffix(".json.dryrun")

    rc_syn = _process_source(
        "synthetic", lambda: synthetic.build_v2_payload(), syn_target,
    )
    rc_ali = _process_source(
        "alibaba", lambda: alibaba.build_v2_payload(), ali_target,
    )
    return rc_syn or rc_ali


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Directory to write quickstart JSON files into (defaults to repo root).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Write to .json.dryrun files instead of overwriting the canonical ones.",
    )
    args = parser.parse_args(argv)
    return run(args.output_dir, dry_run=args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
