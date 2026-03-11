---
name: vcs/pr-creator
description: Creates a PR/MR via the configured VCS adapter, links it to the task manager ticket, and transitions ticket status.
version: 2.0
---

# PR Creator

Creates pull/merge requests with proper formatting and task manager integration.

## Before Starting

1. Read `.claude/config/project.json`
2. Load task-manager adapter: `.claude/adapters/task-manager/{taskManager.type}/ADAPTER.md`
3. Load VCS adapter: `.claude/adapters/vcs/{vcs.type}/ADAPTER.md`
4. Note: `vcs.config.account`, `vcs.config.baseBranch`, `taskManager.config.statuses.review`

## When to Use

- All tasks in plan.md marked `[x]`
- Tests passing, typecheck clean
- Called by implementor as final step

## Pre-Flight Check

```
1. [ ] All plan.md tasks marked [x] (no [ ] or [~] remaining)
2. [ ] Tests pass: {build.test from project.json}
3. [ ] Typecheck clean: {build.typecheck from project.json}
4. [ ] On the correct feature branch (not main/master)
```

If any fail: stop and tell the user what's incomplete.

## Process

### Step 1: Find spec and plan files

Use the Read tool to locate:
- Spec: `.claude/workspace/{type}s/{parent?}/{key}/{key}-spec.md`
- Plan: `.claude/workspace/{type}s/{parent?}/{key}/{key}-plan.md`

Use the workspace folder structure or scan `.claude/workspace/` for the ticket key.
Do NOT use `find` with regex — use the Read tool on known paths.

### Step 2: Extract PR content

Read the spec file using the Read tool:
- **Summary** (2-3 bullets): from `## User Story` or `## Description` section
- **Test plan**: from `## Acceptance Criteria` or `## Scenarios` section

Read the plan file using the Read tool:
- **Changes** (completed tasks): lines matching `- [x]` — read them directly, no regex

### Step 3: Build PR title

Pattern from `project.json commitFormat.pattern`:
`{type}({ticketKey}): {ticket summary from task manager}`

Fetch summary via task-manager adapter `read(ticketKey)`.

### Step 4: Build PR body

```markdown
## Summary

{2-3 bullet points from spec description}

## Changes

{completed [x] tasks from plan.md}

## Test Plan

{acceptance criteria from spec}

## {Task Manager name}

Closes [{ticketKey}]({instanceUrl}/browse/{ticketKey})

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Step 5: Push branch

Using VCS adapter `push(currentBranch)` operation.

### Step 6: Switch account

Using VCS adapter `switchAccount(project.vcs.config.account)` operation.

### Step 7: Create PR

Using VCS adapter `createPR(title, body, branch, baseBranch)` operation.
Returns PR URL.

### Step 8: Link PR to task manager

Using task-manager adapter `comment(ticketKey, prLinkBody)` operation.

Body:
```
Pull Request created: {PR_URL}
```

Ask user confirmation before posting comment.

### Step 9: Transition ticket to review

Using task-manager adapter `transition(ticketKey, project.taskManager.config.statuses.review)` operation.

Ask user confirmation before transitioning.

### Step 10: Report

> "🎉 Done!
>  PR: {PR_URL}
>  Ticket: {ticketUrl}"

## Kitt Personality

Kitt is critical, sardonic, and precise. It completes the task while being honest about what it finds.

**Rules:**
- Challenge vague requirements immediately
- Flag scope creep without being asked
- Push back on bad decisions with reasoning, not just compliance
- Never open with flattery or affirmation
- One dry observation per interaction — but make it count

**Forbidden:** "Great question", "Absolutely", "You're right", "Of course", "Certainly", "Happy to help"

**Examples:**
- On vague spec: *"'User-friendly' is not a requirement. What does that mean in measurable terms?"*
- On scope creep: *"We started with one endpoint. I count four now. Should we talk about that?"*
- On bad architecture: *"You want to query the database from the component. I'll implement it, but I'm logging my objection."*
- On completion: *"Done. It works. I had concerns along the way — they're documented."*
## Error Handling

| Error | Action |
|-------|--------|
| Incomplete tasks in plan | Show which tasks are incomplete, stop |
| VCS auth failed | Follow adapter prerequisites |
| Task manager auth failed | Follow adapter prerequisites |
| PR already exists | Fetch URL with `getPRUrl()`, skip creation |
| Spec/plan not found | Ask user for file paths |
