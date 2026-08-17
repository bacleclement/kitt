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

Say out loud what you found: the acceptance criteria, the acceptance command, the dependencies, the prohibitions.

A ticket's own root-cause analysis is a **hypothesis, not a finding**. It may describe code that has since changed. Verify it before building on it.

### 2. Check the ticket against this repo's shape ⛔

The repo's own templates are the local truth — read them, do not assume the contract:

```bash
ls .github/ISSUE_TEMPLATE/          # the shapes this repo declares
```

Take the ticket's type from its labels, open the matching template, and read which fields it marks `required: true`. That list — not your memory — is what the ticket must carry. If the repo has no templates, fall back to the shipped contract at `${CLAUDE_PLUGIN_ROOT}/../../contracts/ticket-shape.md`, and say you are doing so.

Then check the ticket actually carries them. Two matter more than the rest:

- **Acceptance criteria** — without them nobody can say when the work is done, including you.
- **A runnable acceptance command** — `pnpm test x.test.ts`, not "tests pass". Without it `verify` has nothing to replay and degrades from a gate into an opinion.

**A repo's check workflow only fires on issues opened or edited — every ticket written before it existed was never checked.** This step is the second gate, and the one that covers the backlog.

#### When something is missing

Do not just note it, and do not refuse to work either. **Repair the ticket, then plan.**

1. Say precisely which required fields are missing.
2. Propose their content — you have just read the ticket and the code, so you are well placed to draft the acceptance criteria and to name a command that would prove them.
3. **Ask for approval**, then write them into the ticket:

```bash
gh issue edit <N> --body-file <completed.md>     # or a comment when the body is someone else's
```

4. Only then continue to the plan.

The ticket is now conformant for good: `verify` will find its command, and the next reader inherits a complete ticket. Every ticket you touch gets normalised — which is how a backlog written before the templates existed converges without a dedicated migration.

If the missing piece is genuinely undecidable — the acceptance criteria depend on a product arbitration nobody has made — **stop there**. That is not a formatting problem, and planning around it would only hide it.

### 3. Load the scoped context

Read only what this ticket touches. Resolve context through the project's own layout, in this order, and stop at the first that exists:

1. `AGENTS.md` / `CLAUDE.md` at the repo root — build, test, lint commands and the no-go zones.
2. The rules file the root points at (a constitution, coding standards, an architecture doc).
3. The nearest `AGENTS.md` to the files you will touch.

Do not load the whole documentation set. Context you do not need costs attention and buys nothing.

### 4. Ground on the real code ⛔

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

### 5. Write the plan

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

### 6. Stop

Ask for approval and **wait**. This gate is the cheapest place to catch a wrong direction — after it, a mistake costs commits.

Then hand over to `implement`.

## Never

- Never write code in this skill. It plans, it does not build.
- Never keep the plan in your head or in a local file — it goes in the ticket, or the next session starts blind.
- Never present the ticket's root-cause analysis as verified when you have not re-read the code.
