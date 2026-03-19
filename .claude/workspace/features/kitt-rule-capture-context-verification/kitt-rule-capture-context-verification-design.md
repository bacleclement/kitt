# Kitt Rule Capture & Context Verification — Design

## Problem

Corrections made during implementation (bad design, wrong pattern, AI deviation from standards)
are lost after the conversation ends. The next session makes identical mistakes because nothing
was written back to context.

Context files exist (`code-standards.md`, agent docs) but no skill confirms they were actually
applied before writing code — it's assumed, not enforced. `brainstorm` doesn't read agent docs
at all, so design decisions can conflict with domain-specific patterns before a line of code is
written.

## Approach

Three coordinated changes:

1. **New skill: `capture-rule`** — explicit rule capture with flexible destination. Invokable
   manually (`/capture-rule`) or auto-invoked from `implement` when a mid-task correction is
   detected. Interactive: extracts or asks for the rule, classifies the destination, writes it.

2. **Modify `implement`** — add mandatory context confirmation before each task (explicit,
   user-visible summary of relevant constraints). Add a post-correction hook that prompts to
   capture the pattern as a rule.

3. **Fix `brainstorm`** — add agent doc auto-discovery to `Before Starting`, matching the pattern
   already used in `refine`, `align`, `build-plan`, and `implement`.

**Rejected:** passive auto-detection of corrections without user confirmation. Too noisy —
one-off fixes would pollute standards with irrelevant rules.

## Architecture

### `capture-rule` skill

- **Trigger:** `/capture-rule` (manual) or called programmatically from `implement`
- **Auto-invoked context:** when called from `implement`, the correction text is passed as
  argument so the skill can propose the rule directly without re-asking
- **Flow:**
  1. Extract or confirm the rule (propose from correction context if auto-invoked)
  2. Classify destination interactively:
     - Global standard → `.claude/context/code-standards.md`
     - Domain pattern → relevant agent doc (auto-discovered from `**/agents/`)
     - Tech constraint → `.claude/context/tech-stack.md`
  3. Identify the correct section within the destination file
  4. Append rule using `❌/✅` bullet format matching existing style
  5. Confirm write to user with file path + section

### `implement` modifications

**Context confirmation (before each task):**
- After reading context files and agent docs, output an explicit block:
  ```
  Context loaded for this task:
  • code-standards: [2-3 most relevant constraints]
  • {agent-doc}: [1-2 domain-specific rules]
  ```
- This runs before any code is written — visible to the user

**Correction hook (mid-task):**
- When the user issues a correction ("no, do X", "fix this", "that's wrong") during task
  execution, after applying the fix prompt:
  > "This correction looks like a recurring pattern. Capture as a rule? [y/n]"
- If yes: invoke `capture-rule` with the correction as context
- If no: proceed silently

### `brainstorm` fix

Add to `Before Starting` section (after step 2):
```
3. Auto-discover agent docs: glob `**/agents/` and any `AGENTS.md` files in the repo
   — load relevant ones for the domain being discussed
```

## Out of Scope

- Passive/automatic rule capture without user confirmation
- Rule deduplication or conflict detection between files
- Syncing captured rules to Jira or external systems
- Modifying `refine`, `align`, `build-plan` — they already read context and agent docs correctly

## Open Questions

- Should `capture-rule` support updating an existing rule (if a similar rule already exists)
  vs always appending? Recommend: scan for similarity before appending, prompt if a close match
  is found.
- Rule format: free-form or structured? Recommend: match the existing style of the destination
  file — `code-standards.md` uses tables and code blocks, agent docs use prose + examples.
