---
name: design-interface
version: 1.0
---

# Design Adapter Interface

All design adapters implement these operations.
Skills call this interface — never design tool APIs directly.

## How Skills Use Adapters

1. Read `.claude/config/kitt.json`
2. `type = project.design.type` → e.g. `"figma"`
3. Load `.claude/adapters/design/{type}/ADAPTER.md`
4. Follow the adapter's instructions for the needed operation

If `project.design` is not set → skip design context, proceed without it.

## Operations

### getContext(fileKey, nodeId)

Fetch design context for a specific component/frame.

Input:
- `fileKey` — file identifier (Figma: from URL `figma.com/file/{fileKey}/...`)
- `nodeId` — component/frame identifier (Figma: from URL `?node-id={nodeId}`)

Output:
```json
{
  "name": "ComponentName",
  "css": { "color": "#fff", "padding": "16px" },
  "spacing": { "top": 16, "right": 24, "bottom": 16, "left": 24 },
  "colors": ["#ffffff", "#1a1a1a"],
  "typography": { "fontFamily": "Inter", "fontSize": 14, "fontWeight": 500 },
  "children": [...]
}
```

### list(fileKey, filter?)

List available frames/components in a file.

Input:
- `fileKey` — design file identifier
- `filter?` — optional name filter

Output: array of `{ nodeId, name, type }`

### export(fileKey, nodeId, format)

Export a node as an asset.
`format` — `"png"`, `"svg"`, `"pdf"`

Returns: file path or base64 data.

## Stack Adaptation

Adapters return raw CSS/design values. Skills adapt them to the project stack:

| Stack | Adaptation |
|-------|-----------|
| MUI (React) | `padding: "16px 24px"` → `sx={{ px: 3, py: 2 }}` (8px base) |
| Tailwind | `color: #3b82f6` → `text-blue-500` |
| Svelte | use CSS custom properties directly |

The adapter returns raw values — the implementor adapts them.
