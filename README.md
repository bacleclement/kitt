# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager, VCS, and design tool.

---

## What Kitt Gives You

- 🚗 **Full workflow pipeline:** refine → align → build-plan → implement
- 🚗 **Systematic debugging:** reproduce → locate → root cause → fix → regress
- 🚗 **Developer onboarding:** role-aware guide generated from your actual codebase
- 🚗 **Pluggable adapters:** Jira, Linear, GitHub Issues, Local / GitHub, GitLab, Bitbucket / Figma
- 🚗 **Smart setup wizard:** scans your repo, asks only what it can't infer
- 🚗 **Zero hardcoding:** all platform config lives in `project.json`

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

Kitt installs **globally on your machine** (like superpowers or conductor) — not inside the project repo. Each developer installs once. Updates are a single `git pull`. No submodules, no forced commits.

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

### Step 1: Install (30 seconds)

From your **project root**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bacleclement/kitt/main/bin/install.sh)
```

This installs kitt to `~/.claude/kitt/`, creates local symlinks, and scaffolds the project structure.

### Step 2: Configure (5 minutes)

Open Claude Code in your project and run:

```
/setup
```

Kitt scans your repo and guides you through configuration. When done, it writes:
- `.claude/config/project.json` — platform config (task manager, VCS, build commands)
- `.claude/context/product.md` — what the product is
- `.claude/context/tech-stack.md` — frameworks and infrastructure
- `.claude/context/code-standards.md` — naming, imports, patterns

**Commit these files.** They're the shared foundation every skill reads.

### Step 3: Validate

```
/setup validate
```

### Step 4: Work

```
/orchestrate
```

---

## New Team Member? (Project Already Configured)

### Step 1: Install Kitt on your machine (once)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bacleclement/kitt/main/bin/install.sh)
```

Run this from the cloned project root. Kitt detects that `project.json` already exists, switches to **join mode**, and skips the wizard entirely:
- Installs `~/.claude/kitt/` if not already present
- Recreates local symlinks
- Verifies your credentials (task manager, VCS)
- Hands off to `/onboard` for your personalized guide

### Step 2: Onboard

```
/setup   → join mode → /onboard
```

No wizard. No re-configuration. No commits needed. Done in under a minute.

---

## Updating Kitt

On any machine:

```bash
git -C ~/.claude/kitt pull
```

That's it. Symlinks pick up the new version instantly. Nothing to commit in your project.

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
