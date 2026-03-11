#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_HOME="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_HOME/workspace"
OC="npx --yes openclaw"

# Load .env from project dir if it exists (auto-detect keys)
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

echo "============================================"
echo "  OpenClaw 4-Agent System — Setup"
echo "  Commander, Research, Content, Performance. CRON only."
echo "============================================"
echo ""

# --- Pre-flight ---

echo "[1/7] Checking prerequisites..."

if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js not found. brew install node"
  exit 1
fi

NODE_MAJOR=$(node -v | cut -d'.' -f1 | tr -d 'v')
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "ERROR: Node.js >= 22 required (found $(node -v))"
  exit 1
fi
echo "  Node.js $(node -v) — OK"

# --- LLM Selection ---

echo ""
echo "[2/7] Select LLM provider..."
echo ""
MINIMAX_STATUS="not set"
GEMINI_STATUS="not set"
OPENAI_STATUS="not set"
[ -n "${MINIMAX_API_KEY:-}" ] && MINIMAX_STATUS="key found"
[ -n "${GEMINI_API_KEY:-}" ] && GEMINI_STATUS="key found"
[ -n "${OPENAI_API_KEY:-}" ] && OPENAI_STATUS="key found"
echo "  1) MiniMax M2.1  (\$10-20/month — recommended) [$MINIMAX_STATUS]"
echo "  2) Google Gemini 2.5 Flash [$GEMINI_STATUS]"
echo "  3) OpenAI GPT-4o-mini (paid plan required) [$OPENAI_STATUS]"
echo ""

LLM_CHOICE=""
while [[ "$LLM_CHOICE" != "1" && "$LLM_CHOICE" != "2" && "$LLM_CHOICE" != "3" ]]; do
  read -rp "  Pick [1, 2, or 3]: " LLM_CHOICE
done

if [ "$LLM_CHOICE" = "1" ]; then
  LLM_NAME="MiniMax M2.1"
  LLM_MODEL="minimax/MiniMax-M2.1"
  if [ -n "${MINIMAX_API_KEY:-}" ]; then
    echo "  MiniMax API key — OK (from .env)"
  else
    read -rp "  MiniMax API key: " MINIMAX_API_KEY
    if [ -z "$MINIMAX_API_KEY" ]; then echo "  ERROR: required."; exit 1; fi
    echo "  MiniMax — OK"
  fi
elif [ "$LLM_CHOICE" = "2" ]; then
  LLM_NAME="Google Gemini 2.5 Flash"
  LLM_MODEL="google/gemini-2.5-flash"
  if [ -n "${GEMINI_API_KEY:-}" ]; then
    echo "  Gemini API key — OK (from .env)"
  else
    read -rp "  Gemini API key: " GEMINI_API_KEY
    if [ -z "$GEMINI_API_KEY" ]; then echo "  ERROR: required."; exit 1; fi
    echo "  Gemini — OK"
  fi
else
  LLM_NAME="OpenAI GPT-4o-mini"
  LLM_MODEL="openai/gpt-4o-mini"
  if [ -n "${OPENAI_API_KEY:-}" ]; then
    echo "  OpenAI API key — OK (from .env)"
  else
    read -rp "  OpenAI API key: " OPENAI_API_KEY
    if [ -z "$OPENAI_API_KEY" ]; then echo "  ERROR: required."; exit 1; fi
    echo "  OpenAI — OK"
  fi
fi

# --- Collect tokens ---

echo ""
echo "[3/7] Collecting API tokens..."

ask_optional() {
  local var_name="$1" label="$2"
  local current_val="${!var_name:-}"
  if [ -n "$current_val" ]; then
    echo "  $label — OK (from env)"
    return
  fi
  read -rp "  $label (Enter to skip): " current_val
  eval "$var_name='${current_val:-}'"
  if [ -n "$current_val" ]; then
    echo "  $label — OK"
  else
    echo "  $label — skipped"
  fi
}

echo ""
echo "  --- Commander (Notion) ---"
ask_optional NOTION_API_KEY "Notion API key"

echo ""
echo "  --- Research (YouTube + Brave) ---"
ask_optional YOUTUBE_API_KEY "YouTube Data API key"
ask_optional BRAVE_SEARCH_API_KEY "Brave Search API key"

echo ""
echo "  --- Content (OpenAI for image generation) ---"
ask_optional OPENAI_API_KEY "OpenAI API key (DALL-E images)"

echo ""
echo "  --- Performance (Stripe — read-only revenue/ads) ---"
ask_optional STRIPE_SECRET_KEY "Stripe secret key (sk_...)"

echo ""
echo "  --- Infrastructure (Telegram + Google) ---"
ask_optional TELEGRAM_BOT_TOKEN "Telegram bot token"
ask_optional TELEGRAM_CHAT_ID "Telegram chat ID"
ask_optional GOOGLE_CLIENT_ID "Google client ID (Gmail/Drive)"
ask_optional GOOGLE_CLIENT_SECRET "Google client secret"
ask_optional GOOGLE_REFRESH_TOKEN "Google refresh token"

