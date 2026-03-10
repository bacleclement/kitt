---
name: setup
description: Interactive kitt configuration wizard. Scans the project repo, asks targeted questions, writes project.json, generates context file drafts, and validates completeness.
version: 1.0
---

# Kitt Setup Wizard

> "Good evening. I'm KITT — Kitt Intelligence and Tooling Toolkit.
> I don't transform into a car, but I will scan your entire codebase in seconds
> and ask surprisingly few questions. Let's begin."

## When to Use

After running `kitt-setup.sh` (Phase 1). Configures kitt for this specific project.
Also used for: `/setup validate` to check completeness.

## Commands

- `/setup` — full wizard (scan → questions → write config → generate context)
- `/setup validate` — completeness check only
- `/setup update` — re-run wizard to update project.json (keeps existing context files)

---

## /setup — Full Wizard

### Step 1: Check kitt installation

```
Verify .claude/kitt/ exists (submodule)
Verify .claude/skills symlink points to .claude/kitt/.claude/skills/
Verify .claude/adapters symlink points to .claude/kitt/.claude/adapters/
Verify .claude/conductor/ has all four subfolders
```

If any missing:
> "Kitt isn't fully installed yet. Run `bin/kitt-setup.sh` first, then come back."

If project.json already exists:
> "I found an existing project.json. Run `/setup update` to modify it,
> or continue to overwrite. What would you prefer?"

### Step 2: Deep repo scan

Announce: *"Scanning your repository. I'll be thorough."*

Scan the following (automated, no user input needed):

**Project identity:**
- Read `README.md` (first 100 lines)
- Read all manifest files: `package.json`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`
- Detect project name, description, main language

**Folder structure:**
- List top 3 levels of directory tree (excluding `node_modules`, `.git`, `dist`, `build`)
- Detect monorepo indicators: `nx.json`, `lerna.json`, `pnpm-workspace.yaml`, `turborepo.json`
- Detect architecture patterns: presence of `domain/`, `application/`, `infrastructure/` (DDD), `src/`, `lib/`, `pkg/`, `cmd/`

**Tech stack:**
- Backend: detect NestJS, Spring Boot, FastAPI, Rails, Go, Rust from manifests
- Frontend: detect React, Vue, Angular, Svelte, Next.js from manifests
- Database: detect Prisma, TypeORM, Hibernate, SQLAlchemy from manifests
- Testing: detect Jest, pytest, JUnit, RSpec from manifests + config files

**Build commands:**
- Read `package.json scripts` section
- Read `Makefile` if present
- Read CI config: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- Detect test/typecheck/lint/build commands

**Code standards:**
- Read `.eslintrc*`, `eslint.config.*`, `.prettierrc*`, `tsconfig.json`
- Sample 3-5 source files for naming conventions and import patterns

**Git integration:**
- Run: `git remote -v` → detect GitHub/GitLab/Bitbucket URL + org/repo
- Run: `git log --oneline -20` → scan commit messages for ticket patterns (`[A-Z]+-[0-9]+`)
- From ticket patterns: infer task manager project key (e.g. `HUB-` → project key `HUB`)
- From remote URL: infer task manager instance (GitHub Issues vs external)

**Agent docs:**
- Search for: `agents/`, `AGENT.md`, `AGENTS.md`, `ARCHITECTURE.md` anywhere in tree
- Record found paths for `project.agentDocs`

**Existing kitt config:**
- Check if any context files already exist in `.claude/context/`

Present scan summary:
> "Scan complete. I detected:
> - {framework} project with {N} {components}
> - Ticket pattern: {PATTERN}-XXXX (project key: {KEY})
> - {VCS} remote: {org}/{repo}
> - Build system: {detected}
> - Agent docs: {paths found}
>
> I have {N} questions."

### Step 3: Targeted questions (only what scan couldn't answer)

Ask ONLY questions where the answer wasn't inferred. Skip any that were detected.

**Task manager questions** (if not inferred):
1. "What task manager does this project use?" → Jira / Linear / GitHub Issues / None
2. If Jira: "Instance URL?" (pre-fill with inferred value if found in commits/README)
3. "Project key?" (pre-fill if inferred)
4. "Status names — I'll use these defaults, correct them if needed:"
   Show inferred or default statuses, ask for confirmation or corrections.

**VCS questions** (if not inferred):
5. "Which account should create PRs?" (pre-fill if single account in git config)

**Build questions** (if not inferred):
6. "Confirm build commands:" (show inferred commands, ask for corrections)

**Agent docs:**
7. "I found agent docs at: {paths}. Any others I missed?"

**Architecture:**
8. "Any specific architecture constraints to enforce? (e.g. no barrel files, strict DDD layers)"
   Show detected patterns, ask if there's more.

### Step 4: Write project.json

Show full project.json preview:
> "Here's your project.json — confirming before I write it:"
> {show full JSON}

After confirmation, write to `.claude/config/project.json`.

The JSON structure:
```json
{
  "$schema": ".claude/kitt/.claude/templates/project.json.schema",
  "kitt": {
    "version": "{kitt version from .claude/kitt/version}",
    "installedAt": "{ISO timestamp}"
  },
  "project": {
    "name": "{detected project name}",
    "description": "{detected description}",
    "agentDocs": ["{detected agent doc paths}"]
  },
  "taskManager": {
    "type": "{jira|linear|github-issues|none}",
    "config": {
      "instanceUrl": "{instance url}",
      "projectKey": "{project key}",
      "statuses": {
        "todo":       "{todo status name}",
        "inProgress": "{in progress status name}",
        "review":     "{review status name}",
        "done":       "{done status name}",
        "blocked":    "{blocked status name}"
      }
    }
  },
  "vcs": {
    "type": "{github|gitlab|bitbucket}",
    "config": {
      "account":    "{pr account username}",
      "org":        "{org or owner}",
      "repo":       "{repo name}",
      "baseBranch": "main"
    }
  },
  "build": {
    "test":      "{detected test command with {project} and {pattern} placeholders}",
    "typecheck": "{detected typecheck command}",
    "lint":      "{detected lint command}",
    "build":     "{detected build command}"
  },
  "commitFormat": {
    "pattern": "{type}({ticket}): {description}",
    "types": ["feat", "fix", "refactor", "test", "docs", "chore"],
    "coAuthored": false
  }
}
```

### Step 5: Generate context file drafts

Generate three files from scan data:

**`product.md`** — from README + detected project purpose:
```markdown
# {Project Name} — Product Context

