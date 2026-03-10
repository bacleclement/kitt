---
name: vcs-github
implements: vcs-interface
cli: gh, git
version: 1.0
---

# GitHub VCS Adapter

Implements the VCS interface for GitHub using `git` + `gh` CLI.

## Prerequisites

```bash
gh auth status && echo "✅ authenticated" || echo "❌ run: gh auth login"
git --version && echo "✅ git available"
```

## Configuration (from project.json)

```json
{
  "vcs": {
    "type": "github",
    "config": {
      "account":    "your-github-username",
      "org":        "your-org",
      "repo":       "your-repo",
      "baseBranch": "main"
    }
  }
}
```

## switchAccount(account)

Switch to the correct GitHub account before PR creation:

```bash
GH_HOST=github.com gh auth switch --user {account}
```

`account` = `project.vcs.config.account`

Verify switch worked:
```bash
gh auth status
```

## createBranch(ticketKey, type, summary)

```bash
# 1. Generate slug from summary
SLUG=$(echo "{summary}" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/--*/-/g' \
  | sed 's/^-//' \
  | sed 's/-$//' \
  | cut -c1-50)

BRANCH="{type}/{ticketKey}-$SLUG"

# 2. Check for dirty working tree
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "⚠️  Uncommitted changes detected."
  echo "    Stash them first: git stash push -m 'Before $BRANCH'"
  # Ask user: stash automatically or abort?
fi

# 3. Check if branch exists
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Branch $BRANCH already exists. Checkout? (y/n)"
  # If yes: git checkout $BRANCH
  # If no: suggest alternative name
else
  git checkout -b "$BRANCH"
  echo "✅ Created branch: $BRANCH"
fi
```

## push(branch)

```bash
git push -u origin {branch}
```

## createPR(title, body, branch, base)

```bash
# 1. Switch to correct account
GH_HOST=github.com gh auth switch --user {account}

# 2. Write body to temp file
cat > /tmp/vcs-pr-{timestamp}.md << 'PRBODY'
{body}
PRBODY

# 3. Create PR
PR_URL=$(gh pr create \
  --title "{title}" \
  --body-file /tmp/vcs-pr-{timestamp}.md \
  --base {base} \
  --json url -q .url)

# 4. Cleanup
rm /tmp/vcs-pr-{timestamp}.md

echo "✅ PR created: $PR_URL"
```

Returns: `$PR_URL`

## getPRUrl(branch)

```bash
gh pr view {branch} --json url -q .url
```
