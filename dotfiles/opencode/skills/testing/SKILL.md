---
name: testing
description: Testing patterns and best practices for multiple languages
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: testing
---

## What I do

- Provide testing patterns for Python, TypeScript, and more
- Guide on test structure and organization
- Help with mocking and fixtures
- Assist with CI/CD test integration

## Python testing (pytest)

```python
# test_user.py
import pytest

def test_create_user(db):
    user = User(name="Test", email="test@example.com")
    assert user.name == "Test"

@pytest.fixture
def db():
    return Database()

@pytest.mark.parametrize("input,expected", [
    ("a", 1),
    ("ab", 2),
])
def test_length(input, expected):
    assert len(input) == expected
```

```bash
pytest                          # Run all tests
pytest tests/test_user.py       # Run specific file
pytest -k "test_user"           # Run by name
pytest --cov=src                # With coverage
```

## TypeScript testing (vitest)

```typescript
// user.test.ts
import { describe, it, expect, vi } from 'vitest';

describe('User', () => {
  it('should create user', () => {
    const user = new User('Test');
    expect(user.name).toBe('Test');
  });

  it('should mock API call', async () => {
    const mock = vi.fn().mockResolvedValue({ id: 1 });
    const result = await fetchUser(mock);
    expect(mock).toHaveBeenCalledOnce();
  });
});
```

## Test organization

```
tests/
├── unit/           # Fast, isolated tests
├── integration/    # Component interaction tests
├── e2e/            # End-to-end tests
└── fixtures/       # Shared test data
```

## Best practices

- Test behavior, not implementation
- One assertion per test when possible
- Use descriptive test names: `should_<action>_when_<condition>`
- Keep tests independent and isolated
- Use fixtures for shared setup
- Mock external dependencies

## When to use me

Use this when writing tests, setting up test infrastructure, or debugging test failures.
