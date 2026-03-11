---
name: task-manager-local
implements: task-manager-interface
cli: none (file-based)
version: 1.0
---

# Local Adapter

Implements the task-manager interface using local files only. No external CLI or API.
Everything lives in `.claude/workspace/`. Works offline. No account required.

Use this when `project.json taskManager.type` is `"local"`.

## Configuration (from project.json)

```json
{
  "taskManager": {
    "type": "local",
    "config": {
      "projectKey": "FEAT",
      "statuses": {
        "todo":       "pending",
        "inProgress": "in_progress",
        "review":     "in_review",
        "done":       "completed",
        "blocked":    "blocked"
      }
    }
  }
}
```

## File Structure

All data lives in `.claude/workspace/`:

```
.claude/workspace/
├── epics/
│   └── FEAT-001/
│       ├── metadata.json      ← ticket data
│       ├── FEAT-001-spec.md   ← description / user story
│       └── FEAT-001-log.md    ← comments and status history
├── features/
│   └── FEAT-002/
│       ├── metadata.json
│       ├── FEAT-002-spec.md
│       └── FEAT-002-log.md
├── bugs/
└── refactors/
```

## read(ticketKey)

```
1. Search .claude/workspace/*/{ticketKey}/ — find the folder
2. Read metadata.json from that folder
3. Read {ticketKey}-spec.md if it exists
```

Return:
```json
{
  "key": "{ticketKey}",
  "summary": "{metadata.title}",
  "type": "{metadata.type}",
  "status": "{metadata.status}",
  "description": "{contents of spec.md}",
  "assignee": "{metadata.assignee or null}"
}
```

If folder not found: `{ success: false, error: { code: "TICKET_NOT_FOUND" } }`

## create(project, type, summary, description, parent?)

Generate key: `{projectKey}-{next available number}`

To find next number: list all folders in conductor/ subfolders, extract numbers from `{projectKey}-{N}` pattern, increment max. Format as `{projectKey}-{N:03d}`.

```
1. Generate key (e.g. FEAT-007)
2. Determine folder: epics/, features/, bugs/, or refactors/
3. Create .claude/workspace/{folder}/{key}/
4. Write metadata.json
5. Write {key}-spec.md with description content
6. Show user: "Creating {key} at .claude/workspace/{folder}/{key}/ — confirm?"
7. Return { key, url: ".claude/workspace/{folder}/{key}/" }
```

metadata.json:
```json
{
  "key": "{key}",
  "type": "{type}",
  "title": "{summary}",
  "status": "pending",
  "assignee": null,
  "parent": "{parent or null}",
  "taskManager": { "synced": false },
  "created_at": "{ISO timestamp}",
  "updated_at": "{ISO timestamp}"
}
```

## update(ticketKey, fields)

```
1. Find ticket folder
2. Update metadata.json fields (title, assignee, status)
3. If description in fields: overwrite {ticketKey}-spec.md
4. Update metadata.json updated_at
```

## transition(ticketKey, targetStatus)

`targetStatus` is already resolved from `project.taskManager.config.statuses.*`.

```
1. Read metadata.json
2. Update status field to targetStatus
3. Append to {ticketKey}-log.md:
   "[{ISO timestamp}] Status → {targetStatus}"
4. Write updated metadata.json
```

## comment(ticketKey, body)

Append to `.claude/workspace/{folder}/{ticketKey}/{ticketKey}-log.md`:

```markdown
---
**[{ISO timestamp}]**

{body}
```

Create log file if it doesn't exist.

## assign(ticketKey, assignee)

```
1. Read metadata.json
2. Update assignee field
3. Write metadata.json
4. Append to log: "[{timestamp}] Assigned to {assignee}"
```

## link(ticketKey, destKey, linkType)

Update both tickets' metadata.json, adding to a `links` array:

```json
{
  "links": [
    { "type": "{linkType}", "target": "{destKey}" }
  ]
}
```

Also append to {ticketKey}-log.md:
```
[{timestamp}] Linked to {destKey} as "{linkType}"
```

## search(query)

```
1. List all metadata.json files in .claude/workspace/**/
2. Filter: title contains query (case-insensitive) OR status matches query
3. Return array of { key, summary, status, assignee }
```

## Key generation

```
1. Scan all .claude/workspace/**/ folder names
2. Extract numbers from names matching {projectKey}-{N} pattern
3. next = max(N) + 1, formatted as {projectKey}-{N:03d}
```

Example: existing FEAT-001, FEAT-002 → next is FEAT-003.

## Offline-first benefits

- No auth required. No setup. No vendor lock-in.
- Everything in git — full history, portable across machines.
- Works on a plane. Works when Jira is down (which is often).
