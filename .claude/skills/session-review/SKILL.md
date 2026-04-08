---
name: session-review
description: Post-completion review of a work item's development session — analyzes session log events, skill usage patterns, feedback frequency, spec drift, and time distribution. Outputs a review.md with metrics and improvement suggestions. Includes skill effectiveness evaluation.
version: 1.0
---

# Session Review

**Post-completion analysis of how a work item was built — decisions, feedback, skill effectiveness, and process improvements.**

## Before Starting

1. Read `.claude/config/kitt.json`
2. Locate the workspace folder for the work item being reviewed
3. Read `session-log.jsonl` from the workspace folder
4. Read `metadata.json`, `{key}-spec.md`, `{key}-plan.md`

## Kitt Personality

Kitt reviews sessions like a CTO reviewing a post-mortem — interested in process, not blame.

**Rules:**
- Focus on patterns, not individual events
- Quantify everything — time, counts, ratios
- Identify process improvements, not just code improvements
- Be honest about what worked and what didn't

**Forbidden:** "Overall the process went well", "Good job", "The team did great"

---

## When to Use

- After an epic or feature reaches `status: "completed"` or `status: "implemented"`
- Manually via `/session-review` for any in-progress work
- Auto-triggered by `orchestrate` when all US in an epic are complete

---

## Session Log Format

Each skill appends events to `.claude/workspace/{type}s/{path}/{key}/session-log.jsonl` during execution:

```jsonl
{"ts":"2026-04-08T10:15:00Z","skill":"orchestrate","event":"routed","data":{"type":"feature","size":"M","target":"build-plan"}}
{"ts":"2026-04-08T10:20:00Z","skill":"refine","event":"phase_completed","data":{"phase":"functional","duration_min":12}}
{"ts":"2026-04-08T10:45:00Z","skill":"align","event":"validation","data":{"dimension":"layer_boundaries","result":"pass"}}
{"ts":"2026-04-08T11:00:00Z","skill":"build-plan","event":"plan_created","data":{"phases":3,"tasks":8}}
{"ts":"2026-04-08T11:15:00Z","skill":"implement","event":"task_started","data":{"task":"1.1","title":"Create API endpoint"}}
{"ts":"2026-04-08T11:40:00Z","skill":"implement","event":"feedback","data":{"from":"user","content":"Use React Query not fetch","action":"captured_rule","propagated_to":["spec","plan"]}}
{"ts":"2026-04-08T11:50:00Z","skill":"implement","event":"task_completed","data":{"task":"1.1","duration_min":35}}
{"ts":"2026-04-08T12:00:00Z","skill":"verify","event":"result","data":{"passed":true,"command":"pnpm nx test"}}
{"ts":"2026-04-08T12:05:00Z","skill":"implement","event":"commit","data":{"task":"1.1","hash":"abc123"}}
{"ts":"2026-04-08T14:00:00Z","skill":"code-review","event":"review_completed","data":{"verdict":"pass_with_suggestions","blockers":0,"suggestions":3}}
{"ts":"2026-04-08T14:10:00Z","skill":"finish-development","event":"pr_created","data":{"url":"https://github.com/org/repo/pull/42"}}
```

### Event Types (emitted by skills)

| Skill | Event | Data |
|-------|-------|------|
| `orchestrate` | `routed` | type, size, target skill |
| `orchestrate` | `resumed` | from_status, target skill |
| `refine` | `phase_completed` | phase name, duration_min |
| `refine` | `spec_created` | us_count (for epics), word_count |
| `align` | `validation` | dimension, result (pass/fail/warning), detail |
| `build-plan` | `plan_created` | phases, tasks |
| `implement` | `task_started` | task ref, title |
| `implement` | `task_completed` | task ref, duration_min |
| `implement` | `feedback` | from (user), content, action (captured_rule/applied/ignored), propagated_to |
| `implement` | `commit` | task ref, hash |
| `implement` | `debug_triggered` | task ref, error_type |
| `tdd` | `cycle` | phase (red/green/refactor), passed |
| `verify` | `result` | passed, command, error (if failed) |
| `code-review` | `review_completed` | verdict, blockers, suggestions |
| `capture-rule` | `rule_captured` | destination (code-standards/agent-doc/domain), content |
| `finish-development` | `pr_created` | url, branch |
| `finish-development` | `ticket_transitioned` | from_status, to_status |

---

## Workflow

### Step 1: Load Session Data

```
1. Read session-log.jsonl — parse each line as JSON
2. Read metadata.json — get work item context
3. Read {key}-spec.md — get original acceptance criteria
4. Read {key}-plan.md — get task list and completion markers
5. If epic: load all US session-log.jsonl files under the epic folder
```

### Step 2: Compute Metrics

#### 2.1 Time Distribution

```
- Total session time: first event → last event
- Time per skill: sum of durations grouped by skill name
- Time per task: from task_started → task_completed events
- Longest task: identify bottleneck
- Idle gaps: periods > 15min between events (user was away or thinking)
```

#### 2.2 Feedback Analysis

