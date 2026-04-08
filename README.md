# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## What Kitt Gives You

- **Full workflow pipeline:** brainstorm → refine → align → build-plan → implement → code-review → finish
- **App-scoped context:** monorepo support — load only relevant agents and standards per app/service
- **Automated code review:** diff-against-spec review with 5 quality dimensions before every PR
- **Session analytics:** token costs, feedback tracking, skill effectiveness, spec drift scoring
- **Systematic debugging:** reproduce → locate → root cause → fix → regress
- **Frontend & backend QA:** browser scenarios + HTTP scenarios, live run file, multi-stakeholder review columns
- **Developer onboarding:** role-aware guide generated from your actual codebase
- **Pluggable adapters:** Jira, Linear, GitHub Issues, Local / GitHub, GitLab, Bitbucket / report to Local or Notion
- **Smart setup wizard:** scans your repo, detects apps, asks one question at a time with lettered options
- **Zero hardcoding:** all platform config lives in `kitt.json`

---

## Skills

| Skill | Purpose |
|-------|---------|
| `setup` | First-time config wizard — or join mode for new team members. Detects monorepo apps for scoped context. |
| `onboard` | Personalized onboarding guide (role interview → scoped codebase tour) |
| `brainstorm` | Explore raw ideas → design.md before any spec or ticket |
| `orchestrate` | Routes work to the right next step based on current state. Detects scope per work item in multi-app projects. |
| `refine` | Constraint discovery: functional, access, NFRs. Epic mode generates spec with US breakdown |
| `align` | Validates spec against DDD / Clean Architecture |
| `build-plan` | Breaks spec into implementable TDD tasks |
| `implement` | Implements tasks with TDD — sequential or subagent mode. Session logging for analytics. |
| `tdd` | Red-Green-Refactor cycle — called by implement on every task |
| `verify` | Evidence before completion claims — no exceptions |
| `code-review` | Automated 5-dimension review (spec compliance, architecture, standards, agents, quality). Runs before finish-development. |
| `debug` | Systematic bug investigation: reproduce → root cause → fix → regress |
| `capture-rule` | Turns corrections into permanent rules. Scope-aware: feature → app → repo → company destinations. |
| `session-review` | Post-completion analytics: time distribution, token costs, feedback log, skill effectiveness, agent freshness. |
| `qa-frontend` | Browser-based QA: scenario generation from spec/Jira, live `qa-run.md` with AI/Dev/PM/Design columns, publishes to Local or Notion |
| `qa-backend` | HTTP scenario runner: API credentials, request/response assertions, live run file, same report adapter |
| `manage-task` | Ticket CRUD (read, create, transition, comment) |
| `branch-creator` | Git branch from ticket key |
| `pr-creator` | PR creation with task manager linking |
| `vcs/worktree` | Creates isolated git worktree outside the repo — called by orchestrate when user wants isolation |
| `finish-development` | End-of-work sequence: verify → push → PR → ticket transition → worktree cleanup |
| `vcs/worktree-finish` | Removes a worktree properly after PR is merged — called by finish-development |

---

## Workflow

All work starts with `/orchestrate`. It detects the current state and routes to the right skill.

### Use Case 1 — Raw idea (no ticket, no spec)

```
raw idea
  └─ /orchestrate
       ├─ branch or worktree? → choose work environment
       ├─ needs exploration? → /brainstorm → design.md → /orchestrate
       └─ scope clear?
            ├─ Epic  → /refine (EPIC MODE) → spec + ## User Stories
            │            └─ for each US: /align → /build-plan → /implement → /code-review → /finish-development
            ├─ Feature M  → /build-plan → /implement → /code-review → /finish-development
            └─ Feature S  → /implement → /code-review → /finish-development
```

### Use Case 2 — PM creates a ticket (epic with or without US)

```
ticket key
  └─ /orchestrate (reads ticket via adapter)
       ├─ branch or worktree? → choose work environment
       ├─ multi-app? → detect scope (from ticket or ask) → store in metadata.json
       ├─ US belongs to existing epic? → nest under epic folder, update children
       ├─ Epic, no US yet  → /refine (EPIC MODE) → extract US subfolders
       └─ Epic, US in TM   → import US from task manager
            └─ for each US: /align → /build-plan → /implement → /code-review → /finish-development
```

### Use Case 3 — Known feature or refactor

```
known scope
  └─ /orchestrate (ask size)
       ├─ branch or worktree? → choose work environment
       ├─ S (1-3 files, obvious)  → /implement → /code-review → /finish-development
       ├─ M (clear, < 2 days)     → /build-plan → /implement → /code-review → /finish-development
       └─ L (unclear or risky)    → /refine → /align → /build-plan → /implement → /code-review → /finish-development
```

### Use Case 4 — Bug

```
bug reported
  └─ /orchestrate
       ├─ branch or worktree? → choose work environment
       ├─ root cause unknown  → /debug → /finish-development
       ├─ quick fix           → /implement → /code-review → /finish-development
       └─ complex fix         → /build-plan → /implement → /code-review → /finish-development
```

