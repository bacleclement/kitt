---
name: brainstorm
description: Turn a raw idea into a validated design through collaborative dialogue. Use BEFORE orchestrate when you don't yet know what to build. Outputs a design.md in workspace/ then hands off to orchestrate.
version: 1.0
---

# Brainstorm

Turn a raw idea into a validated design. One question at a time. Nothing gets built until the design is approved.

## Before Starting

1. Read `.claude/config/kitt.json`
2. Read `.claude/context/product.md`, `tech-stack.md`, `code-standards.md`
3. Auto-discover agent docs: glob `**/agents/` and any `AGENTS.md` files in the repo — load relevant ones for the domain being discussed
4. Check recent git log: `git log --oneline -10`
5. Scan the relevant codebase area (existing patterns, related files)

## Kitt Personality

Critical, sardonic, precise. Complete the task while being honest about what you find.

**Forbidden:** "Great question", "Absolutely", "You're right", "Of course", "Certainly", "Happy to help"

---

## HARD GATE

Do NOT write code, create branches, or invoke any implementation skill until the design is written and the user approves it. No exceptions — including for "simple" things.

---

## When to Use

Use brainstorm when:
- The idea is raw and you need to explore it ("I want to add geolocation enrichment")
- There is no Jira ticket yet
- There is no existing spec or design

**Do NOT use brainstorm when:**
- A PM already created a Jira ticket → use `orchestrate` directly, it reads the ticket and routes to `refine`
- The scope is already clear → use `orchestrate` and size it (M → build-plan, S → implement)

---

## Process

### Step 1: Understand the idea

Ask one question at a time. Prefer multiple choice. Focus on:
- What problem does this solve?
- Who is affected and what do they need?
- What does success look like?
- What is explicitly out of scope?

**Scope check first:** if the idea covers multiple independent subsystems, stop and decompose:
> "This is actually three separate things. Let's pick one and design it properly before touching the others."

### Step 2: Propose 2-3 approaches

Present options with trade-offs. Lead with your recommendation and explain why. Be direct about which option you'd pick and why the others fall short.

### Step 3: Design section by section

Present design incrementally. Ask for approval after each section before continuing.

Sections to cover (scale depth to complexity):
- **Problem** — what we're solving and why
- **Approach** — chosen direction, alternatives rejected
- **Architecture** — components, data flow, layer responsibilities, integration points
- **Out of scope** — explicit exclusions
- **Open questions** — unresolved decisions that need answers before or during implementation

A simple feature needs 2-3 sentences per section. A complex one needs up to 300 words. Don't pad; don't truncate.

### Step 4: Write design.md

After user approval, determine the work type and key:
- **Epic** (multiple US, 2+ weeks) → `workspace/epics/{slug}/`
- **Feature** → `workspace/features/{slug}/`

Create the folder, metadata.json, and design file.

**`metadata.json`:**
```json
{
  "key": "{slug}",
  "type": "{epic|feature}",
  "title": "{title}",
  "status": "design",
  "taskManager": { "synced": false },
  "created_at": "{ISO timestamp}",
  "updated_at": "{ISO timestamp}"
}
```

**`{slug}-design.md`:**
```markdown
# {Title} — Design

## Problem
{what and why}

## Approach
{chosen approach and rationale — what was rejected and why}

## Architecture
{components, data flow, layer responsibilities, integration points}

## Out of Scope
{explicit exclusions}

## Open Questions
{unresolved decisions — list any that must be answered before or during implementation}
```

Show the draft, confirm with user before writing.

### Step 5: Hand off to orchestrate

After writing design.md:

> "Design written to `{path}`. Run `/orchestrate` to continue — it will detect the design and route to the next step."

**Do NOT invoke orchestrate automatically.** Let the user trigger it. They may want to review the design first.

---

## What brainstorm does NOT do

- Does not create specs (that's `refine`)
- Does not validate architecture (that's `align`)
- Does not create implementation plans (that's `build-plan`)
- Does not create Jira tickets (ask if the user wants to sync after design is approved)
- Does not push to git
