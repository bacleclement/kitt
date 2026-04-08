---
name: capture-rule
description: "Captures a coding correction or design fix as a permanent rule in the right context file. Invokable manually (/capture-rule) or auto-invoked from implement after a mid-task correction. Flexible destination: code-standards, domain agent, or tech-stack."
version: 2.0
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

Read `metadata.json.scope` for the current work item and `kitt.json.scopes` (if present).

**If scopes exist and a scope is active** — show scope-aware options:

```
Where does this rule belong?

  A) This feature only → workspace/{key}/spec ## Implementation Notes
     (applies to this work item only — already handled by feedback propagation)

  B) App standards     → .claude/context/apps/{scope}/standards.md      ← PRE-SELECTED DEFAULT
     (patterns specific to {scope} — only loaded when working on this app)

  C) Scoped agent      → agent doc matched to {scope} (from kitt.json.scopes.{scope}.agents)
     (domain-specific patterns for this service/module)

  D) Repo-wide standard → .claude/context/code-standards.md
     (naming, imports, architecture, formatting — applies everywhere)

  E) Tech constraint    → .claude/context/tech-stack.md
     (library-specific patterns, approved/banned packages, runtime constraints)

  F) Company-wide       → ~/.claude/context/company-standards.md
     (rules shared across all repos — naming, security, compliance)
```

Default = **B (app standards)** when a scope is active. This is the most common destination in monorepos.

**If no scopes or no active scope** — show flat options (current behavior):

```
Where does this rule belong?

  A) Global standard  → .claude/context/code-standards.md
     (naming, imports, architecture, formatting — applies everywhere)

  B) Domain agent     → relevant agent doc (e.g. code-agent.md)
     (patterns specific to one module, service, or bounded context)

  C) Tech constraint  → .claude/context/tech-stack.md
     (library-specific patterns, approved/banned packages, runtime constraints)
```

**If domain agent / scoped agent:** discover agents using scoped context loading rules (scoped agents for active scope + repo-wide agents). List them for user selection, or infer from the correction context.

---

### Step 3: Find the right section

Read the destination file. Identify the most relevant existing section.

- `code-standards.md`: match to Naming, Imports, Architecture, Testing, etc.
- Agent docs: match to the section covering the affected layer or pattern
- `tech-stack.md`: match to the relevant library or runtime section

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

**For agent docs (prose + example style):**
```markdown
**Rule: {short title}**
{one sentence explanation}
❌ Bad: `{code or pattern to avoid}`
✅ Good: `{correct pattern}`
```

**For `tech-stack.md`:**
```markdown
- **{Library/constraint}:** {rule in one sentence}
```

Write the rule. Confirm the write:

> "Rule written to {file path}, section '{section name}'."

---

## What capture-rule does NOT do

- Does not rewrite or restructure existing rules
- Does not capture one-off environment issues (only repeatable patterns)
- Does not sync to Jira or external systems
- Does not validate whether the rule contradicts existing ones (flags obvious duplicates only)
