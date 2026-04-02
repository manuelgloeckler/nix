---
name: gh-pr
description: GitHub CLI workflows for PRs, issues, and code review
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
---

## What I do

- Help create well-structured PRs with good descriptions
- Guide on PR review workflows
- Provide templates for issues and PRs
- Assist with GitHub Actions and CI/CD

## Creating PRs

```bash
gh pr create --title "feat: add user authentication" --body "$(cat <<'EOF'
## Summary
- Add OAuth2 login flow with Google provider
- Include session management

## Changes
- New auth module with JWT handling
- Login/logout endpoints
- Session middleware

## Testing
- Unit tests for auth module
- Manual testing with Google OAuth
EOF
)"
```

## PR template

```markdown
## Summary
Brief description of the change.

## Changes
- Bullet list of key changes
- Include any breaking changes

## Testing
How was this tested?

## Screenshots
If applicable, add screenshots.
```

## Review workflow

```bash
gh pr list                          # List open PRs
gh pr view <number>                 # View PR details
gh pr checkout <number>             # Check out PR locally
gh pr review <number> --approve     # Approve PR
gh pr review <number> --request-changes --body "..."
gh pr merge <number> --squash       # Squash and merge
```

## Issues

```bash
gh issue create --title "Bug: login fails" --body "..."
gh issue list --label "bug"
gh issue view <number>
gh issue close <number>
```

## When to use me

Use this when creating PRs, reviewing code, managing issues, or working with GitHub workflows.
