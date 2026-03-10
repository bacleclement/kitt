---
name: branch-creator
description: Creates a git branch from a task manager ticket key using the configured VCS adapter. No interactive bash.
version: 2.0
---

# Branch Creator

Creates correctly-named git branches from task manager tickets.

## Before Starting

1. Read `.claude/config/project.json`
2. Load task-manager adapter: `.claude/adapters/task-manager/{taskManager.type}/ADAPTER.md`
3. Load VCS adapter: `.claude/adapters/vcs/{vcs.type}/ADAPTER.md`

## When to Use

- Before starting implementation (called by implementor)
- User explicitly requests branch creation

## Process

### Step 1: Fetch ticket data

Using the task-manager adapter `read(ticketKey)` operation:
- Get `summary`, `type`

### Step 2: Determine branch type

| Ticket type | Branch prefix |
|-------------|--------------|
| Story / Feature | `feat/` |
| Bug / Defect | `fix/` |
| Task | `feat/` (ask user if ambiguous) |
| Refactor | `refactor/` |

If ticket type is "Task" and purpose is unclear, ask:
> "Is this task a new feature or a bug fix? (feat/fix)"

### Step 3: Generate slug

From ticket summary:
1. Lowercase
2. Replace all non-alphanumeric characters with `-`
3. Collapse consecutive hyphens to one
4. Strip leading/trailing hyphens
5. Truncate to 50 characters

Example: `"Fix: Auth fails intermittently"` → `fix-auth-fails-intermittently`

### Step 4: Confirm branch name

Present to user before creating:
> "Creating branch: `feat/HUB-1234-add-user-authentication`
> Proceed? (yes/no)"

### Step 5: Create branch

Using the VCS adapter `createBranch(ticketKey, type, slug)` operation.
The adapter handles: dirty repo check, existing branch check, git checkout -b.

### Step 6: Confirm

> "✅ Branch created: `feat/HUB-1234-add-user-authentication`
> Ready to implement."

## Error Handling

| Error | Action |
|-------|--------|
| Ticket not found | Verify key with user |
| Task manager auth failed | Follow adapter prerequisites section |
| Dirty working tree | Adapter will prompt — stash or abort |
| Branch already exists | Adapter will offer checkout |

## Tone

One dry KITT-style quip per interaction.
Example: "Branch created. The road ahead is clear. Try not to veer off course."
