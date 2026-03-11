---
name: vcs-interface
version: 1.0
---

# VCS Adapter Interface

All VCS adapters MUST implement these operations.
Skills call this interface — never platform CLIs directly.

## How Skills Use Adapters

1. Read `.claude/config/kitt.json`
2. `type = project.vcs.type`  → e.g. `"github"`
3. Load `.claude/adapters/vcs/{type}/ADAPTER.md`
4. Follow the adapter's instructions for the needed operation

## Operations

### switchAccount(account)

Switch to the correct account before any write operation.
`account` comes from `project.vcs.config.account`.

Some platforms use token-based auth (no account switching needed) — adapter handles this.

### createBranch(ticketKey, type, summary)

Create and checkout a new branch following the naming convention:

```
{type}/{ticketKey}-{slug}
```

Where:
- `type` — `feat`, `fix`, `refactor` (from ticket type)
- `ticketKey` — e.g. `HUB-1234`
- `slug` — summary lowercased, non-alphanumeric → hyphens, max 50 chars

Handle dirty repo: stash or warn before creating.
Handle existing branch: offer to checkout instead.

### push(branch)

Push branch to remote, setting upstream:
```bash
git push -u origin {branch}
```

### createPR(title, body, branch, base)

Create a pull/merge request.
- `title` — follows `project.commitFormat.pattern`
- `body` — markdown string (write to temp file)
- `branch` — source branch
- `base` — from `project.vcs.config.baseBranch`

Returns: PR/MR URL.

### getPRUrl(branch)

Get the URL of an existing PR/MR for a branch.

## Branch Naming Convention

```
feat/HUB-1234-add-user-authentication
fix/HUB-5678-fix-login-race-condition
refactor/HUB-9012-extract-auth-module
```

Slug generation rules:
1. Take ticket summary
2. Lowercase
3. Replace non-alphanumeric with hyphens
4. Collapse multiple hyphens to one
5. Strip leading/trailing hyphens
6. Truncate to 50 chars

## PR Body Template

All adapters use this structure:

```markdown
## Summary

{bullet points from spec.md description}

## Changes

{completed tasks from plan.md marked [x]}

## Test Plan

{acceptance criteria from spec.md}

## {Task Manager Link}

Closes [{ticketKey}]({ticketUrl})

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
