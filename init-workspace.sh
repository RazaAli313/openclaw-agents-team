#!/usr/bin/env bash
# init-workspace.sh — Run this on the Mac client to fix missing workspace files
# Usage: bash init-workspace.sh

set -euo pipefail

OPENCLAW_HOME="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_HOME/workspace"

echo "Initializing OpenClaw workspace at: $WORKSPACE"

# Create all required directories
mkdir -p \
  "$WORKSPACE/tasks" \
  "$WORKSPACE/memory" \
  "$WORKSPACE/briefs" \
  "$WORKSPACE/reports" \
  "$WORKSPACE/content"

echo "  Directories created"

# Initialize task registry if missing or empty
if [ ! -f "$WORKSPACE/task-registry.json" ] || [ ! -s "$WORKSPACE/task-registry.json" ]; then
  echo '{"tasks":{}}' > "$WORKSPACE/task-registry.json"
  echo "  task-registry.json created"
else
  echo "  task-registry.json already exists — skipped"
fi

# Initialize Telegram offset if missing
if [ ! -f "$WORKSPACE/memory/telegram-offset.txt" ]; then
  echo "0" > "$WORKSPACE/memory/telegram-offset.txt"
  echo "  telegram-offset.txt created"
else
  echo "  telegram-offset.txt already exists — skipped"
fi

# Create empty placeholder files so agents don't fail on first read
touch "$WORKSPACE/tasks/research-task.md" 2>/dev/null || true
touch "$WORKSPACE/tasks/content-task.md" 2>/dev/null || true
touch "$WORKSPACE/reports/research-latest.md" 2>/dev/null || true
touch "$WORKSPACE/reports/content-latest.md" 2>/dev/null || true
touch "$WORKSPACE/reports/performance-latest.md" 2>/dev/null || true

echo "  Placeholder files created"
echo ""
echo "Workspace layout:"
ls -la "$WORKSPACE/"
echo ""
ls -la "$WORKSPACE/tasks/"
echo ""
ls -la "$WORKSPACE/memory/"

echo ""
echo "Done. Workspace is ready."
echo ""
echo "Next steps on the Mac client:"
echo "  1. cd into the project directory (where cron-jobs.sh lives)"
echo "  2. Run: bash deploy-agents.sh   (push updated agent files)"
echo "  3. Run: bash reset-crons.sh     (re-register cron jobs with updated messages)"
