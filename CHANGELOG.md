# Kitt Changelog

## v2.0.0 — 2026-08-17

**Rewrite.** Kitt becomes a small, standalone Claude Code plugin instead of an installed workflow engine.

### Added
- Four skills, no dependency on any app, server, env var or workspace layout: `prepare`, `implement`, `verify`, `finish`.
- The plan-execute-verify loop is closed: `verify` replays the ticket's runnable acceptance command and blocks on failure; `finish` refuses to open a PR on red.
- The harness loop: a failing check must produce a lesson — a regression test or a rule where the project already keeps its rules — under a strict no-regression requirement (a change that breaks a previously passing check is rejected).
- `prepare` validates the ticket against the repo's **own** `.github/ISSUE_TEMPLATE/` before planning, and offers to complete the missing required fields in place. The generated workflow only sees tickets opened or edited after it was installed, so this second gate is what makes an existing backlog converge as it is worked through.
- Grounding is an executed step, not a reading suggestion: `prepare` opens the sibling files, quotes the pattern, and stops when the ticket's approach disagrees with the code.
- The plan is written into the GitHub ticket, dated and tied to a commit SHA, and gated on human approval before any code.
- Ticket-shape contract in `contracts/`, with `/sync-ticket-templates` to generate GitHub issue templates and a check workflow into a repo.
- Distributed as a plugin marketplace (`/plugin marketplace add bacleclement/kitt`); project-scope install shares the loop with a team through `git pull`.

### Removed
- The 24-skill v1 engine (`/orchestrate`, `/setup`, `/refine`, `/align`, `/build-plan`, `/code-review`, `/debug`, the QA and session skills), the adapters, agent and template directories, and `bin/install.sh`.
- `kitt.json` as a required configuration: the skills read the project's own `AGENTS.md` / `CLAUDE.md` and whatever they point at.

The v1 engine lives on in [kitt-studio](https://github.com/bacleclement/kitt-studio) and in this repository's history.

## v1.0.0 — 2026-03-10

### Initial release

- Core workflow skills: workflow-orchestrator, refinement, architecture-alignment, plan-building, implementor, branch-creator, pr-creator
- Pluggable task-manager adapters: Jira, Linear, GitHub Issues
- Pluggable VCS adapters: GitHub, GitLab, Bitbucket
- Interactive setup wizard with repo scan + KITT personality
- Git submodule adoption model via kitt-setup.sh
