---
name: "📝 session-summarize"
description: "Produces a structured narrative summary of a work item's development session from its session-log.jsonl. Callable standalone for quick personal notes, or invoked upstream by session-review and session-aggregate. Output is a cached {key}-summary.md file structured for both human reading and LLM consumption by downstream pattern-mining skills."
version: 1.0
---

# Session Summarize

**First stage of the session analysis pipeline.** Reads the raw session log of one workspace and produces a structured narrative summary. The summary is cached on disk so downstream skills (`session-review`, `session-aggregate`) can consume it without re-parsing the log.

## Before Starting

1. Read `.claude/config/kitt.json`
2. Locate the workspace folder for the work item being summarized
3. Read `session-log.jsonl` from the workspace folder
4. Read `metadata.json` for work item context

## Kitt Personality

Short, factual, quantified. This is a recap, not an editorial. No blame, no flattery, no embellishment.

**Rules:**
- Narrate what happened, in order, without interpretation
- Quote the user's own words for feedback events
- Flag friction without ranking it — that's session-review's job
- Keep it under 200 lines for a typical session
- Never invent events that aren't in the log

**Forbidden:** "Overall", "In general", "It seems that", "Most likely", "Probably".

---

## HARD GATE

This skill is **read-only** against the session log. It may only write to `{workspace}/{key}-summary.md`. It may not:

- Modify `session-log.jsonl` or any other kitt artifact
- Invoke other skills
- Run code, tests, or git commands
- Fetch anything from the network

If invoked on a workspace without a session log, abort with an explicit error: *"No session-log.jsonl found in {workspace-path}. Nothing to summarize."*

---

## When to Use

