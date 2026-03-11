---
name: task-manager-linear
implements: task-manager-interface
cli: linear-cli (or Linear API via curl)
version: 1.0
---

# Linear Adapter

Implements the task-manager interface for Linear using the Linear CLI or API.

## Prerequisites

```bash
# Option A: Linear CLI
npm install -g @linear/cli
linear auth login

# Option B: Direct API (no CLI needed)
# Set LINEAR_API_KEY in .env.local
echo $LINEAR_API_KEY | grep -q . && echo "✅ API key set" || echo "❌ set LINEAR_API_KEY in .env.local"
```

## Configuration (from kitt.json)

```json
{
  "taskManager": {
    "type": "linear",
    "config": {
      "instanceUrl": "https://linear.app/your-team",
      "projectKey": "ENG",
      "statuses": {
        "todo":       "Todo",
        "inProgress": "In Progress",
        "review":     "In Review",
        "done":       "Done",
        "blocked":    "Blocked"
      }
    }
  }
}
```

## read(issueId)

Linear uses short IDs (e.g. `ENG-42`).

```bash
# Via Linear CLI
linear issue view {issueId}

# Via API
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ issue(id: \"{issueId}\") { id identifier title description state { name } assignee { name } } }"}'
```

## create(team, type, summary, description, parent?)

Linear uses "teams" instead of projects and "labels" for types.

```bash
# Via API
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"mutation { issueCreate(input: { teamId: \\\"{teamId}\\\", title: \\\"{summary}\\\", description: \\\"{description}\\\" }) { success issue { identifier } } }\"}"
```

Note: Linear descriptions use **Markdown** (not ADF JSON).

## transition(issueId, targetStatus)

targetStatus is resolved from `project.taskManager.config.statuses.*`.

```bash
# Get state ID for target status name first
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d '{"query": "{ workflowStates { nodes { id name } } }"}'

# Then update issue state
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d "{\"query\": \"mutation { issueUpdate(id: \\\"{issueId}\\\", input: { stateId: \\\"{stateId}\\\" }) { success } }\"}"
```

## comment(issueId, body)

Linear comments use **Markdown** — no ADF conversion needed.

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d "{\"query\": \"mutation { commentCreate(input: { issueId: \\\"{issueId}\\\", body: \\\"{body}\\\" }) { success } }\"}"
```

## assign(issueId, assignee)

```bash
# Get user ID by name/email first
# Then assign
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d "{\"query\": \"mutation { issueUpdate(id: \\\"{issueId}\\\", input: { assigneeId: \\\"{userId}\\\" }) { success } }\"}"
```

## search(query)

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -d "{\"query\": \"{ issues(filter: { title: { containsIgnoreCase: \\\"{query}\\\" } }) { nodes { identifier title state { name } assignee { name } } } }\"}"
```
