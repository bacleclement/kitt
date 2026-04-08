---
name: design-figma
implements: design-interface
tool: mcp__figma__get_design_context (preferred) or Figma REST API (fallback)
version: 1.0
---

# Figma Design Adapter

Implements the design interface for Figma.
Two modes: MCP tool (preferred, no token needed) or REST API (fallback).

## Prerequisites

**Before using any Figma operation, run the connectivity check below.**

### Connectivity Check (REQUIRED before first use)

```
1. Check MCP tool availability:
   → Is mcp__figma__get_design_context available in this session?
   → YES: use MCP mode ✅
   → NO: fall through to step 2

2. Check FIGMA_TOKEN env var:
   → source .env.local 2>/dev/null; echo $FIGMA_TOKEN | grep -q . && echo "✅" || echo "❌"
   → SET: use REST API mode ✅
   → NOT SET: fall through to step 3

3. Neither available — show clear error:
   "❌ Figma is not accessible. Configure one of:

    Option A — Figma MCP (preferred, no token needed):
    Add to .claude/settings.json or ~/.claude/settings.json:
    {
      \"mcpServers\": {
        \"figma\": {
          \"command\": \"npx\",
          \"args\": [\"-y\", \"@figma/mcp-server\"]
        }
      }
    }
    Then restart Claude Code session.

    Option B — REST API fallback:
    1. Go to figma.com → Settings → Personal access tokens
    2. Create a token, add to .env.local:
       FIGMA_TOKEN=figd_xxxxxxxxxxxx"

   Do NOT proceed silently — stop and inform the user.
```

**Option A: Figma MCP (preferred)**

Configure in Claude Code settings (`~/.claude/settings.json` or project `.claude/settings.json`):

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@figma/mcp-server"]
    }
  }
}
```

Verify: MCP tool `mcp__figma__get_design_context` is available in your session.

**Option B: Figma REST API (fallback)**

```bash
echo $FIGMA_TOKEN | grep -q . && echo "✅ token set" || echo "❌ set FIGMA_TOKEN in .env.local"
```

Get token at: figma.com → Settings → Personal access tokens.

## Configuration (from kitt.json)

```json
{
  "design": {
    "type": "figma",
    "config": {
      "defaultFileKey": "abc123XYZ"
    }
  }
}
```

`defaultFileKey` is optional — skills can also receive fileKey inline from spec references.

## getContext(fileKey, nodeId)

**Via MCP (preferred):**

```
Call: mcp__figma__get_design_context
Args: { fileKey: "{fileKey}", nodeId: "{nodeId}" }
```

Returns CSS properties, spacing, colors, typography, component tree.

**Via REST API (fallback):**

```bash
source .env.local
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/{fileKey}/nodes?ids={nodeId}" \
  | jq '.nodes["{nodeId}"].document'
```

## list(fileKey, filter?)

```bash
source .env.local
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/{fileKey}" \
  | jq '[.document.children[] | select(.type == "FRAME") | {nodeId: .id, name: .name, type: .type}]'
```

With filter: pipe through `| select(.name | test("{filter}"; "i"))`

## export(fileKey, nodeId, format)

```bash
source .env.local
curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/images/{fileKey}?ids={nodeId}&format={format}" \
  | jq -r '.images["{nodeId}"]'
```

Returns URL. Download with curl.

## How plan-building uses this adapter

When a spec references Figma designs, plan-building:

```
1. Load design adapter (project.design.type)
2. For each UI task, add a "- **Design:** {fileKey}:{nodeId}" field
3. Implementor calls getContext() before implementing the component
4. Adapts returned CSS to project stack (MUI, Tailwind, etc.)
```

Figma references in specs:
```markdown
## Design References

| Component | File | Node |
|-----------|------|------|
| UserCard | abc123 | 45:67 |
```

## Finding nodeIds

From a Figma URL:
```
https://www.figma.com/file/abc123XYZ/MyDesign?node-id=45%3A67
                         ^^^^^^^^^^                   ^^^^^
                         fileKey                      nodeId (URL-decoded: 45:67)
```
