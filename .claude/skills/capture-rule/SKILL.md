---
name: "📏 capture-rule"
description: "Captures a coding correction or design fix as a permanent rule in the right context file. Invokable manually (/capture-rule) or auto-invoked from implement after a mid-task correction. Four destinations: feature-level spec, app-scope agent doc, repo-wide code-standards.md, or domain-wide product.md."
version: 3.0
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

**Deprecated destinations (do not propose):** `~/.claude/context/company-standards.md` and `.claude/context/tech-stack.md` are legacy files. If a project still has them, they are read by skills for backward compatibility but new rules MUST go to one of the four destinations above. Merge content from legacy files into `code-standards.md` opportunistically when a related rule is captured.

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

## What capture-rule does NOT do

- Does not rewrite or restructure existing rules
- Does not capture one-off environment issues (only repeatable patterns)
- Does not sync to Jira or external systems
- Does not validate whether the rule contradicts existing ones (flags obvious duplicates only)
