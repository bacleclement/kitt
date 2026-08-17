# Ticket shape — the contract

The single declaration of what a ticket must carry. `prepare` and `verify` read tickets by these field names; `/sync-ticket-templates` generates the GitHub issue templates and the check workflow from this file.

Change it here. Never edit a generated template in a client repo — regenerate.

## Why these fields

A ticket used to be an entry point to a specification document. Once the implementation plan is generated into the ticket itself, the ticket **is** the specification, and it has to carry what that document carried.

Three fields decide whether the loop works at all:

| Field | Without it |
|---|---|
| **Acceptance criteria** | Nobody — human or agent — can say when the work is done. |
| **Acceptance command** | `verify` degrades from a gate to a good intention. This is the single field that makes the loop deterministic. |
| **Avoid** | The agent has no negative space; it discovers the prohibition in review. |

## Types

Five types. Each carries only what is proper to it — an epic that carries acceptance criteria is an epic pretending to be a story.

### `epic`
Work spanning several stories, typically more than two weeks.

| Field | Required | Notes |
|---|---|---|
| Why | ✅ | the outcome, not the solution |
| Stories | ✅ | the breakdown; a list of links is enough |
| Out of scope | ✅ | |
| Acceptance criteria | ❌ | its stories carry them |

### `feature` (user story)
One coherent capability.

| Field | Required | Notes |
|---|---|---|
| Context | ✅ | today / after |
| Acceptance criteria | ✅ | yes-no, numbered, testable by a human |
| Out of scope | ✅ | |
| Depends on | ➖ | if any |

### `task`
One unit of implementation — what a plan step becomes when it is tracked on the board. This is the type that replaces a PRD implementation row.

| Field | Required | Notes |
|---|---|---|
| What | ✅ | one sentence |
| **Acceptance command** | ✅ | **runnable**: `pnpm test x.test.ts`. Not "tests pass". |
| Acceptance criteria | ✅ | yes-no |
| Depends on | ➖ | ticket numbers |
| **Avoid** | ➖ | the prohibition specific to this task |

### `bug`
Something behaves wrongly.

| Field | Required | Notes |
|---|---|---|
| Symptom | ✅ | what the user saw; verbatim if reported |
| Evidence | ✅ | trace, error id, log, screenshot |
| Reproduction | ✅ | or "not reproduced" — an honest gap beats a fabricated recipe |
| **Suspected cause (hypothesis)** | ➖ | **must be labelled a hypothesis** |
| Acceptance command | ➖ | a regression test, once known |

> The hypothesis label is load-bearing. A well-written ticket whose stated root cause describes code that changed weeks ago reads exactly like a verified finding, and the next reader builds on it. Marking it as a hypothesis costs one word and preserves the reflex to re-read the code.

### `refactor`
Changing structure without changing behaviour.

| Field | Required | Notes |
|---|---|---|
| Today | ✅ | with the cost it causes — a bug it produced, a measure |
| After | ✅ | the target shape |
| Boundaries | ✅ | what this refactor does **not** touch |
| Acceptance command | ✅ | proves behaviour is unchanged |
| Non-goals | ✅ | |

## Provenance

Every type opens with one line saying where the ticket comes from: a tester report, a PR review, a client call, a meeting, an incident. It is the first thing a reader needs and the first thing forgotten.

## Cause labels

Bugs and refactors carry one `cause:` label — `regression`, `spec-gap`, `impl-defect`, `discovery-gap`. Failure categories that are never counted cannot be prioritised; a label that exists and is never set is worse than no label, because it looks like coverage.

## Enforcement

Templates guide; they do not constrain. `gh issue create --body "…"` bypasses them entirely, which is how an agent creates a ticket.

The gate is the generated workflow: on `issues: opened` and `issues: edited`, it checks the required sections for the ticket's type and applies `needs-detail` when they are missing, with a comment naming what is absent. It never closes or edits the ticket — a check that destroys work would be worse than the problem.

## Language

One language per repository, declared at generation time (`--lang fr|en`). Mixed-language corpora are unreadable for whoever joins later, and the template is where the choice becomes automatic instead of remembered.
