---
name: worktree-finish
description: Cleans up a git worktree after development is complete. Removes the worktree folder, unregisters it from git, and optionally deletes the local branch. Called by finish-development.
version: 1.0
---

# Worktree Finish Skill

Properly removes a git worktree after work is done. Always use this instead of `rm -rf` — git needs to unregister the worktree or the branch stays locked.

## When Called

Invoked by `finish-development` when the user confirms a worktree needs cleanup.

---

## Step 1: Read kitt.json

```
project.name           → to resolve worktree path
vcs.worktrees.path     → base path (default: ~/worktrees/{{project.name}})
```

---

## Step 2: Identify the worktree

```bash
git worktree list
```

Show the list and ask:
```
"Which worktree do you want to remove?
{list of active worktrees with paths and branches}"
```

If only one non-main worktree exists, pre-select it and confirm:
```
"Remove worktree at {path} (branch: {branch})? (y/n)"
```

---

## Step 3: Confirm PR is merged

```
"Is the PR for {branch} merged?
  A) Yes — remove the worktree
  B) Not yet — I'll come back later"
```

If B: stop. Do not remove the worktree. The developer may need to go back to it for review changes.

---

## Step 4: Remove the worktree

```bash
git worktree remove {path}
```

If it fails (uncommitted changes):
```bash
git worktree remove --force {path}
```

Only use `--force` after confirming with the user that uncommitted changes can be discarded.

Then prune any stale references:
```bash
git worktree prune
```

---

## Step 5: Offer branch cleanup

```
"Delete the local branch {branch} too?
  A) Yes — it's merged, I don't need it
  B) No — keep it"
```

If A:
```bash
git branch -d {branch}
```

If `-d` fails (not fully merged according to git): warn the user and use `-D` only with explicit confirmation.

---

## Step 6: Report

```
"Worktree removed: {path}
Branch: {kept / deleted}

All clean."
```

---

## What NOT to Do

- Never `rm -rf` the worktree folder — always use `git worktree remove`
- Never remove without confirming the PR is merged
- Never force-delete the branch without explicit user confirmation
- Never hardcode paths — always read from kitt.json
