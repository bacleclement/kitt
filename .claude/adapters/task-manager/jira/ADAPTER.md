---
name: task-manager-jira
implements: task-manager-interface
cli: acli
version: 1.0
---

# Jira Adapter

Implements the task-manager interface for Atlassian Jira using `acli` (Atlassian CLI).

## Prerequisites

```bash
# Verify acli is installed and authenticated
acli jira workitem view <any-valid-key> --output-format json 2>/dev/null \
  && echo "✅ authenticated" || echo "❌ run: acli jira auth login"
```

If not authenticated: `acli jira auth login`

## Configuration (from project.json)

```json
{
  "taskManager": {
    "type": "jira",
    "config": {
      "instanceUrl": "https://your-team.atlassian.net",
      "projectKey": "PROJ",
      "statuses": {
        "todo":       "To Do",
        "inProgress": "In Progress",
        "review":     "In Review",
        "done":       "Done",
        "blocked":    "Blocked"
      }
    }
  }
}
```

## read(ticketKey)

```bash
acli jira workitem view {ticketKey} --output-format json
```

Parse output for: `key`, `summary`, `type`, `status`, `description`, `assignee`

## create(project, type, summary, description, parent?)

1. Search for duplicates first:
```bash
acli jira workitem search \
  --jql "project = {project} AND summary ~ \"{summary}\"" \
  --output-format json
```

2. If duplicate found: inform user, offer to update instead.

3. If no duplicate — write description to temp file as ADF JSON, then:
```bash
# Write ADF to temp file
cat > /tmp/tm-create-{timestamp}.json << 'EOF'
{
  "version": 1,
  "type": "doc",
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "{description}" }] }
  ]
}
EOF

acli jira workitem create \
  --project {project} \
  --type "{type}" \
  --summary "{summary}" \
  --body-file /tmp/tm-create-{timestamp}.json \
  [--parent {parent}]

# Cleanup
rm /tmp/tm-create-{timestamp}.json
```

## update(ticketKey, fields)

```bash
acli jira workitem update {ticketKey} \
  [--summary "{summary}"] \
  [--assignee "{assignee}"]
```

For description updates: use `--body-file` with ADF JSON (same pattern as create).

## transition(ticketKey, targetStatus)

`targetStatus` comes from `project.taskManager.config.statuses.*` — already resolved to Jira's actual string.

```bash
# Check current status first
acli jira workitem view {ticketKey} --output-format json | jq -r '.status'

# Transition (Jira may require intermediate steps)
acli jira workitem transition {ticketKey} --status "{targetStatus}"
```

If transition fails with "invalid transition": check current status and chain through required intermediate statuses. Common Jira chain: `To Do → In Progress → In Review → Done`.

## comment(ticketKey, body)

Write body as ADF JSON, post with acli:

```bash
cat > /tmp/tm-comment-{timestamp}.json << 'EOF'
{
  "version": 1,
  "type": "doc",
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "{body}" }] }
  ]
}
EOF

acli jira workitem comment create {ticketKey} \
  --body-file /tmp/tm-comment-{timestamp}.json

rm /tmp/tm-comment-{timestamp}.json
```

For rich content (links, bullet lists) — see ADF format guide below.

## assign(ticketKey, assignee)

```bash
# Check current assignee first
current=$(acli jira workitem view {ticketKey} --output-format json | jq -r '.assignee')

# Skip if already assigned to target
if [ "$current" != "{assignee}" ]; then
  acli jira workitem assign {ticketKey} --assignee "{assignee}"
fi
```

For `@me`: use your Jira account ID (found via `acli jira user whoami`).

## link(ticketKey, destKey, linkType)

```bash
acli jira workitem link {ticketKey} {destKey} --link-type "{linkType}"
```

Common link types: `Relates`, `Blocks`, `Cloners`, `Duplicate`

## search(query)

```bash
acli jira workitem search \
  --jql "{jql-query}" \
  --output-format json
```

Example JQL: `project = HUB AND status = "In Progress" AND assignee = currentUser()`

## ADF JSON Reference

### Simple text paragraph
```json
{ "version": 1, "type": "doc", "content": [
  { "type": "paragraph", "content": [{ "type": "text", "text": "Your text here" }] }
]}
```

### With hyperlink
```json
{ "version": 1, "type": "doc", "content": [
  { "type": "paragraph", "content": [
    { "type": "text", "text": "PR: " },
    { "type": "text", "text": "https://github.com/...",
      "marks": [{ "type": "link", "attrs": { "href": "https://github.com/..." } }] }
  ]}
]}
```

### Bullet list
```json
{ "version": 1, "type": "doc", "content": [
  { "type": "bulletList", "content": [
    { "type": "listItem", "content": [
      { "type": "paragraph", "content": [{ "type": "text", "text": "Item 1" }] }
    ]},
    { "type": "listItem", "content": [
      { "type": "paragraph", "content": [{ "type": "text", "text": "Item 2" }] }
    ]}
  ]}
]}
```
