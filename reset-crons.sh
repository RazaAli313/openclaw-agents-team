#!/usr/bin/env bash
# Removes all existing OpenClaw cron jobs and re-registers them.
# Run this after updating agent files to apply the new job messages.
set -euo pipefail

OC="npx --yes openclaw"

JOBS=(
  "performance-daily"
  "research-morning"
  "commander-morning"
  "research-midday"
  "commander-midday"
  "research-evening"
  "content-afternoon"
  "commander-evening"
  "research-weekly"
  "performance-weekly"
  "task-watcher"
  "telegram-listener"
  "urgent-research"
  "urgent-content"
)

echo "Removing existing cron jobs..."
for job in "${JOBS[@]}"; do
  $OC cron rm "$job" 2>/dev/null && echo "  Removed: $job" || echo "  Not found (skipped): $job"
done

echo ""
echo "Re-registering all cron jobs..."
bash "$(dirname "$0")/cron-jobs.sh"