# --- Install OpenClaw ---

echo ""
echo "[4/7] Installing OpenClaw..."
$OC --version 2>/dev/null && echo "  OpenClaw $($OC --version 2>/dev/null) — OK" || echo "  Installing on first run..."

# --- Create workspace + agent dirs ---

echo ""
echo "[5/7] Creating workspace..."

mkdir -p "$WORKSPACE/briefs" "$WORKSPACE/reports" "$WORKSPACE/tasks" "$WORKSPACE/content" "$WORKSPACE/memory"

# Initialize task registry if not present
if [ ! -f "$WORKSPACE/task-registry.json" ]; then
  echo '{"tasks":{}}' > "$WORKSPACE/task-registry.json"
  echo "  task-registry.json initialized"
fi

# Initialize Telegram offset if not present
if [ ! -f "$WORKSPACE/memory/telegram-offset.txt" ]; then
  echo "0" > "$WORKSPACE/memory/telegram-offset.txt"
  echo "  telegram-offset.txt initialized"
fi

AGENTS=("commander" "research" "content" "performance")

for agent in "${AGENTS[@]}"; do
  AGENT_DIR="$OPENCLAW_HOME/agents/$agent/agent"
  mkdir -p "$AGENT_DIR" "$OPENCLAW_HOME/agents/$agent/sessions"

  for file in SOUL.md AGENTS.md HEARTBEAT.md; do
    if [ -f "$SCRIPT_DIR/agents/$agent/$file" ]; then
      cp "$SCRIPT_DIR/agents/$agent/$file" "$AGENT_DIR/$file" 2>/dev/null || true
    fi
  done
  echo "  [$agent] ready"
done

# --- Deploy config ---

echo ""
echo "[6/7] Deploying config..."

mkdir -p "$OPENCLAW_HOME"
AUTH_TOKEN=$(openssl rand -hex 32)

sed -e "s/REPLACE_WITH_AUTH_TOKEN/$AUTH_TOKEN/" \
    -e "s|MODEL_PLACEHOLDER|$LLM_MODEL|" \
    "$SCRIPT_DIR/openclaw.json" > "$OPENCLAW_HOME/openclaw.json"

cat > "$OPENCLAW_HOME/.env" <<ENVEOF
MINIMAX_API_KEY=${MINIMAX_API_KEY:-}
GEMINI_API_KEY=${GEMINI_API_KEY:-}
NOTION_API_KEY=${NOTION_API_KEY:-}
YOUTUBE_API_KEY=${YOUTUBE_API_KEY:-}
BRAVE_SEARCH_API_KEY=${BRAVE_SEARCH_API_KEY:-}
OPENAI_API_KEY=${OPENAI_API_KEY:-}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN:-}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET:-}
GOOGLE_REFRESH_TOKEN=${GOOGLE_REFRESH_TOKEN:-}
STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY:-}
ENVEOF

echo "  Config deployed (LLM: $LLM_NAME)"
echo "  .env written with all tokens"

# --- Start gateway (no cron here — use cron-jobs.sh) ---

echo ""
echo "[7/7] Starting gateway..."

$OC gateway stop 2>/dev/null || true
sleep 2
$OC gateway &
sleep 5

echo ""
echo "============================================"
echo "  DONE — $LLM_NAME"
echo "============================================"
echo ""
echo "  Gateway is running."
echo "  To create cron jobs (once per machine), run:"
echo "    ./cron-jobs.sh"
echo ""
echo "  REAL-TIME (every 1 minute):"
echo "  task-watcher      → detects new Notion tasks instantly, dispatches high-priority"
echo "  telegram-listener → processes incoming Telegram messages as tasks or feedback"
echo "  urgent-research   → executes high-priority research, writes results to Notion"
echo "  urgent-content    → executes high-priority content, uploads to Drive + Notion"
echo ""
echo "  DAILY SCHEDULE (UTC):"
echo "  06:00  Performance → revenue snapshot (Stripe read-only)"
echo "  07:00  Research → morning scan (40-60 sources) → Notion summary page"
echo "  08:00  Commander → Morning Brief → Telegram report with suggested tasks"
echo "  13:00  Research → midday competitor scan → Notion competitor table"
echo "  14:00  Commander → midday check + task updates"
echo "  17:00  Research → evening trend scan → Notion trending hooks page"
echo "  18:00  Content → produce assets → Google Drive images → Notion content table"
echo "  21:00  Commander → Evening Report → Telegram summary"
echo ""
echo "  WEEKLY (Monday):"
echo "  05:00  Performance → Weekly Optimization Report (Kill/Scale/Fix/Test)"
echo "  06:00  Research → Deep Growth Intel Report (60+ sources) → Notion weekly page"
echo ""
echo "  Workspace: $WORKSPACE"
echo "  Auth token: $AUTH_TOKEN"
echo "  LLM: $LLM_NAME"
echo ""
echo "  npx openclaw agents list"
echo "  npx openclaw cron list"
echo "  npx openclaw agent --agent commander -m \"test\""
echo "============================================"
