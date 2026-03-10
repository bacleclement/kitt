---
name: task-manager-github-issues
implements: task-manager-interface
cli: gh
version: 1.0
---

# GitHub Issues Adapter

Implements the task-manager interface for GitHub Issues using the `gh` CLI.

## Prerequisites

```bash
gh auth status && echo "✅ authenticated" || echo "❌ run: gh auth login"
```

## Configuration (from project.json)

```json
{
  "taskManager": {
    "type": "github-issues",
    "config": {
      "instanceUrl": "https://github.com/org/repo",
      "projectKey": "org/repo",
      "statuses": {
        "todo":       "open",
        "inProgress": "open",
        "review":     "open",
        "done":       "closed",
        "blocked":    "open"
      }
    }
  }
}
```

Note: GitHub Issues has only open/closed states. Use labels (e.g. `in-progress`, `blocked`) to represent richer statuses. The adapter applies labels on transition.

## read(issueNumber)

```bash
gh issue view {issueNumber} --repo {projectKey} --json number,title,body,state,assignees,labels
```

## create(repo, type, summary, description, parent?)

```bash
# Check for duplicates
gh issue list --repo {projectKey} --search "{summary}" --json number,title

# Create
gh issue create \
  --repo {projectKey} \
  --title "{summary}" \
  --body "{description}" \
  --label "{type}"
```

Note: GitHub Issues descriptions use **Markdown**.

## transition(issueNumber, targetStatus)

GitHub uses open/closed + labels for status:

```bash
# Map semantic status to GitHub action:
# todo/inProgress/review/blocked → ensure open + apply label
# done → close issue

if [ "{targetStatus}" = "closed" ]; then
  gh issue close {issueNumber} --repo {projectKey}
else
  gh issue reopen {issueNumber} --repo {projectKey} 2>/dev/null || true
  gh issue edit {issueNumber} --repo {projectKey} --add-label "{targetStatus}"
fi
```

## comment(issueNumber, body)

```bash
gh issue comment {issueNumber} --repo {projectKey} --body "{body}"
```

Body uses **Markdown**.

## assign(issueNumber, assignee)

```bash
gh issue edit {issueNumber} --repo {projectKey} --add-assignee "{assignee}"
```

Use `@me` for current user.

## search(query)

```bash
gh issue list --repo {projectKey} --search "{query}" \
  --json number,title,state,assignees,labels
```
