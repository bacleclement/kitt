---
name: "📏 capture-rule"
description: "Captures a coding correction or design fix as a permanent rule in the right context file. Invokable manually (/capture-rule) or auto-invoked from implement after a mid-task correction. Four user-facing destinations: feature-level spec, app-scope agent doc, repo-wide code-standards.md, or domain-wide product.md. Plus a programmatic skill-diff mode used exclusively by /revise for post-completion kitt-skill updates."
version: 3.1
---

# Capture Rule

**Turns a correction or fix into a permanent rule written to the right context file. Scope-aware: pre-selects app-level destination in monorepos.**

## When to Use

- Manually: after any correction during a conversation that should not be repeated
- Auto-invoked: from `implement` after the user corrects AI behavior mid-task

---

## Process

### Step 1: Extract the rule

**If auto-invoked with context (correction text provided):**
Propose a concise rule derived from the correction. Show it to the user:

> "Proposed rule: {derived rule}. Correct this?"

Let the user refine it before proceeding.

**If invoked manually with no context:**
Ask: "What's the rule? Describe the correction or pattern to avoid."

Keep it actionable. Rules should state what to do (✅) or not do (❌), not why it happened.

---

### Step 2: Classify the destination

Read `metadata.json.scope` for the current work item and `kitt.json.scopes` (if present). Four destinations total — no more, no less.

**If scopes exist and a scope is active** — show scope-aware options:

```
Where does this rule belong?

  A) This feature only   → workspace/{key}/spec ## Implementation Notes
     (applies to this work item only — already handled by feedback propagation)

  B) Scoped agent        → agent doc for {scope} (from kitt.json.scopes.{scope}.agents)  ← PRE-SELECTED DEFAULT
     (tech patterns + domain rules specific to this app/service)

  C) Repo-wide standard  → .claude/context/code-standards.md
     (tech baseline, naming, imports, architecture, testing, approved libraries — applies everywhere)

  D) Domain / product    → .claude/context/product.md
     (business rules, domain vocabulary, user-facing behavior — non-tech)
```

Default = **B (scoped agent)** when a scope is active. The agent is the single source of per-scope tech + domain context.

**If scoped agent selected:** list agents matched to the active scope from `kitt.json.scopes.{scope}.agents`, let user pick which file to append to (or infer from correction context).

**If no scopes or no active scope** — show flat options:

```
Where does this rule belong?

  A) This feature only  → workspace/{key}/spec ## Implementation Notes
     (applies to this work item only)

  B) Repo-wide standard → .claude/context/code-standards.md
     (tech baseline, naming, imports, architecture, testing — applies everywhere)

  C) Domain / product   → .claude/context/product.md
     (business rules, domain vocabulary, user-facing behavior)

  D) Domain agent       → a specific agent doc (e.g. code-agent.md)
     (patterns specific to one module, service, or bounded context)
```

**If domain agent / scoped agent:** discover agents using scoped context loading rules (scoped agents for active scope + repo-wide agents). List them for user selection, or infer from the correction context.

### Routing heuristics — tech vs domain

If the user hesitates on B vs C vs D:

- **Tech / code patterns** (how we write code, which libraries, which patterns) → `code-standards.md`
- **Business / domain rules** (how the product behaves, who does what, naming of domain concepts) → `product.md`
- **App-specific patterns** (architecture, conventions, or rules that apply only to one service/module) → scope agent doc

**Four destinations only.** Do not invent or propose alternatives. If an older project contains orphan context files under `.claude/context/` that are not `product.md` or `code-standards.md`, ignore them — merge any relevant content into `code-standards.md` opportunistically when a related rule is captured.

---

### Step 3: Find the right section

Read the destination file. Identify the most relevant existing section.

- `code-standards.md`: match to Tech Baseline, Naming, Imports, Architecture, Testing, Formatting, etc.
- `product.md`: match to Users, Core Domains, Business Rules, Vocabulary
- Agent docs: match to the section covering the affected layer or pattern
- Feature spec: always append under `## Implementation Notes`

If no section fits, propose creating one.

**Before appending:** scan for a similar existing rule. If a close match is found:

> "A similar rule already exists: '{existing rule}'. Update it instead of adding a duplicate? [y/n]"

---

### Step 4: Write the rule

Format to match the destination file's existing style.

**For `code-standards.md` (table or bullet style):**
```markdown
❌ {what not to do — concrete example}
✅ {what to do instead — concrete example}
```

**For `product.md` (prose + optional list):**
```markdown
- **{Domain concept}:** {rule in one sentence, no code}
```
Business rules are appended under `## Business Rules`. Vocabulary entries go under `## Vocabulary`. Never put code examples in `product.md`.

**For agent docs (prose + example style):**
```markdown
**Rule: {short title}**
{one sentence explanation}
❌ Bad: `{code or pattern to avoid}`
✅ Good: `{correct pattern}`
```

**For feature spec (`workspace/{key}/{key}-spec.md`):**
```markdown
- {one-liner rule, applies only to this feature}
```
Always appended under `## Implementation Notes`.

Write the rule. Confirm the write:

> "Rule written to {file path}, section '{section name}'."

---

---

## Skill-diff mode (invoked only by `revise`, not user-facing)

When `revise` classifies a post-completion defect as category 6 (`bad-kitt-skill-logic`), the target is a `SKILL.md` file in `~/.claude/kitt/.claude/skills/{skill-name}/`. This is the **only** path that mutates a skill file, and it bypasses the 4 canonical destinations because the write is fundamentally different: it is an edit anywhere in the file (not an append), and the user reviews an actual diff (not a prose description).

**This mode is NEVER offered when `/capture-rule` is invoked directly by the user.** It is a programmatic entry point used only by `/revise` during Step 6 of its flow.

### Invocation signature

```
capture-rule --mode=skill-diff \
             --target={skill-name} \
             --revision-context={path-to-revision-folder}
```

- `--mode=skill-diff` — flag that distinguishes this from the user-facing flow
- `--target` — the name of the skill to edit (e.g. `implement`, `tdd`, `refine`, `align`, `verify`)
- `--revision-context` — path to the `revisions/{timestamp}-{slug}/` folder containing `context.md` and `classification.md`, used as grounding for the proposed diff

### Flow

**Step A — Resolve the target file**

Look up `~/.claude/kitt/.claude/skills/{target}/SKILL.md`. If missing, abort with an explicit error and log the failure in the revision's classification.md under "Follow-up actions".

**Step B — Read the current skill**

Read the full `SKILL.md` file. Identify which section(s) are most likely responsible for the classified defect, using the revision context's reasoning.

**Step C — Propose a unified diff**

Generate a **unified diff** (not a prose description) of the proposed change. The diff must:

- Target specific sections, not the whole file
- Preserve frontmatter except when bumping the version (see Step E)
- Add, modify, or remove lines surgically — never rewrite large blocks unless the whole section is being replaced
- Include enough context lines (3 before, 3 after) for the user to understand the change in place

Format exactly like `git diff`:

```diff
--- a/.claude/skills/{target}/SKILL.md
+++ b/.claude/skills/{target}/SKILL.md
@@ -{old-start},{old-count} +{new-start},{new-count} @@
 {context line}
 {context line}
-{removed line}
+{added line}
 {context line}
 {context line}
```

**Step D — Show the diff to the user**

Render the diff as a code block in the chat. Do NOT paraphrase it. Accompany it with:

```
"Proposed update to {target}/SKILL.md:

 Why: {one-paragraph rationale tied to the revision classification}

 Accept this diff? (y/n/edit)
   - y → apply the diff to the file
   - n → reject, log the rejection in the revision's classification.md
   - edit → let me refine the diff before applying"
```

**Step E — Apply the diff (only on y)**

If the user accepts:

1. Apply the diff to the target `SKILL.md` file
2. Bump the version in the frontmatter: if current is `X.Y`, write `X.Y+1` (minor bump). If the change is substantial (adds a new step, changes the hard-gate semantics), bump to `X+1.0` (major). Default: minor.
3. Confirm the write:
   > "Applied. {target}/SKILL.md updated. Version bumped to {new-version}."
4. Append to the revision's `classification.md` under `## Lessons approved`:
   ```markdown
   - `{target}` skill updated — version {old} → {new}, diff applied from revision {slug}
   ```
5. Log a session event in the workspace session log:
   ```jsonl
   {"ts":"{ISO}","skill":"capture-rule","event":"skill_updated","data":{"target":"{target}","mode":"skill-diff","revision":"{slug}","version_before":"{old}","version_after":"{new}"}}
   ```

**Step F — Reject or edit**

- **n (reject):** do not apply, append to `classification.md` under `## Lessons rejected`:
  ```markdown
  - `{target}` skill diff rejected — {user-provided reason or "no reason given"}
  ```
- **edit:** show the diff again and let the user refine it line by line. Re-confirm before applying.

### Guardrails

1. **No silent writes.** The user MUST see and approve the diff. Never apply without explicit confirmation.
2. **No whole-file rewrites.** If the proposed change touches more than 50% of the skill file, reject the proposal yourself and ask the user to split the change into smaller revisions.
3. **No frontmatter rewriting except version bump.** The `name` and `description` fields stay unless the user explicitly asks to change them — which they can only do via `edit` mode, not the default flow.
4. **No writes outside `~/.claude/kitt/.claude/skills/**`.** This mode is strictly scoped to skill files. Any attempt to target a different path aborts.
5. **Version bump is mandatory.** A skill file cannot be edited without bumping its version. This keeps change traceable in git history.

---

## What capture-rule does NOT do

- Does not rewrite or restructure existing rules
- Does not capture one-off environment issues (only repeatable patterns)
- Does not sync to Jira or external systems
- Does not validate whether the rule contradicts existing ones (flags obvious duplicates only)
- Does not offer skill-diff mode to direct user invocations — only via `/revise` Step 6
- Does not touch any file outside `.claude/context/`, `.claude/workspace/`, agent docs, or (in skill-diff mode) `~/.claude/kitt/.claude/skills/*/SKILL.md`
