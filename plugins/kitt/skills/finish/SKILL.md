---
name: finish
description: Close out a ticket — confirm verify passed, push the branch and open the PR linked to the ticket. Use when the plan is executed and verified. Refuses to open the PR if any acceptance check failed.
---

# Finish

The last gate. Its only job is to refuse when the work is not actually done.

**Core principle:** a PR is a claim that the work holds. Do not make that claim on unrun checks.

## Precondition ⛔

`verify` ran **in this session** and every gate passed.

```
Any failing check → no PR. Go back to implement.
```

Not "the PR will show it". Not "CI will catch it". A PR opened on a red branch spends someone else's review time discovering what you already could have known.

If `verify` has not run in this session, run it now. Do not take a previous session's word for it.

## Workflow

### 1. Check the diff

```bash
git status --short
git diff origin/<base>...HEAD --stat
```

Look for what should not be there: debug prints, commented-out code, a stray file, a secret, an unrelated change that crept in. Read the diff — do not just count the lines.

### 2. Push

```bash
git push -u origin HEAD
```

### 3. Open the PR

Link it to the ticket so closing one closes the other, and write the body for the reviewer — what changed, how it was proven, what to look at first.

```bash
gh pr create --title "<type>(#<ticket>): <what changed>" --body "$(cat <<'EOF'
Closes #<ticket>

## What changed
<one paragraph, in plain terms>

## How it was proven
| Gate | Result |
|---|---|
| `<acceptance command>` | pass |
| `<lint / types / tests>` | pass |

## What to look at first
<the part where review is worth the most>

## Learned
<what verify added to the context or the tests — or "nothing new">
EOF
)"
```

Match the repo's title convention — `git log --oneline -10` shows it.

### 4. Point the ticket at the PR

```bash
gh issue comment <N> --body "PR: <url> — plan executed, all gates green."
```

### 5. Report

Give the PR URL, the gates that passed, and anything the reviewer should decide rather than rubber-stamp.

## Never

- Never open a PR with a failing or unrun check.
- Never write "should work", "probably fine" or "minor fix" in a PR body — say what was proven.
- Never merge your own PR unless the project says you may.
- Never leave the ticket without a link to the PR.
