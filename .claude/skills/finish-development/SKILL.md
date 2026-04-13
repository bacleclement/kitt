---
name: "🚀 finish-development"
description: Finalizes development work — verifies build, pushes branch, creates PR, transitions ticket to review, and optionally cleans up worktree. Called by orchestrate when the user signals work is done.
version: 2.0
---

# Finish Development Skill

Guides the developer through the complete end-of-work sequence: verify → push → PR → ticket → cleanup.

## When Called

Invoked by `orchestrate` when the user says work is complete (e.g. "I'm done", "feature is ready", "ship it").

---

## Step 1: Read kitt.json

```
build.*                              → verification commands
vcs.config.baseBranch                → base branch for PR
taskManager.config.statuses.review   → review status name
vcs.worktrees.path                   → to detect worktree cleanup needed
commitFormat.*                       → commit message format
```

---

## Step 2: Verify current state

Run `verify` skill — check tests, typecheck, lint pass.

If any check fails: stop. Report what's failing. Do not proceed until the user fixes it or explicitly overrides.

---

## Step 3: Commit remaining changes

Check for uncommitted changes:

```bash
git status --short
```

If any:
```
"You have uncommitted changes:
{list of files}

Commit them now, or leave them out of the PR?"
  A) Commit them — I'll provide a message
  B) Leave them uncommitted
```

If A: ask for commit message, commit using `commitFormat` from kitt.json.

---

## Step 4: Create PR

Invoke `pr-creator` skill. It handles:
- Push branch
- Switch VCS account
- Create PR with title + body from spec/plan
- Link PR to task manager
- Transition ticket to review status

---

## Step 5: Update metadata to completed ⛔ HARD GATE

**This step is MANDATORY. Do not skip it.**

Update the workspace metadata.json:

```json
{ "status": "completed", "updated_at": "{current ISO timestamp}" }
```

Also update the sprint plan file if one exists in `.claude/workspace/` (e.g. `sprint-week-*.md`) — mark the ticket as DONE.

Append a session-log event:
```jsonl
{"ts":"...","skill":"finish-development","event":"completed","data":{"key":"{key}","pr":"{pr_url}"}}
```

**Status lifecycle:**
- `implemented` = all tasks done, code ready (set by implement)
- `completed` = PR created, Jira transitioned, work delivered (set here)

---

## Step 6: Worktree cleanup

Ask:
```
"Were you working in a worktree?
  A) Yes — clean it up
  B) No — we're done"
```

If A: invoke `vcs/worktree-finish` skill.

---

## What NOT to Do

- Never skip verify — broken code does not ship
- Never hardcode status names, branch names, or commands
- Never create the PR before verify passes (unless user explicitly overrides)
- Never assume worktree exists — always ask
