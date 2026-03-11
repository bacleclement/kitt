#!/bin/bash
# kitt-setup.sh — Phase 1 of Kitt adoption
# Adds kitt as a git submodule and wires up symlinks + directory structure
#
# Usage (from your project root):
#   bash <(curl -fsSL https://raw.githubusercontent.com/bacleclement/kitt/main/bin/kitt-setup.sh)

set -e

KITT_REPO="https://github.com/bacleclement/kitt.git"
CLAUDE_DIR=".claude"

echo ""
echo "Kitt Installation"
echo "================="
echo ""

# Validate we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: Not a git repository. Run 'git init' first."
  exit 1
fi

# Check if already installed
if [ -f "$CLAUDE_DIR/config/project.json" ]; then
  echo "WARNING: Kitt appears to already be installed (.claude/config/project.json exists)."
  read -p "         Reinstall? (y/N) " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Step 1/5: Adding kitt as git submodule..."
if [ -d "$CLAUDE_DIR/kitt" ]; then
  echo "  (submodule already exists, skipping)"
else
  git submodule add "$KITT_REPO" "$CLAUDE_DIR/kitt"
  git submodule update --init --recursive
fi

KITT_VERSION=$(cat "$CLAUDE_DIR/kitt/version" 2>/dev/null || echo "unknown")
echo "  Kitt version: $KITT_VERSION"

echo "Step 2/5: Creating project-owned directories..."
mkdir -p "$CLAUDE_DIR/config"
mkdir -p "$CLAUDE_DIR/context"
mkdir -p "$CLAUDE_DIR/conductor/epics"
mkdir -p "$CLAUDE_DIR/conductor/features"
mkdir -p "$CLAUDE_DIR/conductor/bugs"
mkdir -p "$CLAUDE_DIR/conductor/refactors"

echo "Step 3/5: Creating symlinks..."
ln -sf "kitt/.claude/adapters" "$CLAUDE_DIR/adapters"

echo "Step 4/5: Copying CLAUDE.md template..."
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$CLAUDE_DIR/kitt/.claude/templates/CLAUDE.md.template" "$CLAUDE_DIR/CLAUDE.md"
else
  echo "  (CLAUDE.md already exists, skipping)"
fi

echo "Step 5/5: Updating .gitignore..."
if ! grep -q "Kitt" .gitignore 2>/dev/null; then
  cat "$CLAUDE_DIR/kitt/.claude/templates/.gitignore.append" >> .gitignore
fi

echo ""
echo "Kitt v$KITT_VERSION installed."
echo ""
echo "Next step: open Claude Code in this project and run /setup"
echo ""
