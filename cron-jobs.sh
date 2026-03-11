#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OC="npx --yes openclaw"

# Load .env from project dir if it exists so TELEGRAM_CHAT_ID etc are available
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$SCRIPT_DIR/.env"
  set +a
fi

echo "============================================"
echo "  OpenClaw — Cron Jobs"
echo "============================================"
echo ""

# Configure delivery: prefer Telegram, otherwise disable delivery to avoid errors
DELIVERY_FLAGS=()
if [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "Using Telegram delivery → chat: $TELEGRAM_CHAT_ID"
  DELIVERY_FLAGS=(--announce --channel telegram --to="$TELEGRAM_CHAT_ID")
else
  echo "WARNING: TELEGRAM_CHAT_ID not set; cron jobs will not deliver (internal only)."
  DELIVERY_FLAGS=(--no-deliver)
fi

job_exists() {
  local name="$1"
  $OC cron list 2>/dev/null | awk 'NF > 1 {print $2}' | grep -qx "$name" || return 1
}

echo "Adding cron jobs (skipping any that already exist by name)..."

# ─────────────────────────────────────────────────────────────
# REAL-TIME TASK DETECTION (every 1 minute)
# These jobs run every minute so tasks are picked up almost instantly.
# ─────────────────────────────────────────────────────────────

if job_exists "task-watcher"; then
  echo "  * * * * * task-watcher — already exists, skipping"
else
  $OC cron add \
    --name "task-watcher" \
    --cron "* * * * *" --tz "UTC" \
    --session isolated --agent commander \
    --no-deliver \
    --message "TASK_WATCHER_MODE: Query Notion for ALL tasks with Status=Pending. For each Pending task: check workspace/task-registry.json to skip already-dispatched tasks. If Priority=High: (1) Update Notion status to Running, (2) Create a Notion result page titled with the task name, (3) Write the appropriate urgent flag file (urgent-research.flag for Research agent, urgent-content.flag for Content agent) with TASK_TITLE, NOTION_PAGE_ID, NOTION_TASK_ID, ITERATION_NUM=1, USER_INSTRUCTION from task Notes or title, FEEDBACK empty, (4) Update task-registry.json with the new entry, (5) Send Telegram notification. If Priority=Medium or Low: write to tasks/research-task.md or tasks/content-task.md only (no flag file), update Notion status to Queued. If no Pending tasks found, stop immediately." \
    2>/dev/null && echo "  * * * * * task-watcher — OK" || echo "  task-watcher — exists/failed"
fi

if job_exists "telegram-listener"; then
  echo "  * * * * * telegram-listener — already exists, skipping"
else
  $OC cron add \
    --name "telegram-listener" \
    --cron "* * * * *" --tz "UTC" \
    --session isolated --agent commander \
    --no-deliver \
    --message "TELEGRAM_LISTENER_MODE: Read workspace/memory/telegram-offset.txt to get the last processed update ID (default 0 if file missing). Call Telegram getUpdates API: curl -s 'https://api.telegram.org/bot\$TELEGRAM_BOT_TOKEN/getUpdates?offset=OFFSET&timeout=0'. Parse the response. For each new message from chat ID matching \$TELEGRAM_CHAT_ID: (1) If it looks like a new task (e.g. 'Find me X', 'Create content for Y', 'Research Z') — create a Notion result page, write the appropriate urgent flag file, update task-registry.json, send Telegram confirmation. (2) If it looks like feedback/iteration (e.g. 'too expensive', 'add more', 'redo this') — read task-registry.json to find most recent matching task, write iteration flag file with existing NOTION_PAGE_ID and incremented ITERATION_NUM and the FEEDBACK text, send confirmation. (3) If it is /status — read task-registry.json and reply with current task statuses. Save the highest update_id + 1 to workspace/memory/telegram-offset.txt. If no new messages, stop immediately." \
    2>/dev/null && echo "  * * * * * telegram-listener — OK" || echo "  telegram-listener — exists/failed"
fi

if job_exists "urgent-research"; then
  echo "  * * * * * urgent-research — already exists, skipping"
else
  $OC cron add \
    --name "urgent-research" \
    --cron "* * * * *" --tz "UTC" \
    --session isolated --agent research \
    --no-deliver \
    --message "URGENT_MODE: First check if workspace/tasks/urgent-research.flag exists. If it does NOT exist, stop immediately — do nothing else. If it DOES exist: source the flag file to get TASK_TITLE, NOTION_PAGE_ID, NOTION_TASK_ID, ITERATION_NUM, USER_INSTRUCTION, FEEDBACK. Execute research based on USER_INSTRUCTION using YouTube API and Brave Search. If FEEDBACK is not empty, focus the research on addressing the feedback. Collect real data. Then: if NOTION_PAGE_ID is empty, create a new Notion page titled TASK_TITLE. If NOTION_PAGE_ID is set, append a new section (Section ITERATION_NUM) to that existing page. Add a structured table with your research results to the Notion page. Delete workspace/tasks/urgent-research.flag. Update workspace/task-registry.json status to complete. If NOTION_TASK_ID is a valid UUID, update Notion task status to Complete." \
    2>/dev/null && echo "  * * * * * urgent-research — OK" || echo "  urgent-research — exists/failed"
fi

if job_exists "urgent-content"; then
  echo "  * * * * * urgent-content — already exists, skipping"
else
  $OC cron add \
    --name "urgent-content" \
    --cron "* * * * *" --tz "UTC" \
    --session isolated --agent content \
    --no-deliver \
    --message "URGENT_MODE: First check if workspace/tasks/urgent-content.flag exists. If it does NOT exist, stop immediately — do nothing else. If it DOES exist: source the flag file to get TASK_TITLE, NOTION_PAGE_ID, NOTION_TASK_ID, ITERATION_NUM, USER_INSTRUCTION, FEEDBACK. Execute the content task based on USER_INSTRUCTION. If image generation is needed: generate with DALL-E, download the image, upload to Google Drive 'OpenClaw Content' folder (use cached folder ID from workspace/memory/drive-folder-id.txt or create folder if needed), get shareable link. Then: if NOTION_PAGE_ID is empty, create a new Notion page titled TASK_TITLE. If NOTION_PAGE_ID is set, append new section to that page. Add a structured content table (with Google Drive links for images) to the Notion page. Delete workspace/tasks/urgent-content.flag. Update workspace/task-registry.json status to complete. If NOTION_TASK_ID is a valid UUID, update Notion task status to Complete." \
    2>/dev/null && echo "  * * * * * urgent-content — OK" || echo "  urgent-content — exists/failed"
fi

# ─────────────────────────────────────────────────────────────
# SCHEDULED AUTONOMOUS RUNS (daily)
# ─────────────────────────────────────────────────────────────

if job_exists "performance-daily"; then
  echo "  06:00 performance-daily — already exists, skipping"
else
  $OC cron add \
    --name "performance-daily" \
    --cron "0 6 * * *" --tz "UTC" \
    --session isolated --agent performance \
    "${DELIVERY_FLAGS[@]}" \
    --message "Read tasks/performance-task.md. Pull Stripe data (balance, subscriptions, charges) if STRIPE_SECRET_KEY set. Write revenue snapshot and Kill/Scale/Fix/Test bullets to reports/performance-latest.md. No emotional decisions — cite metrics only." \
    2>/dev/null && echo "  06:00 performance-daily — OK" || echo "  performance-daily — exists/failed"
fi

if job_exists "research-morning"; then
  echo "  07:00 research-morning — already exists, skipping"
else
  $OC cron add \
    --name "research-morning" \
    --cron "0 7 * * *" --tz "UTC" \
    --session isolated --agent research \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_MODE: Read workspace/tasks/research-task.md. If no flag file exists (check workspace/tasks/urgent-research.flag — if it exists, stop and let urgent-research handle it). Run deep YouTube research (20 results per query, pull stats). Run Brave Search on Reddit + X + TikTok (10 results each). Analyze 40-60 sources total. Write findings to workspace/reports/research-YYYY-MM-DD-morning.md and update workspace/reports/research-latest.md. Then create a Notion summary page titled 'Morning Research — YYYY-MM-DD' with a table of key findings." \
    2>/dev/null && echo "  07:00 research-morning — OK" || echo "  research-morning — exists/failed"
fi

if job_exists "commander-morning"; then
  echo "  08:00 commander-morning — already exists, skipping"
else
  $OC cron add \
    --name "commander-morning" \
    --cron "0 8 * * *" --tz "UTC" \
    --session isolated --agent commander \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_BRIEF: Morning report. Query Notion API for all current tasks (Pending, Running, Complete). Read workspace/reports/research-latest.md, workspace/reports/content-latest.md, and workspace/reports/performance-latest.md. Identify bottlenecks. Write Morning Brief to workspace/briefs/YYYY-MM-DD-morning.md with 3 actionable decisions for MT. Write task assignments to workspace/tasks/research-task.md and workspace/tasks/content-task.md. Send morning Telegram report to MT with: completed work summary, top 3 actions for today, and 2-3 suggested tasks MT can approve by replying." \
    2>/dev/null && echo "  08:00 commander-morning — OK" || echo "  commander-morning — exists/failed"
fi

if job_exists "research-midday"; then
  echo "  13:00 research-midday — already exists, skipping"
else
  $OC cron add \
    --name "research-midday" \
    --cron "0 13 * * *" --tz "UTC" \
    --session isolated --agent research \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_MODE: Read workspace/tasks/research-task.md. Focus on competitor analysis and market expansion. Search for competitor apps, pricing gaps, new markets, language opportunities. Analyze 30-40 sources. Append findings to workspace/reports/research-YYYY-MM-DD-midday.md and update workspace/reports/research-latest.md. Create or update a Notion page with competitor analysis table." \
    2>/dev/null && echo "  13:00 research-midday — OK" || echo "  research-midday — exists/failed"
fi

if job_exists "commander-midday"; then
  echo "  14:00 commander-midday — already exists, skipping"
else
  $OC cron add \
    --name "commander-midday" \
    --cron "0 14 * * *" --tz "UTC" \
    --session isolated --agent commander \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_BRIEF: Quick midday check. Read workspace/reports/research-latest.md for new findings. If urgent opportunities found, update workspace/tasks/content-task.md with priority items. Write brief status to workspace/briefs/YYYY-MM-DD-midday.md." \
    2>/dev/null && echo "  14:00 commander-midday — OK" || echo "  commander-midday — exists/failed"
fi

if job_exists "research-evening"; then
  echo "  17:00 research-evening — already exists, skipping"
else
  $OC cron add \
    --name "research-evening" \
    --cron "0 17 * * *" --tz "UTC" \
    --session isolated --agent research \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_MODE: Read workspace/tasks/research-task.md. Final scan: trending content from today, viral posts from last 24h, new hooks and emotional triggers. Analyze 20-30 sources. Write to workspace/reports/research-YYYY-MM-DD-evening.md and update workspace/reports/research-latest.md with full day summary. Create Notion page with trending hooks table." \
    2>/dev/null && echo "  17:00 research-evening — OK" || echo "  research-evening — exists/failed"
fi

if job_exists "content-afternoon"; then
  echo "  18:00 content-afternoon — already exists, skipping"
else
  $OC cron add \
    --name "content-afternoon" \
    --cron "0 18 * * *" --tz "UTC" \
    --session isolated --agent content \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_MODE: Read workspace/tasks/content-task.md and workspace/reports/research-latest.md. Generate: 3+ TikTok hook scripts, 2 Reddit posts, 1 LinkedIn thread, 1 email draft. Create 2 variations of best hooks. Generate 1-2 DALL-E images: download each, upload to Google Drive 'OpenClaw Content' folder, get shareable links. Write all content to workspace/content/ directory. Create a Notion page titled 'Content Batch — YYYY-MM-DD' with a table of all produced assets including Google Drive links for images. Write detailed summary to workspace/reports/content-latest.md. Mark everything PR PENDING." \
    2>/dev/null && echo "  18:00 content-afternoon — OK" || echo "  content-afternoon — exists/failed"
fi

if job_exists "commander-evening"; then
  echo "  21:00 commander-evening — already exists, skipping"
else
  $OC cron add \
    --name "commander-evening" \
    --cron "0 21 * * *" --tz "UTC" \
    --session isolated --agent commander \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_BRIEF: Evening report. Review all workspace/reports/ from today. Tally: sources analyzed, content pieces produced, Notion pages created, images generated. Write Evening Report to workspace/briefs/YYYY-MM-DD-evening.md. Update workspace/tasks/research-task.md and workspace/tasks/content-task.md with refined keywords and priorities for tomorrow. Send Telegram evening report to MT: day summary, what was completed, suggested tasks for tomorrow with instructions to reply to approve." \
    2>/dev/null && echo "  21:00 commander-evening — OK" || echo "  commander-evening — exists/failed"
fi

if job_exists "research-weekly"; then
  echo "  Mon 06:00 research-weekly — already exists, skipping"
else
  $OC cron add \
    --name "research-weekly" \
    --cron "0 6 * * 1" --tz "UTC" \
    --session isolated --agent research \
    "${DELIVERY_FLAGS[@]}" \
    --message "SCHEDULED_MODE: Compile Weekly Growth Intel Report. Deep dive: top 10 ideas to test, full competitor teardown (5+ competitors), 5 experiments to launch, market expansion opportunities (3+ new markets/languages). Pull 60+ sources across YouTube, Reddit, X, TikTok. Write to workspace/reports/research-weekly-YYYY-MM-DD.md. Create a Notion page titled 'Weekly Intel — YYYY-MM-DD' with all findings in structured tables." \
    2>/dev/null && echo "  Mon 06:00 research-weekly — OK" || echo "  research-weekly — exists/failed"
fi

if job_exists "performance-weekly"; then
  echo "  Mon 05:00 performance-weekly — already exists, skipping"
else
  $OC cron add \
    --name "performance-weekly" \
    --cron "0 5 * * 1" --tz "UTC" \
    --session isolated --agent performance \
    "${DELIVERY_FLAGS[@]}" \
    --message "Compile Weekly Optimization Report. Pull Stripe (and any configured ad/analytics) data. Output: Kill this, Scale this, Fix this, Test this. Revenue snapshot, LTV/churn signals, funnel drop-off, ad CPA/CTR. Write to workspace/reports/performance-weekly-YYYY-MM-DD.md and update workspace/reports/performance-latest.md." \
    2>/dev/null && echo "  Mon 05:00 performance-weekly — OK" || echo "  performance-weekly — exists/failed"
fi

echo ""
echo "Done. To review: npx openclaw cron list"
echo ""
echo "Real-time jobs running every minute:"
echo "  task-watcher     — Detects new Notion tasks instantly"
echo "  telegram-listener — Processes incoming Telegram messages"
echo "  urgent-research   — Executes high-priority research tasks"
echo "  urgent-content    — Executes high-priority content tasks"
