# Default Personas

This directory ships kitt's 6 default personas as Layer 1 in the persona override model defined in [kitt-studio#85](https://github.com/bacleclement/kitt-studio/issues/85):

```
L1 — kitt defaults (~/.claude/kitt/agents/)         ← this directory
L2 — project overrides (<repo>/.claude/agents/{name}/)   ← override an L1 by name
L3 — project additions (<repo>/.claude/agents/{name}/)   ← new persona, no L1 equivalent
```

Name collision → L2/L3 wins (full file override, no partial merge).

## The 6 default personas

| Slug | Voice | Best for |
|---|---|---|
| `cto` | Decisive, trade-off-aware, anti-bike-shedding | Strategic technical decisions, scope cuts, build/buy calls |
| `architect` | Pattern-aware, structural, defends integrity | `/align`, ADRs, layer allocation, bounded contexts |
| `sr-backend` | Code-first, TDD-disciplined, respects standards | `/implement` on backend tasks |
| `sr-frontend` | Component-first, a11y, design-token-aware | `/implement` on frontend tasks |
| `qa-lead` | Skeptical, evidence-driven, coverage auditor | `/code-review`, post-`/implement` verification |
| `sec-chief` | Triage-first, attack-surface-aware, minimum-fix | Security pass during `/code-review` |

## Why these 6 and not more

These cover the lifecycle of a typical SDD work item:

```
brainstorm → product-chief, cto              (not yet shipped — future)
refine     → product-chief, architect        (architect ships now)
align      → architect
plan       → architect, sr-backend/frontend
implement  → sr-backend OR sr-frontend (by scope)
review     → architect + qa-lead + sec-chief
ship       → qa-lead
```

`product-chief` was deferred — it's a hive-style role too business-y for kitt's solo/small-team default. If you need it, drop a project-level override in `<repo>/.claude/agents/product-chief/AGENT.md` (Layer 3).

## Why personas need explicit constraints (the research)

Persona prompting only works when paired with explicit operational constraints:

- **Mission** — what they're for, in one sentence
- **Responsibilities** — numbered list of what they DO
- **Forbidden** — explicit refusals (the highest-impact section)
- **Tools** — allowed and disallowed tool access
- **Style** — communication patterns

A bare `"You are a CTO"` prompt without the Forbidden section produces a sycophant who agrees with whatever the dev wants. The Forbidden section is what makes the persona refuse to write code, refuse to bike-shed, refuse to ship without coverage.

Sources cited in the brainstorm (kitt-studio#85):
- Dennis Kennedy, "Operational Protocol Method", SSRN 2025
- arXiv:2509.23501 on role design impact
- arXiv:2603.18507 (PRISM)

## Editing personas

**Don't edit these defaults.** They're shared across all projects using kitt.

Override per project: drop a file at `<repo>/.claude/agents/{name}/AGENT.md` with the same slug to replace, or a new slug to add a project-specific persona.

Studio (issue #85, future) will surface a UI to edit overrides without leaving the IDE.
