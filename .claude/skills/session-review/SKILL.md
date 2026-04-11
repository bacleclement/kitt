---
name: "📊 session-review"
description: Post-completion review of a work item's development session — analyzes session log events, skill usage patterns, feedback frequency, spec drift, and time distribution. Outputs a review.md with metrics, actionable improvements classified into 5 typed categories (kitt-skill, context-stale, spec-quality, skill-gap, process-waste), and skill effectiveness evaluation.
version: 2.1
---

# Session Review

**Post-completion analysis of how a work item was built — decisions, feedback, token costs, skill effectiveness, and process improvements.**

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
| *any skill* | `tokens` | input_tokens, output_tokens, model (e.g. "sonnet", "opus") |

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

#### 2.4 Token Usage & Cost

```
- Total tokens: sum input_tokens + output_tokens from all tokens events
- Tokens per skill: group by skill name
- Tokens per task: group by surrounding task_started → task_completed window
- Most expensive task: highest token count
- Cost estimate per skill/task:
    Sonnet: input $3/MTok, output $15/MTok
    Opus:   input $15/MTok, output $75/MTok
    Haiku:  input $0.25/MTok, output $1.25/MTok
  (Use model field from tokens event, default to Sonnet if missing)
```

#### 2.5 Feedback Content Log

```
- Extract ALL feedback events with their content field
- Group by task ref
- For each feedback: show content, action taken, whether propagated to spec/plan
- Detect recurring patterns: feedback with similar content across tasks
  → "Pattern detected: {N} corrections about {theme}" (e.g., "3 corrections about import style")
- Surface the actual user words — not just counts
```

#### 2.6 Agent & Scope Usage

```
If metadata.json.scope is set:
- Active scope: {scope-name}
- Scoped agents loaded: list from kitt.json.scopes.{scope}.agents (resolved globs)
- Repo-wide agents loaded: agents not in any scope
- Agents referenced in context confirmation: which were actually cited?
- Unused agents: loaded but never referenced → candidates for cleanup or re-scoping
- Agent freshness: check last modified date for each loaded agent
  → Flag agents not modified in 30+ days as potentially stale

If no scope:
- All agents loaded (auto-discover mode)
- Track which were referenced vs. ignored
```

#### 2.7 Spec Accuracy

```
- Original acceptance criteria count (from spec)
- Implementation Notes added during implementation (feedback propagation)
- Criteria met vs. missed (from code-review checklist if available)
- Scope creep indicators: tasks added mid-implementation not in original plan
```

#### 2.8 Classify Findings into Actionable Improvements

Beyond metrics and generic process notes, derive **typed, actionable improvements** from the data collected in 2.1–2.7. Each finding must be classified into exactly one of the five categories below, with concrete evidence and a named target (a skill, a file, or a spec).

**Categories and detection heuristics:**

| Category | Target | Detect when |
|---|---|---|
| `kitt-skill` | A specific kitt skill needs a fix or enhancement | • Recurring feedback about the same corrective pattern (≥3 times) points to a skill that should enforce it<br>• `debug` was triggered ≥3 times for similar root causes → the triggering skill (usually `implement` or `tdd`) has a gap<br>• `verify` first-pass failure rate >40% → the skill producing the code skips a check<br>• A tool invocation was repeated because of a known-bad default (e.g. wrong test command) |
| `context-stale` | An `AGENT.md`, `code-standards.md`, or `product.md` file needs a refresh | • An agent doc was loaded but never referenced in context confirmation (flagged in 2.6)<br>• An agent doc was last modified ≥30 days ago AND at least one feedback captured a rule that contradicts it<br>• Feedback content references a pattern not present in the loaded agent docs → doc missing coverage |
| `spec-quality` | The feature/epic spec was too weak — targets the PM/PO, the `refine` skill, or the spec template | • Spec drift score ≥ 5/10 (from 2.2)<br>• ≥50% of feedback events were about missing acceptance criteria or edge cases<br>• Scope creep indicators from 2.7 show ≥3 tasks added mid-implementation<br>• `align` produced warnings that point to architectural decisions the spec never addressed |
| `skill-gap` | A capability is missing — no existing skill covers it, a manual step was taken every time | • A manual step appears in the timeline (user-performed action without a skill event) ≥2 times for similar purposes<br>• A feedback event says "I had to do X by hand" or equivalent<br>• `debug` was used where a dedicated diagnostic skill would have fit (e.g. perf analysis, migration verification) |
| `process-waste` | An existing step in the workflow was unnecessary — consider auto-skipping or simplifying | • `align` passed all dimensions with zero warnings on a feature of size M or smaller → candidate for auto-skip<br>• A phase completed in <5% of the total session time with no corrections → low-value checkpoint<br>• `code-review` produced 0 blockers and 0 suggestions → the review was redundant given the prior skills<br>• Same skill was re-invoked with no feedback between runs → unnecessary iteration |

**Rules for each finding:**

