---
name: task-manager-interface
version: 1.0
---

# Task Manager Adapter Interface

All task-manager adapters MUST implement these operations.
Skills call this interface — never platform CLIs directly.

## How Skills Use Adapters

1. Read `.claude/config/project.json`
2. `type = project.taskManager.type`  → e.g. `"jira"`
3. Load `.claude/adapters/task-manager/{type}/ADAPTER.md`
4. Follow the adapter's instructions for the needed operation

## Operations

### read(ticketKey)

Fetch full ticket details.

Input: `ticketKey` — e.g. `HUB-1234`, `ENG-42`
Output: `{ key, summary, type, status, description, assignee, parent?, children? }`

### create(project, type, summary, description, parent?)

Create a new ticket. Check for duplicates before creating (search by summary first).

Input:
- `project` — from `project.taskManager.config.projectKey`
- `type` — e.g. `"Story"`, `"Bug"`, `"Task"`, `"Sub-task"`
- `summary` — ticket title
- `description` — body text (format varies by adapter)
- `parent?` — parent ticket key for subtasks

Output: `{ key, url }`

Always ask user confirmation before creating.

### update(ticketKey, fields)

Update ticket fields (summary, description, assignee).

Always ask user confirmation before updating.

### transition(ticketKey, targetStatus)

Change ticket status.

- `targetStatus` MUST come from `project.taskManager.config.statuses.*` — never hardcode status names
- Some platforms require intermediate transitions — adapter handles chaining

Always ask user confirmation before transitioning.

### comment(ticketKey, body)

Add a comment to a ticket.

- Body format varies by adapter (ADF JSON for Jira, Markdown for Linear/GitHub)
- Adapter handles format conversion

Always ask user confirmation before posting.

### assign(ticketKey, assignee)

Assign ticket to a user. Use `"@me"` for current user.
Skip silently if already assigned to the target user.

### link(ticketKey, destKey, linkType)

Create a relationship between tickets.
`linkType` — e.g. `"Relates"`, `"Blocks"`, `"Duplicate"`

### search(query)

Search for tickets.
`query` — natural language or platform-specific query syntax (adapter translates)

Output: array of `{ key, summary, status, assignee }`

## Status Name Mapping

Skills NEVER hardcode status names. Always use:

```
project.taskManager.config.statuses.todo
project.taskManager.config.statuses.inProgress
project.taskManager.config.statuses.review
project.taskManager.config.statuses.done
project.taskManager.config.statuses.blocked
```

The adapter maps these semantic names to the platform's actual status strings.

## Error Handling

All operations must:
1. Verify prerequisites (CLI installed + authenticated) before executing
2. Return structured errors: `{ success: false, operation, error: { code, message, remediation } }`
3. Never proceed silently on failure

Common error codes: `AUTH_FAILED`, `TICKET_NOT_FOUND`, `INVALID_TRANSITION`, `USER_CANCELLED`
