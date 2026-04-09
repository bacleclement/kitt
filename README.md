# Kitt — AI Workflow Engine for Claude Code

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Spec-driven development pipeline with pluggable task managers, VCS, and design tools. One entry point: `/orchestrate`.

## Quick Start

```bash
# Install (once per machine)
git clone https://github.com/bacleclement/kitt.git ~/.claude/kitt

# In your project
/setup        # config wizard — scans repo, writes kitt.json + context files
/orchestrate  # start working
```

New team member? Same commands — `/setup` detects existing config and switches to join mode.

Update: `git -C ~/.claude/kitt pull`

---

## How It Works

`/orchestrate` detects what you're working on and routes to the right skill:

```
/orchestrate
 ├─ Epic       → /refine → /align → /build-plan → /implement → /code-review → /finish-development
 ├─ Feature L  → /refine → /align → /build-plan → /implement → /code-review → /finish-development
 ├─ Feature M  → /build-plan → /implement → /code-review → /finish-development
 ├─ Feature S  → /implement → /code-review → /finish-development
 ├─ Bug        → /debug or /implement → /code-review → /finish-development
 └─ QA         → /qa-frontend or /qa-backend → publish
```

Before routing: asks branch vs. worktree, detects scope (multi-app), reads ticket from task manager.
After completion: `/session-review` for analytics (tokens, feedback, skill effectiveness).

---

## Skills (21)

| Phase | Skills |
|-------|--------|
| **Entry** | `setup` · `onboard` · `orchestrate` |
| **Design** | `brainstorm` · `refine` · `align` · `build-plan` |
| **Build** | `implement` · `tdd` · `verify` · `debug` |
| **Ship** | `code-review` · `finish-development` · `branch-creator` · `pr-creator` · `vcs/worktree` |
| **Quality** | `qa-frontend` · `qa-backend` · `capture-rule` · `session-review` |
| **Ops** | `manage-task` |

---

## Context Architecture

Two dimensions: **domain** (what we build) and **tech** (how we build it).

```
.claude/
├── CLAUDE.md                       # Entry point, hard rules
├── context/
│   ├── product.md                  # Domain: business rules, users, vocabulary
│   └── code-standards.md           # Shared tech: baseline stack, naming, formatting
└── config/kitt.json                # scopes, task manager, VCS, build commands

# Agents live colocated in the codebase — kitt.json maps them:
apps/api/services/network/AGENT.md  # NestJS + hexagonal + DDD + network domain
apps/front/admin/AGENT.md           # React + MUI + admin patterns
```

- `product.md` → always loaded (domain doesn't change per app)
- `code-standards.md` → always loaded (shared conventions + tech baseline)
- Agents → per-scope deep expertise (tech + domain), loaded via `kitt.json.scopes`

### Monorepo Scoping

```json
{
  "scopes": {
    "*": { "agents": ["docs/testing/integration-patterns.md"] },
    "api-network": {
      "path": "apps/api/services/network",
      "agents": ["apps/api/services/network/AGENT.md"]
    }
  }
}
```

`"*"` = always loaded. Named scopes = loaded when active. No scopes = auto-discover `**/agents/`.

---

## Key Features

### Feedback Propagation
Corrections mid-implementation → captured as rules (`/capture-rule`) + appended to spec + noted in plan. Specs stay in sync with decisions.

### Code Review
`/code-review` runs before every PR. 5 dimensions: spec compliance, architecture, standards, agent docs, quality. Outputs verdict: PASS / BLOCKED.

### Session Analytics
`/session-review` after completion: time per skill, token costs, feedback log, spec accuracy score, agent freshness detection.

### Implementation Modes
Sequential (default, one task at a time) or subagent (parallel within phases, checkpoint between).

---

## Adapters

| Type | Supported |
|------|-----------|
| **Task Manager** | Jira · Linear · GitHub Issues · Local |
| **VCS** | GitHub · GitLab · Bitbucket |
| **Design** | Figma (MCP or REST API) |
| **Report** | Local · Notion |

---

## kitt.json

Single source of truth. Every skill reads it — nothing hardcoded.

```json
{
  "project": { "name": "my-project" },
  "scopes": { ... },
  "taskManager": { "type": "jira", "config": { ... } },
  "vcs": { "type": "github", "config": { ... } },
  "build": { "test": "...", "typecheck": "...", "lint": "...", "build": "..." },
  "commitFormat": { "pattern": "{type}({ticket}): {description}" }
}
```

Full schema: `~/.claude/kitt/.claude/templates/kitt.json.schema`
