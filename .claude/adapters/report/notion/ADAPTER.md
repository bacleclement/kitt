---
name: report-notion
implements: report-interface
tool: notion-mcp
version: 2.0
---

# Notion Report Adapter

Implements the report interface using Notion MCP tools.
Called once at the end of a QA run — reads the local run file, syncs to Notion.

## Prerequisites

- Notion MCP server connected in the Claude session
- `project.report.config.workspacePage` set in `kitt.json`

## Configuration

```json
{
  "report": {
    "type": "notion",
    "config": {
      "workspacePage": "notion-page-id"
    }
  }
}
```

---

## publish(runFilePath, context)

### Step 1 — Parse the run file

Read `runFilePath` and extract:
- Header metadata: title, date, status, reviewers
- Test data section: environment, URLs, params
- Scenarios table: all rows with their current status columns
- Summary line

### Step 2 — Find or create the QA page

1. `notion-fetch { id: workspacePage }` — scan child pages
2. Look for a page matching `context.specRef` or `context.title`
3. **Found** → use it (update mode)
4. **Not found** → create it:

   a. `notion-create-pages` under `workspacePage`:
   ```
   title: "{context.title}"
   ```

   b. `notion-create-database` inside the new page:

   **Frontend:**
   ```sql
   CREATE TABLE (
     "Scenario" TITLE,
     "Ticket" RICH_TEXT,
     "AI" SELECT('Not tested':gray, 'Pass':green, 'Fail':red, 'Blocked':orange),
     "AI Notes" RICH_TEXT,
     "Dev" SELECT('Not tested':gray, 'Pass':green, 'Fail':red, 'Blocked':orange),
     "Dev Notes" RICH_TEXT,
     "PM" SELECT('Pending':gray, 'Approved':green, 'Change requested':red, 'Needs clarification':yellow),
     "PM Notes" RICH_TEXT,
     "Design" SELECT('Pending':gray, 'Approved':green, 'Change requested':red, 'Needs clarification':yellow),
     "Design Notes" RICH_TEXT
   )
   ```

   **Backend:**
   ```sql
   CREATE TABLE (
     "Scenario" TITLE,
     "Ticket" RICH_TEXT,
     "AI" SELECT('Not tested':gray, 'Pass':green, 'Fail':red, 'Blocked':orange),
     "AI Notes" RICH_TEXT,
     "Dev" SELECT('Not tested':gray, 'Pass':green, 'Fail':red, 'Blocked':orange),
     "Dev Notes" RICH_TEXT
   )
   ```

### Step 3 — Sync scenarios

For each row in the run file scenarios table:

- **Row doesn't exist in Notion** → `notion-create-pages` with data_source_id parent
- **Row exists** → `notion-update-page` with updated properties

Match existing rows by Ticket + Scenario title (not by Notion page ID — avoids stale references).

Map emoji statuses from run file to Notion select values:
- `✅` → `"Pass"`
- `🔴` → `"Fail"`
- `🟠` → `"Blocked"`
- `⬜` → `"Not tested"`
- PM/Design empty → `"Pending"`

### Step 4 — Write the page content

`notion-update-page` with `replace_content`:

```markdown
> {emoji} **{status label}** — {pass}/{total} passed · {fail} failed · {blocked} blocked · {date}

## Test Data

- Environment: {env}
- Base URL: {url}
- {param}: {value}

## Scenarios

<database url="https://www.notion.so/{databaseId}" inline="true">

## Dev Notes

{dev notes section from run file}

## PM Notes

{pm notes section — "pending" if empty}

## Design Notes

{design notes section — "pending" if empty}
```

### Step 5 — Return

```json
{ "url": "https://www.notion.so/{pageId}" }
```

---

## Idempotency

- Same `specRef` → always updates the same Notion page (never creates a duplicate)
- Same scenario row → updates properties in place (never duplicates rows)
- Run `publish()` after partial run, then again after completion: only changed rows are updated
