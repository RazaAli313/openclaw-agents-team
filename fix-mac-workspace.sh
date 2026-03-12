#!/usr/bin/env bash
# fix-mac-workspace.sh — Cleans up v1 workspace leftovers on the Mac client
# Run from the project directory: bash fix-mac-workspace.sh

set -euo pipefail

OPENCLAW_HOME="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_HOME/workspace"

echo "============================================"
echo "  OpenClaw — Mac Workspace Fix"
echo "============================================"
echo ""
echo "Workspace: $WORKSPACE"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 1: Remove v1 agent files that don't belong in workspace
# ─────────────────────────────────────────────────────────────
echo "[1/6] Removing v1 agent files from workspace root..."

V1_FILES=(
  AGENTS.md SOUL.md HEARTBEAT.md BOOTSTRAP.md TOOLS.md
  USER.md IDENTITY.md
  health-check.md
  search_bing.py search_bing2.py search_brave.py search_ddg.py
  notion_api_key.txt notion_api_token.txt
  package.json package-lock.json
)

for f in "${V1_FILES[@]}"; do
  if [ -f "$WORKSPACE/$f" ]; then
    rm -f "$WORKSPACE/$f"
    echo "  removed: $f"
  fi
done

# Remove node_modules if present in workspace root
if [ -d "$WORKSPACE/node_modules" ]; then
  rm -rf "$WORKSPACE/node_modules"
  echo "  removed: node_modules/"
fi

# Remove old OpenClaw directory if present
if [ -d "$WORKSPACE/OpenClaw" ]; then
  rm -rf "$WORKSPACE/OpenClaw"
  echo "  removed: OpenClaw/"
fi

if [ -d "$WORKSPACE/OpenClaw Content" ]; then
  rm -rf "$WORKSPACE/OpenClaw Content"
  echo "  removed: OpenClaw Content/"
fi

echo "  Done."

# ─────────────────────────────────────────────────────────────
# Step 2: Fix misplaced flag files
# ─────────────────────────────────────────────────────────────
echo ""
echo "[2/6] Fixing misplaced flag files..."

mkdir -p "$WORKSPACE/tasks"

# Move flag files from workspace root to tasks/ if they exist
for flag in urgent-research.flag urgent-content.flag; do
  if [ -f "$WORKSPACE/$flag" ]; then
    mv "$WORKSPACE/$flag" "$WORKSPACE/tasks/$flag"
    echo "  moved: $flag → tasks/$flag"
  fi
done

echo "  Done."

# ─────────────────────────────────────────────────────────────
# Step 3: Merge nested workspace/workspace/ into workspace/
# ─────────────────────────────────────────────────────────────
echo ""
echo "[3/6] Merging nested workspace/workspace/ ..."

