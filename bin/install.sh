#!/bin/bash
# install.sh — Kitt installer
#
# Run from your project root:
#   bash <(curl -fsSL https://raw.githubusercontent.com/bacleclement/kitt/main/bin/install.sh)
#
# What it does:
#   1. Installs (or updates) kitt globally to ~/.claude/kitt/
#   2. Sets up kitt in the current project (dirs, symlinks, templates)

set -e

KITT_REPO="https://github.com/bacleclement/kitt.git"
KITT_DIR="$HOME/.claude/kitt"
CLAUDE_DIR=".claude"

echo ""
echo "Kitt Installation"
echo "================="
echo ""

# Validate we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: Not a git repository. Run from your project root."
  exit 1
fi

# Step 1: Install or update kitt globally
if [ -d "$KITT_DIR/.git" ]; then
  echo "Step 1/5: Updating kitt at $KITT_DIR..."
  git -C "$KITT_DIR" pull --quiet
else
  echo "Step 1/5: Installing kitt to $KITT_DIR..."
  mkdir -p "$HOME/.claude"
  git clone "$KITT_REPO" "$KITT_DIR" --quiet
fi

KITT_VERSION=$(cat "$KITT_DIR/version" 2>/dev/null || echo "unknown")
echo "  Kitt version: $KITT_VERSION"

# Step 2: Create project directories
echo "Step 2/5: Creating project directories..."
mkdir -p "$CLAUDE_DIR/config"
mkdir -p "$CLAUDE_DIR/context"
mkdir -p "$CLAUDE_DIR/workspace/epics"
mkdir -p "$CLAUDE_DIR/workspace/features"
mkdir -p "$CLAUDE_DIR/workspace/bugs"
mkdir -p "$CLAUDE_DIR/workspace/refactors"

# Step 3: Create machine-local symlinks (gitignored)
echo "Step 3/5: Creating symlinks..."
ln -snf "$KITT_DIR/.claude/skills"   "$CLAUDE_DIR/skills"
ln -snf "$KITT_DIR/.claude/adapters" "$CLAUDE_DIR/adapters"

# Step 4: Copy CLAUDE.md template if not present
echo "Step 4/5: Copying CLAUDE.md template..."
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$KITT_DIR/.claude/templates/CLAUDE.md.template" "$CLAUDE_DIR/CLAUDE.md"
else
  echo "  (CLAUDE.md already exists, skipping)"
fi

# Step 5: Update .gitignore
echo "Step 5/5: Updating .gitignore..."
if ! grep -q "Kitt" .gitignore 2>/dev/null; then
  cat "$KITT_DIR/.claude/templates/.gitignore.append" >> .gitignore
fi

echo ""
echo "Kitt v$KITT_VERSION installed."
echo ""
echo "Open Claude Code in this project and run /setup"
echo ""
