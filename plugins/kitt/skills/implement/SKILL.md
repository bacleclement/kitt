---
name: implement
description: Execute an approved plan from a GitHub ticket, one step and one commit at a time, ticking progress back into the ticket. Use after prepare has posted a plan and a human approved it. Test-first by default.
---

# Implement

Execute the approved plan. One step, one commit, one proof. Nothing more.

**Core principle:** the plan is the contract; deviating from it silently is how drift ships.

## Before starting

- The plan is posted on the ticket and **approved**. No plan → run `prepare`.
- You are on a branch for this ticket, not on the default branch.

```bash
git rev-parse --abbrev-ref HEAD   # not main / master / staging
```

## Workflow — per step

### 1. Announce

State which step you are on and what will prove it. One line.

### 2. Test first, where it means something

Default is red → green → refactor:

- **Red** — write the failing test, run it, **read the failure**. A test that passes on first run proves nothing.
- **Green** — the minimum code that passes.
- **Refactor** — clean up with the test still green.

Skip the test only where there is nothing to assert (docs, config, a rename). Say when you skip and why — do not skip silently.

⛔ **Confirm the convention before writing the test.** TDD on an unvalidated design locks the drift in: the tests go green around the wrong shape. If `prepare` grounded on a sibling, follow that sibling. If you are about to depart from it, stop and say so.

### 3. Commit the step

```bash
git commit -m "<type>(#<ticket>): <what this step does>"
```

Match the repo's existing commit convention — read `git log --oneline -10` before inventing one.

### 4. Tick the ticket

Update the plan comment: mark the step done, and note anything that turned out different from the plan. The ticket is the shared trace; a step done only in your head is invisible to everyone else.

### 5. Next step

## When the plan is wrong

It will happen. The plan was a hypothesis about code you had partly read.

- **Small correction** (a filename, an extra helper) — do it, note it in the tick.
- **The approach does not hold** — **stop**. Say what you found, propose the revision, wait. Do not renegotiate the plan by unilaterally implementing something else.

## When something breaks

A failing test or a broken build is information, not an obstacle. Follow it to the cause before touching anything:

1. Read the actual error. All of it.
2. Form one hypothesis about the cause.
3. Test that hypothesis cheaply.
4. Only then fix.

Never fix a symptom you do not understand, and never loosen a test to make it pass.

If the failure taught you something the project did not know — a convention nobody wrote down, a trap that will catch the next person — that lesson belongs in the context or in a test. See `verify`, which carries the harness loop.

## Done

All steps ticked → hand over to `verify`. Do not claim completion here; `implement` finishes when the plan is executed, not when it looks right.

## Never

- Never commit on the default branch.
- Never batch several plan steps into one commit — the acceptance check is per step.
- Never mark a step done without its proof having run.
- Never leave the ticket behind the code.
