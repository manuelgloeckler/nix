---
name: python-quality
description: Enforce lint, format, typing, and test checks for Python projects
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: python
---

## What I do

- Run a clean Python quality gate using uv
- Keep checks fast and deterministic
- Standardize pre-commit style commands

## Default quality gate

```bash
uv sync
uv run ruff check .
uv run ruff format --check .
uv run mypy .
uv run pytest -q
```

## Auto-fix flow

```bash
uv run ruff check . --fix
uv run ruff format .
uv run mypy .
uv run pytest -q
```

## pyproject baseline

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.mypy]
python_version = "3.11"
strict = true

[tool.pytest.ini_options]
addopts = "-q"
testpaths = ["tests"]
```

## Guardrails

- Run checks with `uv run`, never global binaries
- Keep lint and format separate in CI
- Treat type errors as real failures

## When to use me

Use this before commits, in CI setup, and after large refactors.
