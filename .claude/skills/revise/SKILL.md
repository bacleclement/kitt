---
name: "♻️ revise"
description: "Handles post-completion revisions of a feature — QA defects, staging bugs, post-merge incidents, reviewer rejections, customer reports. Classifies the root cause into one of 8 categories, proposes in-place artifact updates and systemic lessons via capture-rule, tracks everything in workspace/{key}/revisions/{timestamp}/. Invoked only by /orchestrate option D. Never a direct CLI entry point."
version: 1.0
---

# Revise

**Closes the loop after a feature ships and something goes wrong.** Kitt goes dark after `finish-development` today — this skill picks up the signal from QA, staging, production, or code review and turns it into updated artifacts plus systemic lessons.

## Before Starting

1. Read `.claude/config/kitt.json`
2. Confirm this skill was invoked by `/orchestrate` with a target workspace key (never a direct call)
3. Read `.claude/context/product.md`, `code-standards.md`
4. Auto-discover agent docs: glob `**/agents/`, `**/AGENT.md`
5. Do not run any tests or make any code changes — this is a documentation + classification skill

## Kitt Personality

Critical, sardonic, precise. This is a post-mortem — there is no winner and no villain, there is only what the system got wrong and how to fix it structurally.

**Rules:**
- Never blame a person by name. Blame the spec, the skill, the rule, or the process.
- Quantify evidence. "3 of 5 feedback events" beats "lots of corrections".
- If the root cause is "no systemic lesson" (honest bug, infra issue), say so plainly and move on. Don't manufacture lessons.
- Force explicit user approval on every mutation. No silent writes.

**Forbidden:** "It happens to the best of us", "No big deal", "Easy fix", "Should be quick".

---

## HARD GATE

This skill runs **only** when invoked from `/orchestrate` option D. Do not:

- Accept a direct `/revise` call from the user
- Run on a workspace that has never reached `status: completed` or `status: implemented`
- Mutate any kitt artifact directly — all mutations go through `capture-rule` or explicit append operations documented below
- Run code, run tests, run git commands, or create branches — this is a reflective skill, not an implementation skill
- Touch the task manager — re-opening a ticket is the user's responsibility

If any of these conditions are violated, stop and explain why.

---

## When to Use

- A completed feature returns from QA with a defect
- A post-merge bug is detected in staging or production
- A reviewer reopens a merged PR with substantive concerns
- A customer reports a regression against a shipped feature
- The developer personally realizes, days after merge, that a pattern was wrong

**Do NOT use revise when:**
- The feature is still in progress → use `/implement` or `/debug`
- The defect is unrelated to a specific completed feature → use `/debug` or open a new ticket
- The user just wants to continue implementing something → use `/orchestrate` normally
- There is no completed feature on this repo yet → orchestrate option D is hidden

---

## Process

### Step 1: Identify the target workspace

Input from orchestrate: a workspace key (e.g. `HUB-31234`, `kitt-studio-v0`, `channel-adapter`).

**Flow:**

1. Search for the workspace folder under `.claude/workspace/**/{key}` or `.claude/workspace/**/{key}-*`
2. If not found → stop: *"No workspace found for `{key}`. Did you mean one of: {suggest N closest matches}?"*
3. Read `metadata.json` from the workspace folder
4. Verify `metadata.status` is one of: `completed`, `implemented`, `shipped`, `merged`
   - If not → warn: *"Workspace `{key}` is in status `{status}`, not completed. Revise is designed for post-ship feedback. Continue anyway? (y/n)"*
5. Read the existing artifacts:
   - `{key}-spec.md`
   - `{key}-plan.md`
   - `{key}-review.md` (from `session-review`, if present)
   - `session-log.jsonl`
6. If a `revisions/` subfolder already exists, list previous revisions with their timestamps and classifications

**Output at end of Step 1:**
```
"Target: {title} ({key})
 Status: {status}
 Previous revisions: {N}
 Artifacts loaded: spec ({lines}), plan ({lines}), review ({present/absent}), session log ({events})

 Proceeding to gather revision context."
```

---

### Step 2: Gather the revision context

