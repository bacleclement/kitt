---
name: vcs-gitlab
implements: vcs-interface
cli: glab, git
version: 1.0
---

# GitLab VCS Adapter

Implements the VCS interface for GitLab using `git` + `glab` CLI.
GitLab calls pull requests "Merge Requests" (MRs).

## Prerequisites

```bash
glab auth status && echo "✅ authenticated" || echo "❌ run: glab auth login"
```

## Configuration (from project.json)

```json
{
  "vcs": {
    "type": "gitlab",
    "config": {
      "account":    "your-gitlab-username",
      "org":        "your-group",
      "repo":       "your-project",
      "baseBranch": "main"
    }
  }
}
```

## switchAccount(account)

GitLab uses token-based auth — no account switching command.
Verify authenticated user matches expected account:

```bash
glab auth status
# If wrong user: glab auth login --token <new-token>
```

## createBranch(ticketKey, type, summary)

Identical slug logic to GitHub adapter:

```bash
SLUG=$(echo "{summary}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)
BRANCH="{type}/{ticketKey}-$SLUG"
git checkout -b "$BRANCH"
```

## push(branch)

```bash
git push -u origin {branch}
```

## createPR(title, body, branch, base)

GitLab calls these Merge Requests:

```bash
cat > /tmp/vcs-mr-{timestamp}.md << 'MRBODY'
{body}
MRBODY

MR_URL=$(glab mr create \
  --title "{title}" \
  --description "$(cat /tmp/vcs-mr-{timestamp}.md)" \
  --source-branch {branch} \
  --target-branch {base} \
  --yes \
  | grep -o 'https://[^ ]*')

rm /tmp/vcs-mr-{timestamp}.md
echo "✅ MR created: $MR_URL"
```

## getPRUrl(branch)

```bash
glab mr view {branch} | grep -o 'https://[^ ]*' | head -1
```
