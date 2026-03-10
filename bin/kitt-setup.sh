#!/bin/bash
# kitt-setup.sh — Phase 1 of Kitt adoption
# Adds kitt as a git submodule and wires up symlinks + directory structure
#
# Usage: bash /path/to/kitt/bin/kitt-setup.sh [kitt-path]
# Default kitt path: ~/code/kitt

set -e

KITT_PATH="${1:-$HOME/code/kitt}"
CLAUDE_DIR=".claude"

echo ""
echo "🚗 Kitt Installation"
echo "===================="
echo ""

# Validate we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ Not a git repository. Run 'git init' first."
  exit 1
fi

# Validate kitt path exists
if [ ! -f "$KITT_PATH/version" ]; then
  echo "❌ Kitt not found at: $KITT_PATH"
  echo "   Pass the correct path: bash kitt-setup.sh /path/to/kitt"
  exit 1
fi

KITT_VERSION=$(cat "$KITT_PATH/version")
echo "Kitt version: $KITT_VERSION"
echo "Kitt path:    $KITT_PATH"
echo ""

# Check if already installed
if [ -f "$CLAUDE_DIR/config/project.json" ]; then
  echo "⚠️  Kitt appears to be already installed (.claude/config/project.json exists)."
  read -p "   Reinstall? (y/N) " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Step 1/6: Adding kitt as git submodule..."
if [ -d "$CLAUDE_DIR/kitt" ]; then
  echo "  (submodule already exists, skipping)"
else
  git submodule add "$KITT_PATH" "$CLAUDE_DIR/kitt"
  git submodule update --init --recursive
fi

echo "Step 2/6: Creating project-owned directories..."
mkdir -p "$CLAUDE_DIR/config"
mkdir -p "$CLAUDE_DIR/context"
mkdir -p "$CLAUDE_DIR/conductor/epics"
mkdir -p "$CLAUDE_DIR/conductor/features"
mkdir -p "$CLAUDE_DIR/conductor/bugs"
mkdir -p "$CLAUDE_DIR/conductor/refactors"

echo "Step 3/6: Creating symlinks..."
ln -sf "kitt/.claude/skills"   "$CLAUDE_DIR/skills"
ln -sf "kitt/.claude/adapters" "$CLAUDE_DIR/adapters"

echo "Step 4/6: Copying CLAUDE.md template..."
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$KITT_PATH/.claude/templates/CLAUDE.md.template" "$CLAUDE_DIR/CLAUDE.md"
else
  echo "  (CLAUDE.md already exists, skipping)"
fi

echo "Step 5/6: Updating .gitignore..."
if ! grep -q "Kitt" .gitignore 2>/dev/null; then
  cat "$KITT_PATH/.claude/templates/.gitignore.append" >> .gitignore
fi

echo "Step 6/6: Committing..."
git add "$CLAUDE_DIR/" .gitignore .gitmodules 2>/dev/null || true
git commit -m "chore: install kitt v$KITT_VERSION" 2>/dev/null || echo "  (nothing to commit)"

echo ""
echo "✅ Kitt installed successfully!"
echo ""
echo "Next step: Open Claude Code in this project and run /setup"
echo "KITT will scan your repo and configure everything."
echo ""
