---
name: uv-project
description: Python project management with uv
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: python
---

## What I do

- Guide on uv for Python project management
- Help with dependency management and virtual environments
- Provide pyproject.toml conventions
- Assist with Python packaging

## Project initialization

```bash
uv init my-project          # Create new project
uv init --app               # Application project
uv init --lib               # Library project
```

## Dependency management

```bash
uv add requests             # Add dependency
uv add --dev pytest         # Add dev dependency
uv add --optional web fastapi  # Add optional dependency
uv remove requests          # Remove dependency
uv sync                     # Install all dependencies
uv lock                     # Lock dependencies
```

## Running code

```bash
uv run python main.py       # Run with uv
uv run pytest               # Run tests
uv run --with ipython ipython  # Run with extra deps
```

## Virtual environments

```bash
uv venv                     # Create venv
uv venv --python 3.12       # Create with specific Python
uv python install 3.12      # Install Python version
uv python list              # List available Pythons
```

## pyproject.toml conventions

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "A Python project"
requires-python = ">=3.10"
dependencies = [
    "requests>=2.31.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "ruff>=0.4.0",
    "mypy>=1.10.0",
]

[tool.ruff]
line-length = 100
target-version = "py310"

[tool.mypy]
python_version = "3.10"
strict = true
```

## Common workflows

```bash
# New feature
uv add new-dependency
uv sync
uv run python -m my_module

# Testing
uv run pytest
uv run pytest --cov

# Linting
uv run ruff check .
uv run ruff format .
uv run mypy src/
```

## When to use me

Use this when setting up Python projects, managing dependencies, or working with uv.
