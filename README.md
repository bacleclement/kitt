# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## 🚗 What Kitt Gives You

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
| `debug` | Systematic bug investigation: reproduce → root cause → fix → regress |
| `manage-task` | Ticket CRUD (read, create, transition, comment) |
| `vcs/branch-creator` | Git branch from ticket key |
| `vcs/pr-creator` | PR creation with task manager linking |

---

## How It Works

Kitt installs **globally on your machine** — not inside the project repo. Each developer installs once. Updates are a single `git pull`. No submodules, no forced commits.

What lives **in the project repo** (shared by the team):
- `.claude/config/project.json` — task manager, VCS, build commands
- `.claude/context/` — product knowledge, tech stack, code standards
- `.claude/conductor/` — epics, features, bugs, refactors (work items)

What stays **on your machine only** (gitignored):
- `~/.claude/kitt/` — the kitt installation
- `.claude/skills → ~/.claude/kitt/...` — symlink
- `.claude/adapters → ~/.claude/kitt/...` — symlink

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
├── conductor/               # ✅ committed — epics/, features/, bugs/, refactors/
├── CLAUDE.md                # ✅ committed — project AI instructions
├── skills  →  ~/.claude/kitt/.claude/skills/    # gitignored symlink (machine-local)
└── adapters → ~/.claude/kitt/.claude/adapters/  # gitignored symlink (machine-local)
```

---

## Version

See `version` file. Current: 1.0.0
