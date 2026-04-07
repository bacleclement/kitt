---
name: report-interface
version: 2.0
---

# Report Adapter Interface

All report adapters implement these operations.
Skills call this interface — never report tool APIs directly.

## Architecture

The local run file (`qa-frontend-run.md` / `qa-backend-run.md`) is the **source of truth**.

```
Skill writes → qa-{type}-run.md  (live, after each scenario)
                      ↓
End of run → adapter.publish(runFilePath) → Notion / Confluence / stays local
```

The adapter is called **once at the end** — it reads the run file and generates its output format. It does not need to be called during the run.

## How Skills Use Adapters

1. Read `.claude/config/kitt.json`
2. `type = project.report.type` → e.g. `"notion"` or `"local"`
3. Load `.claude/adapters/report/{type}/ADAPTER.md`
4. Follow the adapter's instructions

If `project.report` is not set → fall back to `"local"` (run file stays in workspace, no publishing).

## kitt.json Schema

```json
{
  "report": {
    "type": "notion",
    "config": {
      "workspacePage": "notion-page-id-where-QA-docs-live"
    }
  }
}
```

---

## Run File Format

Both skills produce a markdown file at `{spec-path}/qa-{type}-run.md`.

### Frontend run file

```markdown
# QA Run — {title} (frontend)

Date: {ISO date}
Spec: {workspace path or Jira key}
Status: in_progress | completed | partial
Reviewers: dev | dev+pm | dev+pm+designer

---

## Test Data

- Environment: {env}
- Base URL: {url}
- {param}: {value}

---

## Scenarios

| # | Ticket | Scenario | AI | AI Notes | Dev | Dev Notes | PM | PM Notes | Design | Design Notes |
|---|--------|----------|----|----------|-----|-----------|----|----------|--------|--------------|
| 1 | HUB-XXX | Scenario title | ✅ | Works as expected | ⬜ | | ⬜ | | ⬜ | |

> ⬜ Not tested · ✅ Pass · 🔴 Fail · 🟠 Blocked
> AI filled by Claude. Dev / PM / Designer filled by humans.

---

## AI Notes
...

## Dev Notes
...

## PM Notes
...

## Design Notes
...

---

## Summary

Total: N · ✅ Pass: N · 🔴 Fail: N · 🟠 Blocked: N · ⬜ Not tested: N
Dev: completed | PM: pending | Design: pending
```

### Backend run file

Same structure with AI + Dev columns only — no PM / Design columns or sections.

---

## Operations

### publish(runFilePath, context)

Read the local run file and generate the adapter's output format.

Input:
```json
{
  "runFilePath": ".claude/workspace/epics/HUB-31234/.../qa-frontend-run.md",
  "context": {
    "title": "Jobs & Specialties — frontend",
    "specRef": "HUB-31234",
    "type": "qa-frontend | qa-backend",
    "reviewers": "dev | dev+pm | dev+pm+designer"
  }
}
```

The adapter:
1. Reads and parses the run file
2. Finds or creates a QA page/database for this `specRef`
3. Syncs all scenario rows (title, ticket, Dev status, Dev notes, PM/Design columns if applicable)
4. Writes the summary callout
5. Returns `{ url }` — the published report URL

**Idempotent** — calling publish multiple times (e.g., after a partial run and again after completion) updates existing rows rather than duplicating them. Match rows by `#` + `Ticket`.

### getRunFile(specPath, type)

Utility — returns the expected run file path for a given spec and type:

```
{specPath}/qa-{type}-run.md
```

Used by skills to check if a previous run exists (resume mode).