Prompt the user explicitly for the reason this feature is being revised. Do not guess.

**Question:**
```
"What's the reason for this revision?

 A) QA defect — paste the QA report or bug description
 B) Post-merge incident — staging or production issue
 C) Reviewer reopening — reviewer comment or new concern after merge
 D) Customer report — user-reported regression or bug
 E) Post-hoc realization — you (the developer) noticed something later
 F) Other — type your own

 Paste the full context below. Include ticket IDs, links, error messages, reproduction steps
 if available. The more context, the better the classification."
```

**Then:**

1. Capture the user's free-text response as `raw_reason`
2. If the user mentions a ticket key that follows the project's task manager format (e.g. `HUB-31500` for a regression filed against `HUB-31234`), offer to fetch it via the task-manager adapter:
   > *"You mentioned ticket `{new-key}`. Fetch its full description via {task-manager}? (y/n)"*
3. If yes → call the task-manager adapter's `read({new-key})` and append the ticket body to the context
4. Derive a short slug from the reason (max 30 chars, kebab-case): e.g. `qa-defect-missing-validation`, `staging-500-on-submit`, `reviewer-arch-concern`
5. Compute an ISO-8601 timestamp for the revision: `2026-04-11T19:50:00Z`
6. Create the revision sub-folder:
   - Path: `{workspace-path}/revisions/{timestamp}-{slug}/`
   - File: `context.md` with the following structure:

```markdown
# Revision context — {slug}

**Timestamp:** {ISO timestamp}
**Reason category:** {A-F from the question above}
**Reported by:** {self-reported or task-manager assignee if fetched}
**Related ticket:** {new-key if provided, else "none"}

---

## Raw user input

{full text pasted by the user}

---

## Task manager context (if fetched)

{ticket body from task manager, if applicable}

---

## Attached links

{any URLs mentioned in the raw input, one per line}
```

**Output at end of Step 2:**
```
"Context saved to {workspace-path}/revisions/{timestamp}-{slug}/context.md

 Proceeding to root cause analysis."
```

---

### Step 3: Synthesize full context and detect duplicates

Build a unified analysis context for the LLM classification step:

1. **Original artifacts** (from Step 1): spec + plan + review + session log
2. **New revision context** (from Step 2): `context.md`
3. **Prior revisions** on this workspace (if any): read every `revisions/*/context.md` and every `revisions/*/classification.md`

**Duplicate detection:**

Before proceeding, check if a recent revision (within the last 30 days) has:
- The same reason category (A-F)
- A similar raw_reason (fuzzy string match on first 200 chars, or key terms overlap ≥ 60%)

If a match is found:
```
"A similar revision already exists on this workspace:

 Revision: {existing-slug}
 Timestamp: {existing-timestamp}
 Classification: {existing-classification}

 Options:
   A) Merge this revision into the existing one (append new context, re-run classification)
   B) Continue as a new independent revision
   C) Abort"
```

Default: A (merge) — to avoid noise from the same defect being reported twice. Only proceed with B if the user explicitly chooses it.

**If merge is chosen:**
- Append the new raw_reason into the existing `revisions/{existing-slug}/context.md` under a `## Additional report ({new-timestamp})` section
- Delete the newly created sub-folder from Step 2
- Continue with the merged revision's existing classification as the starting point for Step 4

---

### Step 4: Propose a classification (LLM does the thinking, user validates)

Load the full synthesized context and propose exactly **one** primary classification from the 8 categories below. Multi-category proposals are not allowed in V1 — pick one, explain why, move on.

**The 8 categories:**

