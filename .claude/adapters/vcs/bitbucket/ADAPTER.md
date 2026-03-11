---
name: vcs-bitbucket
implements: vcs-interface
cli: bb (Bitbucket CLI) or curl (Bitbucket API)
version: 1.0
---

# Bitbucket VCS Adapter

Implements the VCS interface for Bitbucket using the Bitbucket API via curl.
Bitbucket calls pull requests "Pull Requests".

## Prerequisites

```bash
# Set in .env.local (gitignored)
echo $BITBUCKET_TOKEN | grep -q . && echo "✅ token set" || echo "❌ set BITBUCKET_TOKEN in .env.local"
echo $BITBUCKET_USERNAME | grep -q . && echo "✅ username set" || echo "❌ set BITBUCKET_USERNAME in .env.local"
```

Always source `.env.local` before Bitbucket operations:
```bash
source .env.local
```

## Configuration (from kitt.json)

```json
{
  "vcs": {
    "type": "bitbucket",
    "config": {
      "account":    "your-bitbucket-username",
      "org":        "your-workspace",
      "repo":       "your-repo",
      "baseBranch": "main"
    }
  }
}
```

## switchAccount(account)

Bitbucket uses token-based auth. Verify:

```bash
source .env.local
curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN" \
  https://api.bitbucket.org/2.0/user | jq -r '.username'
```

## createBranch(ticketKey, type, summary)

Same slug logic as other adapters:

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

```bash
source .env.local

PR_URL=$(curl -s -X POST \
  -u "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN" \
  -H "Content-Type: application/json" \
  https://api.bitbucket.org/2.0/repositories/{org}/{repo}/pullrequests \
  -d "{
    \"title\": \"{title}\",
    \"description\": \"{body}\",
    \"source\": { \"branch\": { \"name\": \"{branch}\" } },
    \"destination\": { \"branch\": { \"name\": \"{base}\" } },
    \"close_source_branch\": true
  }" | jq -r '.links.html.href')

echo "✅ PR created: $PR_URL"
```

## getPRUrl(branch)

```bash
source .env.local
curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/{org}/{repo}/pullrequests?q=source.branch.name=\"{branch}\"" \
  | jq -r '.values[0].links.html.href'
```