NESTED="$WORKSPACE/workspace"
if [ -d "$NESTED" ]; then
  # Copy files from nested workspace into parent, preserving newer versions
  for item in "$NESTED"/*/; do
    dir_name=$(basename "$item")
    if [ -d "$item" ]; then
      mkdir -p "$WORKSPACE/$dir_name"
      cp -rn "$item"* "$WORKSPACE/$dir_name/" 2>/dev/null || true
      echo "  merged dir: $dir_name/"
    fi
  done

  # Copy top-level files from nested workspace
  for f in "$NESTED"/*; do
    if [ -f "$f" ]; then
      fname=$(basename "$f")
      if [ ! -f "$WORKSPACE/$fname" ]; then
        cp "$f" "$WORKSPACE/$fname"
        echo "  merged file: $fname"
      fi
    fi
  done

  # Remove the nested workspace directory
  rm -rf "$NESTED"
  echo "  removed: nested workspace/ directory"
else
  echo "  No nested workspace/ found — skipped"
fi

echo "  Done."

# ─────────────────────────────────────────────────────────────
# Step 4: Remove old tasks.json (superseded by task-registry.json)
# ─────────────────────────────────────────────────────────────
echo ""
echo "[4/6] Cleaning up old file names..."

if [ -f "$WORKSPACE/tasks.json" ] && [ -f "$WORKSPACE/task-registry.json" ]; then
  rm -f "$WORKSPACE/tasks.json"
  echo "  removed: tasks.json (task-registry.json already exists)"
elif [ -f "$WORKSPACE/tasks.json" ] && [ ! -f "$WORKSPACE/task-registry.json" ]; then
  cp "$WORKSPACE/tasks.json" "$WORKSPACE/task-registry.json"
  rm -f "$WORKSPACE/tasks.json"
  echo "  renamed: tasks.json → task-registry.json"
fi

# Remove old notion-api-error.log if inside nested workspace (already merged or present)
rm -f "$WORKSPACE/notion-api-error.log" 2>/dev/null || true

echo "  Done."

# ─────────────────────────────────────────────────────────────
# Step 5: Ensure all required workspace structure exists
# ─────────────────────────────────────────────────────────────
echo ""
echo "[5/6] Ensuring correct workspace structure..."

mkdir -p \
  "$WORKSPACE/tasks" \
  "$WORKSPACE/memory" \
  "$WORKSPACE/briefs" \
  "$WORKSPACE/reports" \
  "$WORKSPACE/content"

# Initialize task registry if missing or malformed
if [ ! -f "$WORKSPACE/task-registry.json" ] || ! python3 -c "import json,sys; json.load(open('$WORKSPACE/task-registry.json'))" 2>/dev/null; then
  echo '{"tasks":{}}' > "$WORKSPACE/task-registry.json"
  echo "  task-registry.json initialized"
fi

# Initialize Telegram offset if missing
if [ ! -f "$WORKSPACE/memory/telegram-offset.txt" ]; then
  echo "0" > "$WORKSPACE/memory/telegram-offset.txt"
  echo "  memory/telegram-offset.txt initialized"
fi

# Create empty placeholder files so agents don't fail on first read
touch "$WORKSPACE/tasks/research-task.md" 2>/dev/null || true
touch "$WORKSPACE/tasks/content-task.md" 2>/dev/null || true
touch "$WORKSPACE/reports/research-latest.md" 2>/dev/null || true
touch "$WORKSPACE/reports/content-latest.md" 2>/dev/null || true
touch "$WORKSPACE/reports/performance-latest.md" 2>/dev/null || true

echo "  Done."

# ─────────────────────────────────────────────────────────────
# Step 6: Deploy updated v4 agent files
# ─────────────────────────────────────────────────────────────
echo ""
echo "[6/6] Deploying v4 agent files to ~/.openclaw/agents/ ..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

AGENTS=("commander" "research" "content" "performance")
for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$OPENCLAW_HOME/agents/$agent/agent"
  mkdir -p "$AGENT_DIR"

  for file in SOUL.md AGENTS.md HEARTBEAT.md; do
    if [ -f "$SCRIPT_DIR/agents/$agent/$file" ]; then
      cp "$SCRIPT_DIR/agents/$agent/$file" "$AGENT_DIR/$file"
    fi
  done
  echo "  [$agent] agent files deployed"
done

echo ""
echo "============================================"
echo "  Workspace fixed. Final structure:"
echo "============================================"
echo ""
ls -la "$WORKSPACE/"
echo ""
echo "tasks/:"
ls -la "$WORKSPACE/tasks/" 2>/dev/null || echo "  (empty)"
echo ""
echo "memory/:"
ls -la "$WORKSPACE/memory/" 2>/dev/null || echo "  (empty)"
echo ""
echo "============================================"
echo ""
echo "NEXT STEP — re-register cron jobs:"
echo "  cd '$SCRIPT_DIR'"
echo "  bash reset-crons.sh"
echo ""
echo "Then verify: npx openclaw cron list"
echo "============================================"
