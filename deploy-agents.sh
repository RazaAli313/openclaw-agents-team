#!/usr/bin/env bash
# Copies updated agent files to the deployed location without full re-setup.
# Run this after editing any SOUL.md, AGENTS.md, or HEARTBEAT.md file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_HOME="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_HOME/workspace"

echo "Deploying updated agent files..."

AGENTS=("commander" "research" "content" "performance")

for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$OPENCLAW_HOME/agents/$agent/agent"
  mkdir -p "$AGENT_DIR"

  for file in SOUL.md AGENTS.md HEARTBEAT.md; do
    if [ -f "$SCRIPT_DIR/agents/$agent/$file" ]; then
      cp "$SCRIPT_DIR/agents/$agent/$file" "$AGENT_DIR/$file"
      echo "  [$agent] $file — deployed"
    fi
  done
done

# Ensure workspace subdirs exist
mkdir -p "$WORKSPACE/briefs" "$WORKSPACE/reports" "$WORKSPACE/tasks" "$WORKSPACE/content" "$WORKSPACE/memory"

# Initialize task registry if missing
if [ ! -f "$WORKSPACE/task-registry.json" ]; then
  echo '{"tasks":{}}' > "$WORKSPACE/task-registry.json"
  echo "  task-registry.json — created"
fi

# Initialize Telegram offset if missing
if [ ! -f "$WORKSPACE/memory/telegram-offset.txt" ]; then
  echo "0" > "$WORKSPACE/memory/telegram-offset.txt"
  echo "  telegram-offset.txt — created"
fi

echo ""
echo "Done. Agent files deployed to $OPENCLAW_HOME/agents/"
echo ""
echo "Next step — apply updated cron job messages:"
echo "  bash reset-crons.sh"