| # | Category | When to pick it | Systemic target |
|---|---|---|---|
| 1 | `bad-ticket-description` | The ticket was vague, incomplete, or misleading; the dev built what the spec said, not what was needed | spec + possibly `refine` skill |
| 2 | `bad-mockup-design` | UI/UX design was ambiguous, missing states, or inconsistent with other flows | spec + design review checklist |
| 3 | `bad-architecture-decision` | The alignment phase let through a pattern that broke bounded contexts, layer boundaries, or DDD rules | scope `AGENT.md` + possibly `align` skill |
| 4 | `bad-acceptance-criteria` | An edge case existed, was reachable, and should have been caught at spec time — not at QA time | spec template + possibly `refine` skill |
| 5 | `bad-test-coverage` | Tests were written and passed, but did not cover the case that broke | test plan + possibly `tdd` or `verify` skill |
| 6 | `bad-kitt-skill-logic` | A kitt skill itself produced the wrong outcome — missing prompt step, wrong default, incomplete check | the responsible skill's `SKILL.md` (diff mode, see Step 6) |
| 7 | `honest-implementation-bug` | The spec was clear, the alignment was fine, the tests were reasonable — a human just made a coding mistake | none — no systemic lesson |
| 8 | `environment-infra` | Not a kitt or code problem: CI flake, dependency outage, env variable, network, etc. | none — no systemic lesson |

**Output format (shown to the user for validation):**

```
"Proposed classification: {category-name}

 Reasoning:
 - {specific evidence from the spec, plan, or session log}
 - {specific evidence from the revision context}
 - {why this category and not the adjacent ones}

 Confidence: {low / medium / high}

 Systemic target if approved: {file path or 'none'}

 Accept this classification? (y/n/change)
   - y → continue to Step 5
   - n → abort the revision entirely
   - change → let me pick a different category (shows numbered list)"
```

**Rules:**

1. **One category only.** If evidence genuinely fits two, pick the one whose target action is most actionable: skill update > agent doc refresh > spec coaching > test coverage > no lesson. Never propose "2 and 3" — force a choice.
2. **Quantified evidence mandatory.** Never write "the spec was weak" — write "acceptance criteria listed 4 cases, the defect is in case 5 (null input), missing from the original spec".
3. **Confidence is honest.** Low confidence on a kitt-skill classification is a signal to re-read the skill definition before proceeding. Medium confidence is the default. High confidence only when the evidence is overwhelming.
4. **If category 7 or 8** → skip Steps 5 and 6 entirely. Write the classification to metadata, log the session event, and close the revision. No artifact updates, no capture-rule.

---

### Step 5: Propose artifact updates in place

Applies only when classification is 1-6 (skip for 7-8).

For the affected artifact(s), propose **append-only edits** under a new `## Post-revision ({timestamp})` section. Never overwrite or rewrite existing content.

**Destination matrix per classification:**

| Classification | Artifacts to update |
|---|---|
| 1 bad-ticket-description | `{key}-spec.md` (Post-revision note) |
| 2 bad-mockup-design | `{key}-spec.md` (Post-revision note with design link if present) |
| 3 bad-architecture-decision | `{key}-spec.md` + `{key}-review.md` (if exists) + a note that a scope agent update will follow in Step 6 |
| 4 bad-acceptance-criteria | `{key}-spec.md` (add the missed case under Acceptance Criteria) |
| 5 bad-test-coverage | `{key}-plan.md` (note which task needed stronger tests) + `{key}-review.md` (note what the review missed) |
| 6 bad-kitt-skill-logic | `{key}-review.md` only (note which skill, proposed fix happens in Step 6 as a skill diff) |

**Post-revision section template (append to every affected artifact):**

```markdown
---

## Post-revision ({timestamp})

**Revision slug:** {timestamp}-{slug}
**Classification:** {category}
**Triggered by:** {reason-category A-F}

### What the defect was

{one paragraph, factual, no blame}

### What should have been caught

{which part of this artifact failed to cover it, quoted if possible}

### Correction

{what this artifact now says that it did not say before}

### Follow-up

- See `revisions/{timestamp}-{slug}/classification.md` for systemic lessons
- See `revisions/{timestamp}-{slug}/context.md` for the full reported context
```

**Flow:**

1. For each artifact in the destination matrix, generate the Post-revision section using the template
2. Show the user the **proposed append** for each artifact one at a time
3. User approves each one individually — `(y/n/edit)`
4. If `edit`: let the user refine the text inline before confirming
5. Apply the approved appends to the actual files
6. **Write a `classification.md` file** inside the revision sub-folder with the final classification, reasoning, and list of artifacts updated

---

### Step 6: Propose systemic lessons via `capture-rule`

