---
description: Generate this repo's GitHub issue templates and ticket-check workflow from the Kitt ticket-shape contract
---

Generate this repository's GitHub issue templates and ticket-check workflow from the Kitt ticket-shape contract.

Arguments (optional): `$ARGUMENTS` — may contain `--lang fr` or `--lang en` (default: infer from the repo's existing issues), and a list of types to activate (default: all five).

## What this does

The contract lives once, in the plugin: `${CLAUDE_PLUGIN_ROOT}/../../contracts/ticket-shape.md`. This command renders it into the client repo, where GitHub actually reads it:

```
.github/ISSUE_TEMPLATE/epic.yml · feature.yml · task.yml · bug.yml · refactor.yml
.github/ISSUE_TEMPLATE/config.yml          (blank_issues_enabled: false)
.github/workflows/check-ticket-shape.yml   (the gate)
```

Generated, never hand-edited. Regenerating an unchanged contract must produce an empty diff — that property is what keeps every repo in sync, so preserve it: no timestamps, no random ids, stable field order.

## Steps

1. **Read the contract** at `${CLAUDE_PLUGIN_ROOT}/../../contracts/ticket-shape.md`. It is the source of truth for types, fields and which are required.

2. **Detect the language** unless given. Read a handful of recent issues (`gh issue list --limit 10 --json title,body`) and follow the dominant one. Say which you picked.

3. **Check for drift before overwriting.** If `.github/ISSUE_TEMPLATE/` already exists, diff what you would generate against what is there. If a file differs and was hand-edited, **stop and show the difference** — do not silently overwrite someone's work. Ask whether the contract should change instead.

4. **Render the templates** as GitHub issue forms (`.yml`): one `textarea` or `input` per contract field, `validations: {required: true}` for the required ones, and the field label in the chosen language. Put the provenance line first in every type. Add the `cause:` dropdown on `bug` and `refactor`.

   The `task` type's acceptance-command field must make the expectation unmistakable in its placeholder — a real command, not a sentence.

5. **Render `config.yml`** with `blank_issues_enabled: false`.

6. **Render the workflow.** On `issues: opened` and `issues: edited`: infer the type from the issue's labels, check the required sections are present and non-empty, then either add `needs-detail` with a comment naming what is missing, or remove that label if it was there and the ticket is now complete. It must never close or edit the issue body.

7. **Report** the files written, the language, and — if the repo has open issues — how many of them would fail the check today. That number is the re-pass backlog; do not act on it here.

## Constraints

- Write only under `.github/`. This command does not touch source.
- Every template must survive `yamllint`-level validity; malformed YAML silently disables the template on GitHub, which looks exactly like it working.
- Do not invent fields that are absent from the contract. If a repo needs one, it belongs in the contract, for every repo.
