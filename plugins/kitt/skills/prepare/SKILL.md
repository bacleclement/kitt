---
name: prepare
description: Turn a GitHub ticket into a grounded, human-approved plan written back into the ticket. Use before writing any code for a ticket. Reads the ticket, loads the scoped context, confirms the sibling pattern in the real code, then posts the plan and stops for approval.
---

# Prepare

A plan written from the ticket alone is a guess. A plan written after reading the code that already does something similar is a decision.

**Core principle:** ground first, plan second, write the plan where the work is tracked.

## When to use

Before the first line of code on any ticket. If you are about to open an editor without a posted, approved plan — stop and run this.

## The Iron Law

```
NO CODE BEFORE AN APPROVED PLAN IN THE TICKET
```

## Workflow

### 1. Read the ticket

```bash
gh issue view <N> --json number,title,body,labels,comments
```

Extract, and say out loud what you found:

- **Acceptance criteria** — the yes/no list. If there is none, stop and say so: you cannot know when you are done.
- **Acceptance command** — the runnable one. Missing? Propose one in the plan and flag that the ticket needs it.
- **Depends on** — unmet dependency means this ticket is not ready.
- **Avoid** — the prohibitions specific to this work.

A ticket's own root-cause analysis is a **hypothesis, not a finding**. It may describe code that has since changed. Verify it before building on it.

### 2. Load the scoped context

Read only what this ticket touches. Resolve context through the project's own layout, in this order, and stop at the first that exists:

1. `AGENTS.md` / `CLAUDE.md` at the repo root — build, test, lint commands and the no-go zones.
2. The rules file the root points at (a constitution, coding standards, an architecture doc).
3. The nearest `AGENTS.md` to the files you will touch.

Do not load the whole documentation set. Context you do not need costs attention and buys nothing.

### 3. Ground on the real code ⛔

Before proposing any file, **find one or two siblings that already do the same kind of thing** and read them.

```bash
# a route? read an existing route. a tool? an existing tool. a repository? an existing one.
grep -rn "<the pattern you are about to reproduce>" <the area> | head
```

Then state, in the plan:

- the sibling file you used as reference,
- the pattern you are reproducing,
- the rule id you are honouring, if the project numbers its rules.

**If the ticket's approach disagrees with what the code actually does — STOP and raise the conflict before writing anything.** Do not implement and let review discover the drift. A design error survives tests: it will pass TDD and verification and still be wrong.

Reuse the existing errors, enums and base types. Grep for one with the right semantics before inventing a new one.

### 4. Write the plan

Split the ticket into steps that are each **one commit, one acceptance check**. If a step cannot state how it will be proven, it is not a step yet.

Post it as a comment on the ticket:

```markdown
## Plan — <date> · `<short SHA>`

**Grounded on:** `path/to/sibling.ts` (pattern: <what>) · rules: <ids, if any>

| # | Step | Proves it | Touches |
|---|---|---|---|
| 1 | … | `<runnable command>` | `path/…` |
| 2 | … | `<runnable command>` | `path/…` |

**Not doing:** <the explicit non-goals, incl. the ticket's Avoid>
**Open question:** <anything the ticket left undecided — or "none">
```

```bash
gh issue comment <N> --body-file <plan.md>
```

The date and SHA are not decoration: they say which state of the code this plan was true for. A plan without them rots silently.

### 5. Stop

Ask for approval and **wait**. This gate is the cheapest place to catch a wrong direction — after it, a mistake costs commits.

Then hand over to `implement`.

## Never

- Never write code in this skill. It plans, it does not build.
- Never keep the plan in your head or in a local file — it goes in the ticket, or the next session starts blind.
- Never present the ticket's root-cause analysis as verified when you have not re-read the code.