### Use Case 5 — QA

```
feature ready for QA
  └─ /orchestrate
       ├─ frontend feature  → /qa-frontend → qa-run.md → publish (Local or Notion)
       └─ backend feature   → /qa-backend  → qa-run.md → publish (Local or Notion)
```

### Use Case 6 — Post-Completion Review

```
epic or feature completed
  └─ /orchestrate detects completion
       └─ /session-review → review.md (metrics, feedback log, token costs, improvements)
```

---

### Workspace Structure

Workspaces use **human-readable folder names**: `{ticketKey}-{slug}` (e.g., `PROJ-42-user-profile`) or just `{slug}` for work without tickets.

```
.claude/workspace/epics/PROJ-42-company-management/
├── metadata.json              # status, scope, children list
├── company-management-design.md
├── company-management-spec.md # from refine — contains ## User Stories
├── session-log.jsonl          # session events for analytics
├── PROJ-43-company-creation/
│   ├── company-creation-spec.md
│   └── company-creation-plan.md
└── PROJ-44-contact-management/
    ├── contact-management-spec.md
    └── contact-management-plan.md
```

---

## App-Scoped Context (Monorepo Support)

For monorepos with multiple apps (frontend, backend, E2E), kitt loads **only relevant agents and standards** per work item.

### How It Works

1. **Setup** detects apps (Nx, pnpm workspaces, Turbo) and auto-matches agents to scopes
2. **Orchestrate** detects or asks which app a work item touches, stores scope in `metadata.json`
3. **All skills** load only: repo-wide context + app-scoped context + scoped agents

### Configuration in kitt.json

```json
{
  "scopes": {
    "api-network": {
      "path": "apps/api/services/network",
      "agents": [".claude/agents/network-*.md", "apps/api/services/network/agents/**"]
    },
    "front-admin": {
      "path": "apps/front/admin",
      "agents": [".claude/agents/admin-*.md"]
    }
  }
}
```

No `scopes` section = no scoping (single-app projects, backward compatible).

### Context Loading Order

```
1. Repo-wide:    .claude/context/product.md, tech-stack.md, code-standards.md
2. App-scoped:   .claude/context/apps/{scope}/standards.md (if exists)
3. Scoped agents: globs from kitt.json.scopes.{scope}.agents
4. Repo-wide agents: agents not listed in any scope
5. Feature-scoped: workspace/{key}/spec ## Implementation Notes
```

---

## Code Review

`/code-review` runs automatically before `/finish-development`. Reviews the diff against **5 dimensions:**

1. **Spec compliance** — all acceptance criteria met?
2. **Architecture alignment** — layer boundaries, DDD rules, patterns
3. **Code standards** — naming, imports, formatting from `code-standards.md`
4. **Agent doc compliance** — domain-specific rules from loaded agents
5. **Quality & maintainability** — dead code, error handling, test coverage, performance, security

Output: structured review with blockers (must fix), suggestions, spec compliance checklist, and verdict (PASS / PASS WITH SUGGESTIONS / BLOCKED).

---

## Session Review & Analytics

`/session-review` runs after epic or feature completion. Analyzes the development session:

- **Time distribution** per skill and per task
- **Token usage & cost** (per skill, per task, with model-based pricing)
- **Feedback log** with full user correction content and recurring pattern detection
- **Skill effectiveness** (verify pass rate, debug triggers, TDD cycles)
- **Spec accuracy score** (how many corrections = how good was the spec?)
- **Agent usage per scope** with freshness detection (flags 30+ day stale agents)

Skills emit lightweight events to `session-log.jsonl` during execution. Session-review aggregates them into `{key}-review.md`.

---

## Feedback Propagation

When you correct kitt mid-implementation ("no, use X pattern instead"):

1. Fix is applied immediately
2. Rule is optionally captured via `/capture-rule` (scope-aware: feature → app → repo → company)
3. Constraint is appended to `spec.md` under `## Implementation Notes`
4. Inline note added to `plan.md` on the affected task: `> ⚠️ Updated: {what changed}`
5. Event logged to `session-log.jsonl` for session-review analytics

Specs and plans stay synchronized with implementation decisions.

---

## Implementation Modes

When `/implement` starts, it asks which execution mode you want:

```
A) Subagent — parallel tasks within each phase, checkpoint between phases
B) Sequential — one task at a time, full visibility
```

**Sequential (B):** Default. Kitt implements each task in order — TDD cycle, validation, commit, then asks for your review before moving to the next.

**Subagent (A):** Kitt dispatches parallel subagents for tasks within the same phase. Between phases, it shows a summary + diff and waits for go/stop.

---

## Project Configuration (`kitt.json`)

`.claude/config/kitt.json` is the single source of truth. Every skill reads it — nothing is hardcoded.

