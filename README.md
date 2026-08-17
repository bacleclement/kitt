# Kitt

A small, standalone development loop for Claude Code. Four skills, driven by a GitHub ticket, with the plan-execute-verify cycle actually closed.

```
ticket → /prepare → (human approves) → /implement → /verify → /finish → PR
```

No app to run, no server, no configuration. A developer with a bare `claude` CLI and this plugin has the full loop.

## Why

A plan written from a ticket alone is a guess. An agent that writes code without reading the code next to it reproduces whatever it imagined the conventions were, and review pays for it — one recorded drift survived **14 commits with tests and verification both green** before a human caught it. Tests do not catch a design error; grounding at plan time prevents it.

So the loop puts the expensive gates where they are cheap:

| Skill | What it guarantees |
|---|---|
| **prepare** | The plan is grounded in the sibling code that already exists, written into the ticket, and approved by a human before any code. |
| **implement** | One step, one commit, one proof. A plan that turns out wrong stops the work instead of being silently renegotiated. |
| **verify** | The ticket's acceptance command is replayed **in this session**, and a failure blocks. A failure also has to teach something — a test or a rule — or it is wasted. |
| **finish** | The PR is only opened on green, linked to the ticket, written for the reviewer. |

## Install

```
/plugin marketplace add bacleclement/kitt
/plugin install kitt@kitt
```

Install it at **project scope** to share it with a team: the skills land in the repo's `.claude/`, get committed, and every developer has them after a `git pull` — no per-machine setup.

## Use

```
/prepare 412      # read the ticket, ground on the code, post the plan, stop
                  # → you read the plan and approve it
/implement        # execute it, one commit per step, ticking the ticket
/verify           # replay every acceptance command; blocks on failure
/finish           # push, open the PR linked to the ticket
```

## What the ticket must carry

`prepare` and `verify` read the ticket, so the ticket has to hold more than a title:

- **Acceptance criteria** — a yes/no list. Without it, nobody can say when the work is done.
- **A runnable acceptance command** — `pnpm test x.test.ts`, not "it works". This is what turns verification from a good intention into a gate.
- **Depends on** — what must land first.
- **Avoid** — the prohibitions specific to this work.

The [`contracts/`](contracts/) directory holds this shape and the generator that installs it into a repo as GitHub issue templates plus a check workflow — run `/sync-ticket-templates`.

## What this is not

This is not the full Kitt Studio. The Studio has its own richer skills, bound to its cockpit, its session journal and its workspace layout. **A skill that needs the Studio stays in the Studio; a skill that works without it lives here.** One implementation each — two copies of the same skill in two repos is the drift this repo exists to avoid.

## Design constraints

- No dependency on any app, MCP server, environment variable or workspace layout. `git`, `gh`, and the project's own commands.
- Each skill is a few hundred words. Context spent on the skill is context not spent on the work.
- Rules live where the project already keeps them — this plugin reads `AGENTS.md` / `CLAUDE.md` and whatever they point at, and never imposes its own file.

---

**v1 (the `/orchestrate` engine, 24 skills, `kitt.json`, adapters)** was removed in the V2 rewrite; it lives on in [kitt-studio](https://github.com/bacleclement/kitt-studio) and in this repo's history.