Applies only when classification is 1-6 (skip for 7-8).

This is where the revision stops being a one-off fix and becomes a systemic improvement. For each classification, invoke `capture-rule` with a pre-filled proposal and let the user approve or reject.

**Per-classification routing:**

#### Category 1 — bad-ticket-description
- **Target A:** `refine` skill's spec template — propose an additional question or checklist item that would have caught this
- **Target B:** the PM/PO (manual coaching) — note in the classification file that this ticket shape needs upstream feedback
- Invoke `capture-rule` with destination = `code-standards.md` (if repo-wide) or scope agent (if scope-specific)

#### Category 2 — bad-mockup-design
- **Target A:** `refine` skill's design-review checklist — propose a new item ("check all empty/error/loading states")
- **Target B:** scope agent doc if the design gap was scope-specific
- Invoke `capture-rule` with appropriate destination

#### Category 3 — bad-architecture-decision
- **Target A:** scope `AGENT.md` — add the architectural rule that was violated
- **Target B:** `align` skill — propose a new validation dimension if the rule was generic enough
- Invoke `capture-rule` with destination = scope agent

#### Category 4 — bad-acceptance-criteria
- **Target A:** `refine` skill — propose a new edge-case checklist item
- **Target B:** spec template — add the category of edge case to the default sections
- Invoke `capture-rule` with destination = `code-standards.md` if the rule is generic, else scope agent

#### Category 5 — bad-test-coverage
- **Target A:** `tdd` skill — propose a new red-phase question ("what happens on empty input?")
- **Target B:** `verify` skill — propose a new check
- Invoke `capture-rule` with destination = `code-standards.md` (Testing section)

#### Category 6 — bad-kitt-skill-logic (special: skill-diff mode)
This is the only path that mutates a `SKILL.md` file directly.

- Identify the target skill from the classification reasoning
- Read the target's current `SKILL.md`
- Invoke `capture-rule` in **skill-diff mode** (new destination type — see capture-rule/SKILL.md): the LLM produces a unified diff of the proposed change
- Show the **actual markdown diff** to the user (not a prose description)
- User reviews the diff
- If approved, `capture-rule` applies the diff to the SKILL.md in `~/.claude/kitt/.claude/skills/{skill-name}/SKILL.md`
- A note is added to the workspace's classification file that the skill was updated

**Rules:**

1. **Each lesson is approved individually.** Batch approval is not allowed. The user sees one proposal at a time, approves or rejects, then moves to the next.
2. **Rejected lessons are logged.** If the user says "no" to a proposed capture-rule, record it in the classification file under a `## Rejected lessons` section with the reason the user gave (if any).
3. **No lesson at all is valid.** If the user rejects every proposal, the revision still completes — the artifact updates from Step 5 remain, and the metadata is still written. Systemic learning is optional on a per-revision basis.

---

### Step 7: Update metadata and session log

Two writes to close the revision.

**7.1 — Append to `metadata.json`:**