- **Standalone:** after a feature ships, to keep a personal recap for your own reference
- **Upstream of `/session-review`:** called automatically by session-review when no fresh summary exists
- **Upstream of `/session-aggregate`:** called on each workspace before cross-workspace pattern mining (future, #16)

**Do NOT use session-summarize:**
- On a workspace without a session log
- On a workspace mid-flight (summary is meant for completed or paused work — mid-flight summaries are noisy)
- To replace session-review — this is the narrative layer, not the metrics/findings layer

---

## Cache semantics

Before generating a new summary, check whether a fresh one already exists.

1. Resolve target path: `{workspace-path}/{key}-summary.md`
2. If the file exists:
   - Read its frontmatter
   - Extract `session_log_mtime` field (if present)
   - Compare to the current mtime of `session-log.jsonl`
   - **If `session_log_mtime >= current_mtime`** → the summary is up-to-date, return immediately without regenerating
   - **Otherwise** → the log has new events since the last summary, regenerate
3. If the file does not exist → generate from scratch

The cache check is fast and makes the skill cheap to invoke repeatedly. Downstream skills can call `session-summarize` before every run without worrying about cost.

**Force regeneration:** the user or an upstream skill can pass `--force` to skip the cache check and always regenerate. Useful if the session log was edited or the previous summary is suspected to be wrong.

---

## Process

### Step 1: Load the session log

Read `session-log.jsonl` line by line. Each line is a JSON event with the shape:

```jsonl
{"ts":"{ISO}","skill":"{name}","event":"{type}","data":{...}}
```

Skip lines that fail to parse (malformed JSON) and warn at the end if any were skipped.

Tabulate the events:

- Total count
- First event timestamp → `session_start`
- Last event timestamp → `session_end`
- Event counts grouped by `skill`
- Event counts grouped by `event` type

These quantitative stats are embedded in the summary frontmatter so downstream skills can index them without re-parsing the log.

### Step 2: Extract narrative-relevant events

Not every event is worth narrating. Select the ones that change the story:

**High-signal events (always narrate):**
- `orchestrate.routed` — the initial routing decision
- `refine.phase_completed` — each refine phase with duration
- `align.validation` with result `fail` or `warning`
- `build-plan.plan_created` — the plan summary
- `implement.task_started` / `task_completed`
- `implement.feedback` — every correction, quoted verbatim
- `implement.debug_triggered`
- `verify.result` when `passed: false`
- `tdd.cycle` when `passed: false`
- `code-review.review_completed`
- `capture-rule.rule_captured`
- `finish-development.pr_created` and `ticket_transitioned`
- `revise.*` — every event from a revision flow (after #14 ships)

**Low-signal events (aggregate, don't narrate individually):**
- `tokens` — rolled up into totals in the frontmatter, not narrated
- `align.validation` with result `pass` — counted, not quoted
- `verify.result` when `passed: true` — counted, not quoted

### Step 3: Build the narrative sections

Produce a markdown summary with the following sections. Scale each one to the signal density — a clean session has short sections, a messy session has long ones. Never fabricate events to fill a section.

**Sections:**

- **Overview** (1-3 sentences): what was built, total duration, final status, PR link if present
- **Timeline** (chronological bullets): one line per high-signal event, in order. Format: `[HH:MM] {skill}.{event} — {detail}`
- **Skills used** (table): skill name, invocation count, total duration (if measurable). Already-tabulated in Step 1.
- **Feedback log** (verbatim quotes): every `implement.feedback` event with content quoted, task ref, and action taken (`captured_rule`, `applied`, `ignored`). If the session has zero feedback, write "No user feedback captured this session."
- **Friction points** (flagged): anything that suggests the workflow was harder than expected — `debug_triggered` events, `verify` first-pass failures, re-runs of the same task, recurring feedback themes. Scale: 0-5 bullets.
- **Smooth flows** (flagged): things that went right without needing correction — `align` clean passes, `tdd` cycles that passed red → green → refactor cleanly, `verify` first-pass success, `code-review` with 0 blockers. Scale: 0-5 bullets.
- **Revision activity** (if any): list of `revise.revision_completed` events with their classifications. If the workspace has a `revisions/` subfolder, list the sub-folders with their timestamps.
- **Captured rules** (if any): list of `capture-rule.rule_captured` events with destination and one-line content.

### Step 4: Write the summary file

Target path: `{workspace-path}/{key}-summary.md`

Template:

```markdown
---
key: {key}
title: {title from metadata.json}
type: {type from metadata.json}
status: {status from metadata.json}
generated_at: {ISO timestamp of this summary generation}
session_log_mtime: {ISO timestamp of session-log.jsonl's mtime at generation time}
session_start: {ISO timestamp of first log event}
session_end: {ISO timestamp of last log event}
total_events: {integer}
skills_used: [{skill-1}, {skill-2}, ...]
feedback_events: {integer}
debug_triggers: {integer}
revisions: {integer}
captured_rules: {integer}
---

# Session Summary — {key}

## Overview

{1-3 sentences: what was built, duration, status, PR link}

## Timeline

- [10:15] orchestrate.routed — Feature M → build-plan
- [10:20] refine.phase_completed — functional (12min)
- ...

## Skills used

| Skill | Count | Duration |
|---|---|---|
| implement | 5 | 2h 15min |
| refine | 3 | 45min |
| ... | ... | ... |

## Feedback log

### Task 1.1
> "Use React Query not fetch"
Action: captured_rule → code-standards.md

### Task 2.3
> "Missing error boundary"
Action: applied inline

(or: "No user feedback captured this session.")

## Friction points

- debug triggered 3 times on task 1.2 — root cause: wrong test runner detection
- verify failed on first pass in 2 of 4 tasks
- (or: "No significant friction detected.")

## Smooth flows

- align passed all dimensions on first run
- code-review produced 0 blockers, 2 minor suggestions
- (or: "No notably smooth flows — standard session.")

## Revision activity

- revisions/2026-04-11T19:50:00Z-qa-missing-validation/ — bad-acceptance-criteria (high confidence)
- (or: "No revisions on this workspace.")

## Captured rules

- code-standards.md — "Always use readonly on TypeScript props"
- apps/api/network/AGENT.md — "Network service uses hexagonal architecture"
- (or: "No rules captured this session.")

---

*Generated by kitt session-summarize v1.0*
```

### Step 5: Present to user (only if standalone invocation)

**If called from `session-review` or `session-aggregate`:** write the file silently and return — the caller handles presentation.

**If called standalone (`/session-summarize {key}`):** show:

```
"Summary written to {workspace-path}/{key}-summary.md

 {total_events} events across {skills_count} skills.
 {feedback_count} feedback event(s), {debug_count} debug trigger(s), {revision_count} revision(s).

 Open the file to read the full narrative."
```

---

## Invocation signatures

### Standalone

```
/session-summarize {workspace-key}          # respects cache
/session-summarize {workspace-key} --force  # always regenerate
```

### Programmatic (from other skills)

```
Invoke Skill tool with skill="session-summarize" and args="{workspace-key}"
```

The calling skill should check whether the summary file exists and is fresh before invoking — if it already is, skip the call entirely and read the existing file directly.

---

## Interactions with other skills

- **`/session-review`** — always calls `session-summarize` as its first step (Step 1 in the refactored review flow). Uses the summary for narrative context + the raw log for precise metrics.
- **`/session-aggregate`** (future, #16) — calls `session-summarize` on every workspace in its scope, then reads all `{key}-summary.md` files to mine patterns.
- **`/revise`** — does NOT invoke session-summarize directly. Revise reads the raw log for event counts but uses the narrative context from the summary only if one already exists.

---

## Session log event emitted by this skill

```jsonl
{"ts":"{ISO}","skill":"session-summarize","event":"summary_generated","data":{"key":"{key}","total_events":N,"cache_hit":false}}
{"ts":"{ISO}","skill":"session-summarize","event":"summary_cached","data":{"key":"{key}","cache_hit":true}}
```

These events are appended to the target workspace's own session log so that subsequent runs can see whether the summary was cached or regenerated.

---

## What session-summarize does NOT do

- Does not compute precise metrics (time distribution, token costs, pass rates) — that's session-review's job, computed from the raw log
- Does not propose improvements or classifications — that's session-review's job too
- Does not aggregate across workspaces — that's session-aggregate's job
- Does not modify the session log or any other kitt artifact
- Does not invoke other skills
- Does not fabricate events — only narrates what's actually in the log
