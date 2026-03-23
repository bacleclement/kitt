# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## What Kitt Gives You

- **Full workflow pipeline:** brainstorm → refine → align → build-plan → implement
- **Systematic debugging:** reproduce → locate → root cause → fix → regress
- **Developer onboarding:** role-aware guide generated from your actual codebase
- **Pluggable adapters:** Jira, Linear, GitHub Issues, Local / GitHub, GitLab, Bitbucket
- **Smart setup wizard:** scans your repo, asks one question at a time with lettered options
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
| \`implement\` | Implements tasks with TDD — sequential or subagent mode (parallel within phases) |
| `tdd` | Red-Green-Refactor cycle — called by implement on every task |
| `verify` | Evidence before completion claims — no exceptions |
| `debug` | Systematic bug investigation: reproduce → root cause → fix → regress |
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
       ├─ worktree? → /vcs/worktree → isolated workspace → back to orchestrate
       ├─ needs exploration? → /brainstorm → design.md → /orchestrate
       └─ scope clear?
            ├─ Epic  → /refine (EPIC MODE) → spec + ## User Stories
            │            └─ for each US: /align → /build-plan → /implement → /finish-development → PR + cleanup
            ├─ Feature M  → /build-plan → /implement → /finish-development → PR + cleanup
            └─ Feature S  → /implement → /finish-development → PR + cleanup
```

### Use Case 2 — PM creates a ticket (epic with or without US)

```
ticket key
  └─ /orchestrate (reads ticket via adapter)
       ├─ worktree? → /vcs/worktree → isolated workspace → back to orchestrate
       ├─ Epic, no US yet  → /refine (EPIC MODE) → extract US subfolders
       └─ Epic, US in TM   → import US from task manager
            └─ for each US: /align → /build-plan → /implement → /finish-development → PR + cleanup
```

### Use Case 3 — Known feature or refactor

```
known scope
  └─ /orchestrate (ask size)
       ├─ worktree? → /vcs/worktree → isolated workspace → back to orchestrate
       ├─ S (1-3 files, obvious)  → /implement → /finish-development → PR + cleanup
       ├─ M (clear, < 2 days)     → /build-plan → /implement → /finish-development → PR + cleanup
       └─ L (unclear or risky)    → /refine → /align → /build-plan → /implement → /finish-development → PR + cleanup
```

### Use Case 4 — Bug

```
bug reported
  └─ /orchestrate
       ├─ worktree? → /vcs/worktree → isolated workspace → back to orchestrate
       ├─ root cause unknown  → /debug → /finish-development → PR + cleanup
       ├─ quick fix           → /implement → /finish-development → PR + cleanup
       └─ complex fix         → /build-plan → /implement → /finish-development → PR + cleanup
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

## Implementation Modes

When `/implement` starts, it asks which execution mode you want:

```
A) Subagent — parallel tasks within each phase, checkpoint between phases
B) Sequential — one task at a time, full visibility
```

**Sequential (B):** Default. Kitt implements each task in order — TDD cycle, validation, commit, then asks for your review before moving to the next. Full control, nothing happens without you seeing it.

**Subagent (A):** Kitt reads the phases from `build-plan` and dispatches parallel subagents for tasks within the same phase. Between phases, it shows a summary + diff and waits for your go/stop before continuing.

```
Phase 1 — Domain (parallel)
  subagent: aggregate        ─┐
  subagent: repo interface   ─┴─ run in parallel → checkpoint ✅

Phase 2 — Application (depends on Phase 1)
  subagent: command handler  ─── sequential → checkpoint ✅

Phase 3 — Presentation (depends on Phase 2)
  subagent: controller       ─── sequential → checkpoint ✅
```

Tasks within a phase are independent and safe to parallelize. Tasks across phases are sequential — `build-plan` makes dependencies explicit with `### Phase N` sections.

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
| `vcs.worktrees.path` | — | Base path for worktrees. Use `{{project.name}}` as placeholder. Default: `~/worktrees/{{project.name}}` |
| `vcs.worktrees.setup` | — | Commands to run after worktree creation. If omitted, auto-detected from project files |

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

Kitt scans your repo and walks you through configuration one question at a time — each answer is a lettered option, with a "type your own" escape hatch if none fit. It writes:
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
    │   ├── implement/
    │   ├── tdd/
    │   ├── verify/
    │   ├── debug/
    │   ├── manage-task/
    │   ├── branch-creator/
    │   ├── pr-creator/
    │   ├── finish-development/
    │   └── vcs/
    │       ├── worktree/
    │       └── worktree-finish/
    ├── adapters/             # Platform adapters
    │   ├── task-manager/    # Jira, Linear, GitHub Issues, Local
    │   ├── vcs/             # GitHub, GitLab, Bitbucket
    │   └── design/          # Figma
    └── templates/           # kitt.json schema, context templates
```


## Version

See `version` file. Current: 1.0.0
