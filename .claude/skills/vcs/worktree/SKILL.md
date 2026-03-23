---
name: worktree
description: Creates an isolated git worktree for a branch outside the repository. Reads path and setup commands from kitt.json. Called by orchestrate when user wants isolation.
version: 1.0
---

# Worktree Skill

Sets up an isolated git worktree outside the repository so build tools (Nx, Turborepo, etc.) never accidentally scan it.

## When Called

Invoked by `orchestrate` after the user confirms they want worktree isolation. Not invoked directly by the user.

---

## Step 1: Read kitt.json

```
project.name              → used to build the worktree path
vcs.worktrees.path        → base path (default: ~/worktrees/{{project.name}})
vcs.worktrees.setup       → commands to run after creation (default: auto-detect)
```

Resolve `{{project.name}}` in the path using the actual `project.name` value.

---

## Step 2: Determine branch name

Use the branch name provided by orchestrate (ticket key, feature slug, etc.).

If none provided, ask:
```
"What branch name for this worktree?"
```

---

## Step 3: Create the worktree

```bash
# Resolve full path
WORKTREE_PATH="~/worktrees/{project.name}/{branch-name}"

# Create worktree on existing branch, or new branch from base
git worktree add "$WORKTREE_PATH" -b "{branch-name}"
# OR if branch already exists:
git worktree add "$WORKTREE_PATH" "{branch-name}"
```

If the path already exists, report it and ask:
```
"Worktree already exists at {path}. Use it, or create a new one with a different name?"
```

---

## Step 4: Run setup commands

Read `vcs.worktrees.setup` from kitt.json.

**If defined:** run each command in order inside the worktree directory.

**If not defined:** auto-detect from project files:
```bash
# Node.js / pnpm
if [ -f pnpm-lock.yaml ]; then pnpm install; fi
if [ -f package-lock.json ]; then npm install; fi
if [ -f yarn.lock ]; then yarn install; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi
```

Report progress as commands run. If a setup command fails, report the error and ask whether to proceed anyway.

---

## Step 5: Report and hand back to orchestrate

```
"Worktree ready at {full-path}
Branch: {branch-name}
Setup: {commands run}

Handing back to orchestrate."
```

Orchestrate continues its routing from where it left off — routing to implement, build-plan, debug, etc.

---

## Kitt.json Reference

```json
"vcs": {
  "worktrees": {
    "path": "~/worktrees/{{project.name}}",
    "setup": [
      "pnpm install"
    ]
  }
}
```

`setup` is optional. If omitted, the skill auto-detects the right install command.
`path` is optional. Default: `~/worktrees/{{project.name}}`.

---

## Exit Point

When development is complete, the worktree must be cleaned up properly.
`finish-development` handles this — it calls `vcs/worktree-finish` after the PR is created.

Never delete a worktree with `rm -rf` — always go through `finish-development`.

---

## What NOT to Do

- Never create the worktree inside the repository directory — always outside
- Never run verify/typecheck/test — that is orchestrate's responsibility
- Never hardcode project names, paths, or package managers
- Never skip the setup step — a worktree without dependencies is broken