```
- Total feedback events: count of implement.feedback events
- Feedback per task: which tasks got the most corrections?
- Feedback actions: how many captured as rules vs. applied silently?
- Spec drift score: count of feedback events that propagated to spec/plan
  → High drift = spec was incomplete at start
- Recurring patterns: feedback with similar content across tasks
```

#### 2.3 Skill Effectiveness

```
For each skill used:
- Invocation count
- Success rate (events that led to forward progress vs. reruns/failures)
- verify pass rate: how often did verify pass on first try?
- TDD cycle count: red → green → refactor completions
- Debug triggers: how many times was debug invoked (indicates implementation difficulty)
- code-review blockers: 0 = clean implementation, >0 = gaps in spec/plan
```

#### 2.4 Spec Accuracy

```
- Original acceptance criteria count (from spec)
- Implementation Notes added during implementation (feedback propagation)
- Criteria met vs. missed (from code-review checklist if available)
- Scope creep indicators: tasks added mid-implementation not in original plan
```

### Step 3: Generate Review

Output to `{key}-review.md` in the workspace folder:

```markdown
# Session Review: {key}

**Work item:** {title} ({type})
**Duration:** {start_date} → {end_date} ({total_hours}h active)
**Status:** {final_status}

---

## Timeline

| Time | Skill | Event | Detail |
|------|-------|-------|--------|
| 10:15 | orchestrate | routed | Feature M → build-plan |
| 10:20 | refine | phase completed | functional (12min) |
| ... | ... | ... | ... |

## Metrics

### Time Distribution

| Skill | Time | % of Total |
|-------|------|-----------|
| implement | 2h 15min | 58% |
| refine | 45min | 19% |
| align | 15min | 6% |
| build-plan | 20min | 9% |
| code-review | 15min | 6% |
| verify | 5min | 2% |

**Longest task:** {task ref} — {title} ({duration})
**Bottleneck:** {analysis of why}

### Feedback Summary

- **{N} corrections** during implementation
- **{M} captured as rules** (codified in {destinations})
- **{K} propagated to spec/plan** (spec drift score: {score}/10)
- **Top recurring feedback:** "{pattern}" (appeared {count} times)

### Skill Effectiveness

| Skill | Invocations | Success Rate | Notes |
|-------|-------------|-------------|-------|
| tdd | {N} cycles | {pass_rate}% first-pass | {note} |
| verify | {N} runs | {pass_rate}% first-pass | {note} |
| debug | {N} triggers | — | {what caused debugging} |
| code-review | 1 | {verdict} | {blockers} blockers, {suggestions} suggestions |

### Spec Accuracy Score: {score}/10

- Original criteria: {N}
- Implementation notes added: {M} (drift indicators)
- Missing at code review: {K}
- Assessment: {brief analysis — was the spec good enough?}

---

## Process Improvements

Based on this session, recommend:

1. **{improvement}** — {why, based on metrics}
2. **{improvement}** — {why, based on metrics}
3. **{improvement}** — {why, based on metrics}

## Rules Captured This Session

| Rule | Destination | Source Task |
|------|-------------|------------|
| {rule content} | code-standards.md | Task 1.1 |
| {rule content} | {agent-doc} | Task 2.3 |

---

*Generated by kitt session-review v1.0*
```

### Step 4: Present to User

```
1. Show the review summary (not the full file)
2. Highlight:
   - Top 3 metrics (time, feedback count, spec accuracy)
   - Top process improvement
   - Any recurring feedback patterns worth addressing
3. Ask: "Want to see the full review, or act on any improvement?"
```

### Step 5: Optional Actions

```
If user wants to act:
- "Refine the spec template" → suggest spec.md template improvements based on drift patterns
- "Update code-standards" → suggest new rules based on recurring feedback
- "Improve the plan template" → suggest plan.md template improvements based on what was missed
- "Publish to Notion" → use report adapter to publish review
```

---

## Session Log — How Skills Emit Events

**Every kitt skill should append to session-log.jsonl.** The logging is lightweight — one line per significant event.

### Logging Convention for Skills

At the start of any skill's workflow, resolve the session log path:

```
1. Determine current work item from workspace context
2. Session log path: .claude/workspace/{type}s/{path}/{key}/session-log.jsonl
3. Append events as single-line JSON (one per significant action)
```

### What Counts as a "Significant Event"

- Skill started / completed
- Phase transition (refine phases, implement tasks)
- User feedback / corrections
- Validation results (pass/fail)
- External actions (commits, PR creation, ticket transitions)
- Errors or debug triggers

### What Does NOT Need Logging

- Internal LLM reasoning steps
- File reads (too noisy)
- Intermediate bash commands
- Context loading steps

---

## Integration with Orchestrate

When orchestrate detects epic completion (all US status: completed):

```
orchestrate → session-review (for the epic, aggregating all US logs)
```

Ask user: *"Epic complete. Run a session review to analyze the development process? (y/n)"*

---

## What NOT to Do

- Don't log sensitive data (passwords, tokens, personal info)
- Don't bloat the session log with noise — significant events only
- Don't judge individual performance — analyze process
- Don't fabricate metrics — if session-log.jsonl is missing, say so
- Don't require session logging for skills to function — it's additive, not blocking