```json
{
  "project": {
    "name": "my-project",
    "description": "What this project does"
  },
  "scopes": {
    "api-network": {
      "path": "apps/api/services/network",
      "agents": [".claude/agents/network-*.md"]
    }
  },
  "taskManager": {
    "type": "jira",
    "config": {
      "instanceUrl": "https://my-team.atlassian.net",
      "projectKey": "PROJ",
      "statuses": {
        "todo":       "To Do",
        "inProgress": "In Progress",
        "review":     "In Review",
        "done":       "Done",
        "blocked":    "Blocked"
      }
    }
  },
  "vcs": {
    "type": "github",
    "config": {
      "account":    "my-github-username",
      "org":        "my-org",
      "repo":       "my-repo",
      "baseBranch": "main"
    },
    "worktrees": {
      "path": "~/worktrees/{{project.name}}",
      "setup": ["pnpm install"]
    }
  },
  "build": {
    "test":      "pnpm nx run {project}:test --testPathPattern={pattern}",
    "typecheck": "pnpm nx run {project}:typecheck",
    "lint":      "pnpm nx run {project}:lint",
    "build":     "pnpm nx run {project}:build"
  },
  "design": {
    "type": "figma",
    "config": { "defaultFileKey": "abc123XYZ" }
  },
  "commitFormat": {
    "pattern":    "{type}({ticket}): {description}",
    "types":      ["feat", "fix", "refactor", "test", "docs", "chore"],
    "coAuthored": false
  }
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `project.name` | Yes | Project name |
| `scopes` | — | App-scoped context for monorepos (omit for single-app projects) |
| `scopes.{name}.path` | — | Relative path to app folder |
| `scopes.{name}.agents` | — | Glob patterns for scoped agent docs |
| `taskManager.type` | Yes | `jira` · `linear` · `github-issues` · `local` · `none` |
| `taskManager.config.statuses` | Yes | Status names as they appear in your task manager |
| `vcs.type` | Yes | `github` · `gitlab` · `bitbucket` |
| `vcs.config.account` | Yes | Username for PR creation |
| `vcs.config.baseBranch` | Yes | Default: `main` |
| `build.*` | Yes | Use `{project}` and `{pattern}` as placeholders |
| `design.type` | — | `figma` · `none`. Requires MCP server or `FIGMA_TOKEN` env var. |
| `commitFormat.pattern` | Yes | Use `{type}`, `{ticket}`, `{description}` |
| `commitFormat.coAuthored` | — | Add `Co-Authored-By` to commit body. Default: `false` |
| `vcs.worktrees.path` | — | Base path for worktrees. Default: `~/worktrees/{{project.name}}` |

---

## Adopting Kitt (First Person on a Project)

### Step 1: Install kitt on your machine (once)

```bash
git clone https://github.com/bacleclement/kitt.git ~/.claude/kitt
```

### Step 2: Configure your project

Open Claude Code in your project root and run:

```
/setup
```

Kitt scans your repo and walks you through configuration one question at a time. For monorepos, it detects apps and configures scoped context. It writes:
- `.claude/config/kitt.json` — task manager, VCS, build commands, scopes
- `.claude/context/` — product knowledge, tech stack, code standards

**Commit these files.** They're the shared foundation every skill reads.

### Step 3: Work

```
/orchestrate
```

---

## New Team Member? (Project Already Configured)

### Step 1: Install kitt on your machine (once)

```bash
git clone https://github.com/bacleclement/kitt.git ~/.claude/kitt
```

### Step 2: Open Claude Code and run

```
/setup
```

Kitt detects the existing config and switches to **join mode** — no wizard, no re-configuration. It recreates your local symlinks and hands off to `/onboard` for your personalized guide.

---

## Updating Kitt

```bash
git -C ~/.claude/kitt pull
```

Symlinks pick up the new version instantly. Nothing to commit in your project.

---

## Kitt Structure

```
~/.claude/kitt/              # installed globally, never in your project repo
├── bin/install.sh           # curl-able installer
├── version
└── .claude/
    ├── skills/              # 21 workflow skills
    │   ├── setup/
    │   ├── onboard/
    │   ├── brainstorm/
    │   ├── orchestrate/     # v9 — scope detection, smart routing
    │   ├── refine/
    │   ├── align/
    │   ├── build-plan/
    │   ├── implement/       # v5 — session logging, feedback propagation
    │   ├── tdd/
    │   ├── verify/
    │   ├── code-review/     # NEW — automated 5-dimension review
    │   ├── session-review/  # NEW — post-completion analytics
    │   ├── capture-rule/    # v2 — scope-aware destinations
    │   ├── debug/
    │   ├── manage-task/
    │   ├── branch-creator/
    │   ├── pr-creator/
    │   ├── finish-development/
    │   ├── qa-frontend/
    │   ├── qa-backend/
    │   └── vcs/
    │       ├── worktree/
    │       └── worktree-finish/
    ├── adapters/             # Platform adapters
    │   ├── task-manager/    # Jira, Linear, GitHub Issues, Local
    │   ├── vcs/             # GitHub, GitLab, Bitbucket
    │   ├── design/          # Figma (MCP or REST API)
    │   └── report/          # Local, Notion
    └── templates/           # kitt.json schema, context templates
```

---

## Version

See `version` file and `CHANGELOG.md`.
