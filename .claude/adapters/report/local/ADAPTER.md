---
name: report-local
implements: report-interface
version: 2.0
---

# Local Report Adapter

Implements the report interface by keeping the run file in place — no external publishing.

The run file IS the report. This adapter is the default when `project.report` is not set in `kitt.json`.

---

## publish(runFilePath, context)

1. Read `runFilePath` — verify it exists and is valid
2. Update `Status: completed` (or `partial`) in the file header if not already set
3. Ensure the Summary line reflects final counts
4. Return `{ url: runFilePath }` — the local path is the "report URL"

No external calls. No side effects beyond updating the run file itself.

---

## getRunFile(specPath, type)

```
{specPath}/qa-{type}-run.md
```

---

## When to use

- No Notion / Confluence configured
- Offline or air-gapped environment
- Dev-only run that doesn't need publishing
- Quick smoke test — file is enough

The run file is git-trackable. Commit it alongside the feature branch to keep a history of QA runs per feature.
