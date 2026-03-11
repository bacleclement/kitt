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

## Adopting Kitt

### Step 1: Install (30 seconds)

From your **project root**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bacleclement/kitt/main/bin/kitt-setup.sh)
```

This adds kitt as a git submodule, creates symlinks, and scaffolds the conductor folders.

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

Clone the repo (kitt comes with it via submodule), then in Claude Code:

```
/setup
```

Kitt detects that `project.json` already exists and switches to **join mode**:
- Initializes the git submodule (`git submodule update --init --recursive`)
- Recreates any missing symlinks
- Verifies your credentials (task manager, VCS)
- Hands off to `/onboard` for your personalized guide

No wizard. No re-configuration. Done in under a minute.

---

## Kitt Structure

```
kitt/
├── bin/kitt-setup.sh           # Phase 1: submodule + symlinks
└── .claude/
    ├── skills/                 # Workflow skills
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
    ├── adapters/               # Platform adapters
    │   ├── task-manager/       # Jira, Linear, GitHub Issues, Local
    │   ├── vcs/                # GitHub, GitLab, Bitbucket
    │   └── design/             # Figma
    └── templates/              # project.json schema, context templates
```

## Per-Project Structure (after adoption)

```
my-project/.claude/
├── kitt/                       # git submodule (this repo)
├── adapters -> kitt/.claude/adapters/
├── config/project.json         # platform config (committed, shared)
├── context/                    # product.md, tech-stack.md, code-standards.md (committed, shared)
├── skills/                     # project-specific skills (if any) + kitt skills via symlink
└── conductor/                  # epics/, features/, bugs/, refactors/ (work items)
```

---

## Update Kitt

```bash
cd my-project
git submodule update --remote .claude/kitt
git add .claude/kitt
git commit -m "chore: update kitt to latest"
```

---

## Version

See `version` file. Current: 1.0.0