## What Is {Project Name}

{inferred from README description + codebase purpose}

## Users

| Role | Description | Key Actions |
|------|-------------|-------------|
{inferred from README or codebase, or placeholder rows}

## Core Domains

{inferred from folder structure / module names, or placeholder}

## Business Rules

{inferred from README business rules section, or placeholder}
```

**`tech-stack.md`** — from manifests + detected patterns:
```markdown
# {Project Name} — Tech Stack

## Architecture

{inferred: monorepo / microservices / monolith}

## Backend

| Layer | Technology |
{inferred from manifests}

## Frontend

| Layer | Technology |
{inferred from manifests}

## Databases

{inferred from ORM/driver dependencies}

## Infrastructure & CI/CD

{inferred from CI config + cloud SDKs}
```

**`code-standards.md`** — from lint config + code samples:
```markdown
# {Project Name} — Code Standards

## Naming Conventions

{inferred from code samples}

## Import Rules

{inferred from eslint config + samples}

## Formatting

{inferred from prettier config}

## Architecture

{inferred from detected patterns (DDD, hexagonal, etc.)}

## Testing

{inferred from test framework + sample test files}
```

### Step 6: End message

> "✅ Kitt configured.
>
> Your context files are at `.claude/context/` — they're the foundation
> every skill reads before acting. I've done my best with the scan,
> but you know your project better than I do.
>
> Review and edit them, then run `/setup validate` to confirm
> everything is in order. After that: `/workflow-orchestrator`
> to start working."

---

## /setup validate

Check completeness and report:

```
Checking .claude/config/project.json...
  ✅ taskManager: {type} — adapter found at .claude/adapters/task-manager/{type}/ADAPTER.md
  ✅ vcs: {type} — adapter found at .claude/adapters/vcs/{type}/ADAPTER.md
  ✅ build commands: test, typecheck, lint, build — all present
  ✅ commitFormat: pattern defined

Checking .claude/context/...
  ✅/⚠️  product.md — {N} lines {has/missing}: {required sections}
  ✅/⚠️  tech-stack.md — {N} lines {has/missing}: {required sections}
  ✅/⚠️  code-standards.md — {N} lines {has/missing}: {required sections}

Checking .claude/conductor/...
  ✅/❌ epics/ features/ bugs/ refactors/ — {present/missing}

Overall: {COMPLETE ✅ / INCOMPLETE ⚠️}
```

Required sections per context file:
- `product.md`: `## What Is`, `## Users`, `## Business Rules`
- `tech-stack.md`: `## Architecture`, one technology section
- `code-standards.md`: `## Architecture`, `## Testing`

On COMPLETE:
> "All systems nominal. You're cleared for takeoff. Run `/workflow-orchestrator` to begin."

On INCOMPLETE:
> "Almost. {N} item(s) need attention. Fix them and re-run `/setup validate`."

---

## /setup update

Re-run Step 3 (questions) and Step 4 (write project.json) only.
Do NOT overwrite context files.
Useful when: task manager changes, VCS account changes, new agentDocs paths.
