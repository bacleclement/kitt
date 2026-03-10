# Kitt — Kitt Intelligence and Tooling Toolkit

> "I don't transform into a car, but I will scan your entire codebase in seconds." — KITT

Kitt is a reusable AI workflow engine for Claude Code. It provides a complete spec-driven development pipeline with pluggable integrations for any task manager and VCS.

## What Kitt Gives You

- **Full workflow pipeline:** refinement → architecture-alignment → plan-building → implementor
- **Pluggable adapters:** Jira, Linear, GitHub Issues / GitHub, GitLab, Bitbucket
- **Smart setup wizard:** scans your repo, asks only what it can't infer
- **Zero hardcoding:** all platform config lives in project.json

## Adopt Kitt in Your Project

### Step 1: Install (30 seconds)

```bash
bash /path/to/kitt/bin/kitt-setup.sh
```

### Step 2: Configure (5 minutes)

Open Claude Code in your project and run:

```
/setup
```

KITT will scan your repo and guide you through configuration.

### Step 3: Validate

```
/setup validate
```

### Step 4: Work

```
/workflow-orchestrator
```

## Kitt Structure

```
kitt/
├── bin/kitt-setup.sh           # Phase 1: submodule + symlinks
└── .claude/
    ├── skills/                 # Workflow skills
    ├── adapters/               # Platform adapters
    │   ├── task-manager/       # Jira, Linear, GitHub Issues
    │   └── vcs/                # GitHub, GitLab, Bitbucket
    └── templates/              # project.json schema, context templates
```

## Per-Project Structure (after adoption)

```
my-project/.claude/
├── kitt/                       # git submodule (this repo)
├── skills -> kitt/.claude/skills/
├── adapters -> kitt/.claude/adapters/
├── config/project.json         # your platform config
├── context/                    # product.md, tech-stack.md, code-standards.md
└── conductor/                  # epics/, features/, bugs/, refactors/
```

## Update Kitt

```bash
cd my-project
git submodule update --remote .claude/kitt
git add .claude/kitt
git commit -m "chore: update kitt to latest"
```

## Version

See `version` file. Current: 1.0.0
