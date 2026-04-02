---
name: python-packaging
description: Build, version, and publish Python packages with modern uv tooling
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: python
---

## What I do

- Set up package metadata in `pyproject.toml`
- Build wheels and source distributions reproducibly
- Validate package artifacts before release

## Package metadata baseline

```toml
[project]
name = "your-package"
version = "0.1.0"
description = "Your package description"
readme = "README.md"
requires-python = ">=3.11"
dependencies = []
```

## Build and verify

```bash
uv sync
uv run python -m build
uv run twine check dist/*
```

## Local install test

```bash
uv run python -m pip uninstall -y your-package || true
uv run python -m pip install dist/*.whl
uv run python -c "import your_package; print('ok')"
```

## Release checklist

1. Update version and changelog
2. Run lint, typecheck, tests
3. Build artifacts
4. Validate with `twine check`
5. Publish with trusted workflow

## Guardrails

- Never publish untested artifacts
- Keep source and wheel outputs in sync
- Prefer automated release pipelines over manual uploads

## When to use me

Use this when creating a new package, preparing a release, or debugging build issues.