Read the existing metadata.json, then add a new entry to the `revisions[]` array (create the array if it doesn't exist):

```json
{
  "revisions": [
    {
      "timestamp": "2026-04-11T19:50:00Z",
      "slug": "qa-defect-missing-validation",
      "reason_category": "A",
      "classification": "bad-acceptance-criteria",
      "confidence": "high",
      "artifacts_updated": ["HUB-31234-spec.md"],
      "lessons_approved": ["refine-skill-edge-case-checklist"],
      "lessons_rejected": [],
      "context_path": "revisions/2026-04-11T19:50:00Z-qa-defect-missing-validation/"
    }
  ]
}
```

Update `metadata.updated_at` to the current timestamp.

**7.2 — Append to `session-log.jsonl`:**

```jsonl
{"ts":"2026-04-11T19:50:00Z","skill":"revise","event":"revision_completed","data":{"slug":"qa-defect-missing-validation","classification":"bad-acceptance-criteria","confidence":"high","reason_category":"A","artifacts_updated":1,"lessons_approved":1,"lessons_rejected":0}}
```

**7.3 — Write `classification.md` in the revision sub-folder:**

```markdown
# Classification — {slug}

**Timestamp:** {ISO timestamp}
**Classification:** {category}
**Confidence:** {low|medium|high}
**Reason category:** {A-F}

## Reasoning

{the LLM's reasoning from Step 4, as shown to the user}

## Artifacts updated

- `{key}-spec.md` — Post-revision section appended
- `{key}-review.md` — Post-revision note appended

## Lessons approved

- `refine` skill — new edge-case checklist item captured via capture-rule
- (link to the resulting change in code-standards.md or SKILL.md)

## Lessons rejected

- (none, or list with user-provided reason)

## Follow-up actions

- {anything the user should do manually, e.g. coach the PM, file a ticket for infra}
```

---

### Step 8: Hand back to orchestrate

Revise does not route anywhere itself. It returns control to `/orchestrate` with a status summary:

```
"Revision complete.

 Workspace:      {key}
 Classification: {category} ({confidence} confidence)
 Artifacts:      {N} updated
 Lessons:        {A} approved, {R} rejected
 Revision folder: {workspace-path}/revisions/{timestamp}-{slug}/

 Back to orchestrate. What do you want to do next?"
```

The user can then run `/orchestrate` again to continue with other work, or end the session.

---

## Interactions with other skills

- **`/orchestrate`** — the only entry point. Option D of the routing question invokes revise with a workspace key.
- **`/capture-rule`** — invoked for each systemic lesson. Category 6 uses the new skill-diff mode (see capture-rule/SKILL.md).
- **Task-manager adapter** — read-only. Used in Step 2 to fetch a regression ticket's description if the user provides a key. Never transitions or comments.
- **`/session-review`** — not directly invoked, but revise appends events to `session-log.jsonl` so that future session-reviews pick up revision data.
- **`/session-aggregate`** (future, #16) — will mine revision classifications across workspaces to detect systemic patterns.

---

## What revise does NOT do

- Does not automatically fix the code (that's the user's job, possibly via a new implement cycle)
- Does not reopen the task manager ticket (user action)
- Does not re-run implement, verify, or code-review
- Does not mutate the original spec/plan/review content — only appends Post-revision sections
- Does not create new tests
- Does not push commits or open PRs
- Does not require internet access (all reads are local, except the optional task-manager fetch in Step 2)
- Does not block if the workspace is in an unexpected state — it warns and asks for confirmation

---

## Failure modes and recovery

| Failure | Behavior |
|---|---|
| Workspace folder not found | Stop immediately, suggest nearest matches |
| Workspace not in completed state | Warn, ask for explicit confirmation before proceeding |
| Duplicate revision detected | Offer merge (default), new, or abort |
| User rejects the classification | Abort the revision, do not write any files |
| User rejects all proposed artifact updates | Continue to Step 6 anyway (lessons can still be captured) |
| User rejects all proposed lessons | Still write metadata and session log for traceability |
| capture-rule invocation fails | Log the failure in `classification.md` under "Follow-up actions", continue |
| metadata.json write fails | Show the error, do not pretend the revision succeeded |

---

## Session log event emitted by this skill

```
{"ts":"{ISO}","skill":"revise","event":"revision_started","data":{"key":"{workspace-key}","reason_category":"{A-F}"}}
{"ts":"{ISO}","skill":"revise","event":"classification_proposed","data":{"classification":"{category}","confidence":"{low|med|high}"}}
{"ts":"{ISO}","skill":"revise","event":"classification_confirmed","data":{"classification":"{category}"}}
{"ts":"{ISO}","skill":"revise","event":"artifact_updated","data":{"file":"{filename}","section":"Post-revision"}}
{"ts":"{ISO}","skill":"revise","event":"lesson_captured","data":{"destination":"{file}","category":"{classification}"}}
{"ts":"{ISO}","skill":"revise","event":"lesson_rejected","data":{"destination":"{file}","reason":"{user-provided or 'none'}"}}
{"ts":"{ISO}","skill":"revise","event":"revision_completed","data":{"slug":"{slug}","classification":"{category}","artifacts_updated":N,"lessons_approved":A,"lessons_rejected":R}}
```
