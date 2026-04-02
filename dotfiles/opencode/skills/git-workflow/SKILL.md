---
name: git-workflow
description: Git best practices for branching, commits, and rebasing
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: git
---

## What I do

- Guide on conventional commit messages (feat, fix, chore, docs, etc.)
- Recommend branch naming conventions (feat/..., fix/..., chore/...)
- Help with interactive rebase vs merge decisions
- Provide commit message templates

## Commit conventions

Format: `type(scope): description`

Types:
- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation changes
- `style`: formatting, no code change
- `refactor`: code restructuring
- `test`: adding/fixing tests
- `chore`: maintenance tasks

Examples:
```
feat(auth): add OAuth2 login flow
fix(api): handle null response from user endpoint
docs(readme): update installation instructions
```

## Branch naming

```
feat/add-user-auth
fix/resolve-memory-leak
chore/update-dependencies
docs/improve-api-reference
```

## Rebase vs merge

- Use `git rebase` for local feature branches before merging
- Use `git merge` for shared/public branches
- Never rebase published commits
- Use `git pull --rebase` to keep local branches clean

## Useful commands

```bash
git log --oneline -10          # Recent commits
git diff --staged              # Review staged changes
git commit --amend             # Fix last commit (before push)
git rebase -i HEAD~3           # Interactive rebase last 3 commits
git stash                      # Save work in progress
git stash pop                  # Restore stashed changes
```

## When to use me

Use this when writing commit messages, naming branches, or deciding between rebase and merge workflows.
