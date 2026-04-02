---
name: python-debugging
description: Debug Python runtime errors quickly with uv-first workflows
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: python
---

## What I do

- Triage Python failures in a predictable order
- Prefer reproducible commands with `uv run`
- Separate environment issues from code issues

## Debug order

1. Verify environment state
2. Reproduce with a single `uv run` command
3. Capture full traceback
4. Isolate failing import/module/function
5. Add or update a regression test

## Commands to use

```bash
uv sync
uv run python -V
uv run python -m pip list
uv run pytest -q
uv run pytest -k "failing_test_name" -q
uv run python -X dev -m your_module
```

## Common fixes

- Import errors: confirm package in `pyproject.toml`, then `uv sync`
- Version mismatch: check `uv.lock`, then `uv lock && uv sync`
- Hidden path issues: run from repo root, avoid ad-hoc `PYTHONPATH`
- Flaky tests: rerun with `-k` and narrow fixtures/mocks

## Guardrails

- Do not install globally with `pip install`
- Do not skip lockfile updates when dependencies change
- Always include traceback snippets in bug reports

## When to use me

Use this when Python commands fail, imports break, tests are flaky, or dependency state is unclear.
