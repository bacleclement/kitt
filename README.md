# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## 🏎️ What Kitt Gives You

- **Full workflow pipeline:** refine → align → build-plan → implement
- **Systematic debugging:** reproduce → locate → root cause → fix → regress
- **Developer onboarding:** role-aware guide generated from your actual codebase
- **Pluggable adapters:** Jira, Linear, GitHub Issues, Local / GitHub, GitLab, Bitbucket / Figma
- **Smart setup wizard:** scans your repo, asks only what it can't infer
- **Zero hardcoding:** all platform config lives in `project.json`

---

## Skills

| Skill | Purpose |
|-------|---------|
| `setup` | First-time config wizard — or join mode for new team members |
| `onboard` | Personalized onboarding guide (role interview → scoped codebase tour) |
| `orchestrate` | Routes work to the right next step |
| `refine` | Constraint discovery (functional, access, non-functional) |
| `align` | Validates spec against DDD / Clean Architecture |
| `build-plan` | Breaks spec into implementable TDD tasks |
| `implementor` | Implements tasks with TDD, one commit per task |
| `tdd` | Red-Green-Refactor cycle — called by implementor on every task |
| `verify` | Evidence before completion claims — no exceptions |
| `debug` | Systematic bug investigation: reproduce → root cause → fix → regress |
| `manage-task` | Ticket CRUD (read, create, transition, comment) |
| `vcs/branch-creator` | Git branch from ticket key |
| `vcs/pr-creator` | PR creation with task manager linking |

---

## How It Works

Kitt installs **globally on your machine**. Each developer installs once. Updates are a single `git pull`. No submodules, no forced commits.

What lives **in the project repo** (shared by the team):
- `.claude/config/project.json` — task manager, VCS, build commands
- `.claude/context/` — product knowledge, tech stack, code standards
- `.claude/workspace/` — epics, features, bugs, refactors (work items)

What stays **on your machine only** (gitignored):
- `~/.claude/kitt/` — the kitt installation
- `.claude/skills → ~/.claude/kitt/...` — symlink
- `.claude/adapters → ~/.claude/kitt/...` — symlink

---

## Project Configuration (`project.json`)

`.claude/config/project.json` is the single source of truth for all platform config. Every skill reads it — nothing is hardcoded.

```json
{
  "project": {
    "name": "my-project",
    "description": "What this project does",
    "agentDocs": ["services/payments/agents/"]
  },
  "taskManager": {
    "type": "jira",
    "config": {
      "instanceUrl": "https://my-team.atlassian.net",
      "projectKey": "HUB",
      "statuses": {
        "todo":       "À faire",
        "inProgress": "En cours",
        "review":     "Revue en cours",
        "done":       "Terminé(e)",
        "blocked":    "Bloqué(e)"
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
    }
  },
  "build": {
    "test":      "pnpm nx run {project}:test --testPathPattern={pattern}",
    "typecheck": "pnpm nx run {project}:typecheck",
    "lint":      "pnpm nx run {project}:lint",
    "build":     "pnpm nx run {project}:build"
  },
  "commitFormat": {
    "pattern":    "{type}({ticket}): {description}",
    "types":      ["feat", "fix", "refactor", "test", "docs", "chore"],
    "coAuthored": false
  },
  "design": {
    "type": "figma",
    "config": {
      "defaultFileKey": "abc123XYZ"
    }
  }
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `project.name` | ✅ | Project name |
| `project.agentDocs` | — | Paths to service-specific agent documentation |
| `taskManager.type` | ✅ | `jira` · `linear` · `github-issues` · `local` · `none` |
| `taskManager.config.statuses` | ✅ | Status names as they appear in your task manager |
| `vcs.type` | ✅ | `github` · `gitlab` · `bitbucket` |
| `vcs.config.account` | ✅ | GitHub/GitLab username for PR creation |
| `vcs.config.baseBranch` | ✅ | Default: `main` |
| `build.*` | ✅ | Use `{project}` and `{pattern}` as placeholders |
| `commitFormat.pattern` | ✅ | Use `{type}`, `{ticket}`, `{description}` |
| `commitFormat.coAuthored` | — | Add `Co-Authored-By` to commit body. Default: `false` |
| `design.type` | — | `figma` · `none` |
| `design.config.defaultFileKey` | — | Default Figma file key (from URL) |

### Task Manager: `local` (no external tool)

When `taskManager.type` is `local`, work items are stored as files in `.claude/workspace/`. No Jira, no Linear, no account required.

```json
{
  "taskManager": {
    "type": "local",
    "config": {
      "projectKey": "FEAT",
      "statuses": {
        "todo":       "pending",
        "inProgress": "in_progress",
        "review":     "in_review",
        "done":       "completed",
        "blocked":    "blocked"
      }
    }
  }
}
```

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

Kitt scans your repo, asks a few questions, and writes:
- `.claude/config/project.json` — task manager, VCS, build commands
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
    ├── skills/              # Workflow skills
    │   ├── setup/
    │   ├── onboard/
    │   ├── orchestrate/
    │   ├── refine/
    │   ├── align/
    │   ├── build-plan/
    │   ├── implementor/
    │   ├── debug/
    │   ├── manage-task/
    │   └── vcs/
    │       ├── branch-creator/
    │       └── pr-creator/
    ├── adapters/             # Platform adapters
    │   ├── task-manager/    # Jira, Linear, GitHub Issues, Local
    │   ├── vcs/             # GitHub, GitLab, Bitbucket
    │   └── design/          # Figma
    └── templates/           # project.json schema, context templates
```

## Per-Project Structure (after adoption)

```
my-project/.claude/
├── config/project.json      # ✅ committed — platform config (shared)
├── context/                 # ✅ committed — product.md, tech-stack.md, code-standards.md
├── workspace/               # ✅ committed — epics/, features/, bugs/, refactors/
├── CLAUDE.md                # ✅ committed — project AI instructions
├── skills  →  ~/.claude/kitt/.claude/skills/    # gitignored symlink (machine-local)
└── adapters → ~/.claude/kitt/.claude/adapters/  # gitignored symlink (machine-local)
```

---

## Version

See `version` file. Current: 1.0.0