1. **One category per finding.** If evidence fits two categories, pick the one whose target action is most actionable (skill update > doc refresh > spec coaching > new skill > process cut).
2. **Quantified evidence is mandatory.** Never write "the spec was weak" — always "5 of 8 feedback events concerned missing edge cases (62%)".
3. **Name the target explicitly.** For `kitt-skill`, name the skill (`implement`, `refine`, `tdd`, etc.). For `context-stale`, name the file path. For `spec-quality`, name the ticket key. For `skill-gap`, describe the missing capability. For `process-waste`, name the step being cut.
4. **No finding without a proposed action.** Each item in the output must be a checkbox that the reader can either do or mark as wontfix — not an observation.
5. **Cap at 10 findings total.** If more emerge, keep the highest-signal ones (most evidence, most recent occurrences, most actionable). Noise degrades the whole section.
6. **Zero findings is a valid output.** If the session was clean, write "No actionable improvements detected — session was within expected thresholds." Do not fabricate findings.

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

### Token Usage & Cost

| Skill | Input Tokens | Output Tokens | Est. Cost |
|-------|-------------|---------------|-----------|
| implement | 125,000 | 32,000 | $0.52 |
| refine | 45,000 | 12,000 | $0.18 |
| ... | ... | ... | ... |
| **Total** | **210,000** | **58,000** | **$0.85** |

**Most expensive task:** {task ref} — {title} ({token_count} tokens, ${cost})
**Cost per task (avg):** ${avg_cost}

### Feedback Log

| Task | Feedback | Action | Propagated? |
|------|----------|--------|-------------|
| 1.1 | "Use React Query not fetch" | captured_rule | spec, plan |
| 2.3 | "Missing error boundary" | applied | spec |
| ... | ... | ... | ... |

**Recurring patterns:**
- "{theme}" — appeared {N} times across tasks {refs}

### Agent & Scope Usage

**Scope:** {scope-name} (or "repo-wide" if no scope)

| Agent | Scoped? | Referenced? | Last Modified | Status |
|-------|---------|-------------|---------------|--------|
| network-code-agent.md | Yes (api-network) | 6/8 tasks | 2 days ago | ✅ Active |
| network-migration.md | Yes (api-network) | 0/8 tasks | 45 days ago | ⚠️ Stale & unused |
| integration-test-agent.md | Repo-wide | 2/8 tasks | 12 days ago | ✅ Active |

**Recommendation:** {e.g., "network-migration.md was loaded but never referenced and is 45 days stale. Consider refreshing or removing from scope."}

### Spec Accuracy Score: {score}/10

- Original criteria: {N}
- Implementation notes added: {M} (drift indicators)
- Missing at code review: {K}
- Assessment: {brief analysis — was the spec good enough?}

---

## Actionable Improvements

Each finding below is classified into one of five categories, with quantified evidence and a named target. Checkboxes are actionable — check them off as you address each item, or convert them into kitt tickets directly.

### kitt-skill ({N} items)

- [ ] **{skill-name}**: {proposed fix/enhancement}. Evidence: {metric/count that triggered this finding}
- [ ] **{skill-name}**: {proposed fix/enhancement}. Evidence: {metric/count}

### context-stale ({N} items)

- [ ] **{agent-or-context-file-path}**: {what needs refresh}. Last modified: {date}. Evidence: {loaded-but-unreferenced, contradicted-by-feedback, etc.}

### spec-quality ({N} items)

- [ ] **{ticket-key} spec**: {what was weak}. Evidence: {feedback counts, drift score, scope creep indicators}

### skill-gap ({N} items)

- [ ] **Missing: {capability}**. Evidence: {how many times the user did it manually, which tasks}

### process-waste ({N} items)

- [ ] **{step-or-skill-to-cut}**: {why it was unnecessary}. Evidence: {pass rate, duration, corrections count}

---

**If no actionable improvements detected:**
> No actionable improvements detected — session was within expected thresholds. Spec drift {score}/10, feedback count {N}, verify first-pass {rate}%, all below action triggers.

---

## Process Improvements

Softer recommendations that did not meet the classification thresholds above but are worth considering:

1. **{improvement}** — {why, based on metrics}
2. **{improvement}** — {why, based on metrics}
3. **{improvement}** — {why, based on metrics}

## Rules Captured This Session

| Rule | Destination | Source Task |
|------|-------------|------------|
| {rule content} | code-standards.md | Task 1.1 |
| {rule content} | {agent-doc} | Task 2.3 |

---

*Generated by kitt session-review v2.1*
```

### Step 4: Present to User

```
1. Show the review summary (not the full file)
2. Highlight in this order:
   a. Actionable Improvements count per category (e.g. "3 kitt-skill, 1 context-stale, 2 spec-quality")
   b. The top 3 highest-evidence actionable findings, with target + one-line rationale
   c. Top 3 metrics (total time, feedback count, spec accuracy score)
   d. Any recurring feedback patterns worth addressing
3. Ask: "Want to see the full review, act on an actionable finding, or mark findings as wontfix?"
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
