# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## What Kitt Gives You

- **Full workflow pipeline:** brainstorm → refine → align → build-plan → implement
- **Systematic debugging:** reproduce → locate → root cause → fix → regress
- **Developer onboarding:** role-aware guide generated from your actual codebase
- **Pluggable adapters:** Jira, Linear, GitHub Issues, Local / GitHub, GitLab, Bitbucket
- **Smart setup wizard:** scans your repo, asks only what it can't infer
- **Zero hardcoding:** all platform config lives in `kitt.json`

---

## Skills

| Skill | Purpose |
|-------|---------|
| `setup` | First-time config wizard — or join mode for new team members |
| `onboard` | Personalized onboarding guide (role interview → scoped codebase tour) |
| `brainstorm` | Explore raw ideas → design.md before any spec or ticket |
| `orchestrate` | Routes work to the right next step based on current state |
| `refine` | Constraint discovery: functional, access, NFRs. Epic mode generates spec with US breakdown |
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

## Workflow

All work starts with `/orchestrate`. It detects the current state and routes to the right skill.

### Use Case 1 — Raw idea (no ticket, no spec)

```
raw idea
  └─ /orchestrate
       ├─ needs exploration? → /brainstorm → design.md → /orchestrate
       └─ scope clear?
            ├─ Epic  → /refine (EPIC MODE) → spec + ## User Stories
            │            └─ for each US: /refine → /align → /build-plan → /implementor → PR
            ├─ Feature M  → /build-plan → /implementor → PR
            └─ Feature S  → /implementor → PR
```

### Use Case 2 — PM creates a ticket (epic with or without US)

```
ticket key
  └─ /orchestrate (reads ticket via adapter)
       ├─ Epic, no US yet  → /refine (EPIC MODE) → extract US subfolders
       └─ Epic, US in TM   → import US from task manager
            └─ for each US: /refine → /align → /build-plan → /implementor → PR
```

### Use Case 3 — Known feature or refactor

```
known scope
  └─ /orchestrate (ask size)
       ├─ S (1-3 files, obvious)  → /implementor
       ├─ M (clear, < 2 days)     → /build-plan → /implementor → PR
       └─ L (unclear or risky)    → /refine → /align → /build-plan → /implementor → PR
```

### Use Case 4 — Bug

```
bug reported
  └─ /orchestrate
       ├─ root cause unknown  → /debug → fix → PR
       ├─ quick fix           → /implementor → PR
       └─ complex fix         → /build-plan → /implementor → PR
```

---

### Epic Workspace Structure

Epics use a two-level structure: epic spec at the top, one subfolder per user story.

```
.claude/workspace/epics/{key}/
├── metadata.json              # status, children list
├── {key}-design.md            # from brainstorm (optional)
├── {key}-spec.md              # from refine — contains ## User Stories
├── {us-key}/
│   ├── {us-key}-spec.md       # from refine US mode (## Architecture added by align)
│   └── {us-key}-plan.md       # from build-plan
└── {us-key-2}/
    ├── {us-key-2}-spec.md
    └── {us-key-2}-plan.md
```

---

## How It Works

Kitt installs **globally on your machine**. Each developer installs once. Updates are a single `git pull`. No submodules, no forced commits.

**Shared in the project repo:**
- `.claude/config/kitt.json` — task manager, VCS, build commands
- `.claude/context/` — product knowledge, tech stack, code standards
- `.claude/workspace/` — epics, features, bugs, refactors (work items)

**Machine-local only (gitignored):**
- `~/.claude/kitt/` — the kitt installation
- `.claude/skills → ~/.claude/kitt/...` — symlink
- `.claude/adapters → ~/.claude/kitt/...` — symlink

---

## Project Configuration (`kitt.json`)

`.claude/config/kitt.json` is the single source of truth for all platform config. Every skill reads it — nothing is hardcoded.

```json
{
  "project": {
    "name": "my-project",
    "description": "What this project does"
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
  }
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `project.name` | ✅ | Project name |
| `taskManager.type` | ✅ | `jira` · `linear` · `github-issues` · `local` · `none` |
| `taskManager.config.statuses` | ✅ | Status names as they appear in your task manager |
| `vcs.type` | ✅ | `github` · `gitlab` · `bitbucket` |
| `vcs.config.account` | ✅ | Username for PR creation |
| `vcs.config.baseBranch` | ✅ | Default: `main` |
| `build.*` | ✅ | Use `{project}` and `{pattern}` as placeholders |
| `commitFormat.pattern` | ✅ | Use `{type}`, `{ticket}`, `{description}` |
| `commitFormat.coAuthored` | — | Add `Co-Authored-By` to commit body. Default: `false` |

### No external task manager? Use `local`

```json
{
  "taskManager": {
    "type": "local",
    "config": {}
  }
}
```

Work items live in `.claude/workspace/` as files. No account, no API keys required.

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
- `.claude/config/kitt.json` — task manager, VCS, build commands
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
    │   ├── brainstorm/
    │   ├── orchestrate/
    │   ├── refine/
    │   ├── align/
    │   ├── build-plan/
    │   ├── implementor/
    │   ├── tdd/
    │   ├── verify/
    │   ├── debug/
    │   ├── manage-task/
    │   └── vcs/
    │       ├── branch-creator/
    │       └── pr-creator/
    ├── adapters/             # Platform adapters
    │   ├── task-manager/    # Jira, Linear, GitHub Issues, Local
    │   ├── vcs/             # GitHub, GitLab, Bitbucket
    │   └── design/          # Figma
    └── templates/           # kitt.json schema, context templates
```

## Per-Project Structure (after adoption)

```
my-project/.claude/
├── config/kitt.json         # ✅ committed — platform config (shared)
├── context/                 # ✅ committed — product.md, tech-stack.md, code-standards.md
├── workspace/               # ✅ committed — epics/, features/, bugs/, refactors/
├── CLAUDE.md                # ✅ committed — project AI instructions
├── project-skills/          # ✅ committed — project-specific skills (optional)
│   └── my-skill/
│       └── SKILL.md
├── skills  →  ~/.claude/kitt/.claude/skills/    # gitignored symlink (machine-local)
└── adapters → ~/.claude/kitt/.claude/adapters/  # gitignored symlink (machine-local)
```

### Project-Specific Skills

Kitt provides generic skills. For domain-specific workflows, add them to `.claude/project-skills/`:

```
.claude/project-skills/
└── my-skill/
    └── SKILL.md
```

Document them in `CLAUDE.md` so Claude knows they exist:

```markdown
## Project-Specific Skills

| Skill | File | Purpose |
|-------|------|---------|
| `my-skill` | `.claude/project-skills/my-skill/SKILL.md` | What it does |
```

**Invocation:** `Read .claude/project-skills/my-skill/SKILL.md` — there is no slash command. Claude reads the file and follows its instructions.

---

## Version

See `version` file. Current: 1.0.0
