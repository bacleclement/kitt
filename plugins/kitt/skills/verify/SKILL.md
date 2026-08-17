---
name: verify
description: Replay the ticket's runnable acceptance command and block on failure. Use before claiming any work is complete, fixed, or passing. Turns a failure into a lesson — an added test or a context update — never into a silent pass.
---

# Verify

Claiming work is done without running the check is not speed. It is a guess dressed as a result.

**Core principle:** evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE FROM THIS SESSION
```

If you have not run the command **in this session**, you cannot say it passes. Not "it should pass". Not "it passed earlier".

## Workflow

### 1. Get the acceptance command from the ticket

Each plan step carries the command that proves it. Run **all** of them, plus the project's own gates:

```bash
gh issue view <N> --json body,comments   # the plan comment carries the commands
```

Then the project gates — read them from `AGENTS.md` / `CLAUDE.md`, do not invent them. Typically lint, type-check, tests, format.

### 2. Run them. Read the output.

Run each one. Read what it actually printed — not the exit code alone, not the last line.

A green linter does not compile the code. A green build does not run the tests. A green unit suite does not prove the feature works end to end. Each gate proves exactly what it checks and nothing more.

### 3. Report honestly

State, per gate: the command, and pass or fail. If something did not run, say it did not run — an unrun check is not a passing one.

### 4. On failure — BLOCK ⛔

```
Failure → this ticket is not done. `finish` must not open the PR.
```

Fix, then **re-run every gate from the start**. A fix that repairs one case and breaks another is not a fix. This is the no-regression rule, and it is not negotiable: *any change that makes a previously passing check fail is rejected, however well it solves the target case.*

### 5. On failure — learn (the harness loop)

A check that broke is the cheapest signal this project will ever get. Before moving on, ask what would have caught it earlier, and make that thing exist:

| What the failure revealed | What to add |
|---|---|
| A convention nobody wrote down | one line in the project's rules file — where they already live |
| A case the tests never covered | a regression test, named after the ticket |
| A trap in a tool or a provider | a note next to the code that touches it |
| Nothing generalisable — a typo | nothing. Do not inflate the context. |

Keep the addition **minimal and targeted**. A harness that grows with every incident becomes the bloat that made the agent worse in the first place. And apply the same no-regression rule to the addition itself: a new rule that contradicts an existing one is rejected, not stacked on top.

Then say what you added, in one line, so it lands in the PR description.

## Never

- Never claim a pass you did not watch happen.
- Never weaken a check to make it green.
- Never let a failure disappear without either a fix or a written reason it is acceptable.
- Never skip the re-run after a fix.
