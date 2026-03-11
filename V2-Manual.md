OpenClaw V2 — System Manual
============================

## What Changed from V1 to V2

V1 was a static, schedule-only system. Agents ran on a fixed cron schedule, wrote results to local markdown files, and had no way to interact in real time. Notion was read-only. There was no Telegram interaction, no Google Drive upload, and no feedback/iteration loop.

V2 rebuilds the system into a fully interactive multi-agent workflow.

---

## What V2 Does

### 3 Ways to Give Tasks

1. **Notion** — Create a task in the Notion Tasks database. Set Priority to High and it starts within 1 minute automatically.
2. **Telegram** — Message the bot directly. Commander reads it, routes it to the right agent, and confirms back.
3. **OpenClaw Dashboard Chat** — Type directly to Commander in the OpenClaw UI. Commander responds and dispatches the task.

### Agent Roles

**Commander (CEO)**
- Receives tasks from all 3 input channels
- Decides which agent handles each task (Research or Content)
- Creates the Notion result page before dispatching
- Tracks all tasks in a registry for iteration support
- Sends Telegram reports every morning and evening
- Handles feedback and re-runs agents on the same Notion page

**Research Agent**
- Searches YouTube, Reddit, X, TikTok, and the web via Brave Search
- After every task: creates a structured Notion page with a data table
- On iteration (feedback): appends a new section to the same page instead of creating a new one
- Handles both scheduled runs (autonomous daily research) and urgent on-demand tasks

**Content Agent**
- Writes scripts, hooks, posts, emails, and copy
- Generates images via DALL-E
- Downloads generated images and uploads to Google Drive "OpenClaw Content" folder
- Inserts the Google Drive shareable link into the Notion content table
- Creates a structured Notion page with all content assets after every task

### Priority Logic

| Priority | Behavior |
|----------|----------|
| High | Starts within 1 minute (urgent cron picks it up) |
| Medium | Queued for next scheduled daily run |
| Low | Queued for next scheduled daily run |

### Iteration / Feedback Loop

When you give feedback (e.g., "those APIs were too expensive, find cheaper ones"):
- Commander reads the task registry to find the Notion page from the original task
- Writes a new flag file with the same Notion page ID + your feedback
- Research or Content agent runs again and appends **Section 2 — Improved Results** to the same Notion page
- The original results stay. New results appear below. The page grows with each iteration.

---

## Files Changed

### Agent Files (identity + instructions)

| File | What Changed |
|------|-------------|
| `agents/commander/SOUL.md` | Complete rewrite — 4 run modes, interactive orchestrator role |
| `agents/commander/AGENTS.md` | Full rebuild — Notion write, task registry, Telegram 2-way, flag file dispatch, iteration workflow |
| `agents/research/SOUL.md` | Updated — Notion output mandatory, urgent mode added |
| `agents/research/AGENTS.md` | Added urgent flag detection, Notion page creation, structured table insertion, iteration (append sections), task status updates |
| `agents/content/SOUL.md` | Updated — Drive upload, Notion output mandatory, urgent mode added |
| `agents/content/AGENTS.md` | Added urgent flag detection, Google Drive auth + upload + shareable link, Notion content table, task status updates |

### Infrastructure Files

| File | What Changed |
|------|-------------|
| `cron-jobs.sh` | Added 4 new every-minute jobs: task-watcher, telegram-listener, urgent-research, urgent-content |
| `openclaw.json` | maxConcurrentRuns 1 → 4, added Telegram channel config with allowlist |
| `setup.sh` | Creates task-registry.json and telegram-offset.txt on first run |

### New Files

| File | Purpose |
|------|---------|
| `deploy-agents.sh` | Copies agent files to ~/.openclaw/agents/ without full re-setup. Run this after any agent file edit. |
| `reset-crons.sh` | Removes all old cron jobs and re-registers all 14 with updated messages. Run after deploy-agents.sh. |
| `V2-Manual.md` | This document. |

---

## Cron Schedule (14 Jobs Total)

### Real-Time (every minute)

| Job | Agent | What it does |
|-----|-------|-------------|
| task-watcher | Commander | Queries Notion for Pending tasks. High priority → writes flag file + updates status to Running |
| telegram-listener | Commander | Reads new Telegram messages. Routes as new tasks or feedback/iteration |
| urgent-research | Research | Checks for urgent-research.flag. If found: executes research, creates Notion page, deletes flag |
| urgent-content | Content | Checks for urgent-content.flag. If found: creates content, uploads to Drive, creates Notion page, deletes flag |

### Daily Schedule (UTC)

| Time | Agent | What it does |
|------|-------|-------------|
| 06:00 | Performance | Revenue snapshot from Stripe — Kill/Scale/Fix/Test bullets |
| 07:00 | Research | Morning scan — 40-60 sources (YouTube + Brave Search) → Notion summary page |
| 08:00 | Commander | Morning Brief → assigns tasks → sends Telegram morning report with suggested actions |
| 13:00 | Research | Midday competitor analysis — 30-40 sources → Notion competitor table |
| 14:00 | Commander | Midday check — updates task priorities if urgent opportunities found |
| 17:00 | Research | Evening trend scan — 20-30 sources → Notion trending hooks page |
| 18:00 | Content | Produces TikTok scripts, Reddit posts, LinkedIn threads, email drafts, DALL-E images → uploads to Drive → Notion content table |
| 21:00 | Commander | Evening Report → sends Telegram evening summary with tomorrow's suggested tasks |

### Weekly (Monday UTC)

| Time | Agent | What it does |
|------|-------|-------------|
| 05:00 | Performance | Weekly optimization report — full Kill/Scale/Fix/Test with LTV/churn analysis |
| 06:00 | Research | Deep growth intel — 60+ sources, 5+ competitors, top 10 ideas, 5 experiments |

---

## How Data Flows

```
MT gives task (Notion / Telegram / Chat)
        ↓
Commander (task-watcher or telegram-listener fires within 1 min)
        ↓
Commander creates Notion result page (page ID saved)
Commander writes flag file: tasks/urgent-research.flag or tasks/urgent-content.flag
Commander updates task status → Running
Commander saves to task-registry.json
Commander sends Telegram confirmation
        ↓
urgent-research or urgent-content fires within 1 min
        ↓
Agent reads flag file (gets task + Notion page ID)
Agent executes work (web research / content creation / image generation)
Agent uploads images to Google Drive if needed
Agent appends structured table to the Notion page
Agent deletes flag file
Agent updates task status → Complete
Agent updates task-registry.json
        ↓
Results appear in Notion
MT gets Telegram notification
```

### Iteration Flow

```
MT sends feedback ("too expensive, find cheaper")
        ↓
Commander reads task-registry.json → finds Notion page ID from original task
Commander writes new flag file with:
  - same NOTION_PAGE_ID (existing page)
  - ITERATION_NUM = 2
  - FEEDBACK = MT's message
        ↓
urgent-research fires within 1 min
Agent appends "Section 2 — Improved Results" to the SAME Notion page
Original results stay. New results below.
```

---

## File Structure at Runtime

```
~/.openclaw/
├── openclaw.json              ← gateway config (auth token, models, cron settings)
├── .env                       ← all API keys
├── agents/
│   ├── commander/agent/       ← SOUL.md, AGENTS.md, HEARTBEAT.md
│   ├── research/agent/        ← SOUL.md, AGENTS.md, HEARTBEAT.md
│   ├── content/agent/         ← SOUL.md, AGENTS.md, HEARTBEAT.md
│   └── performance/agent/     ← SOUL.md, AGENTS.md, HEARTBEAT.md
└── workspace/                 ← all agent working files
    ├── task-registry.json     ← maps task IDs to Notion page IDs (iteration tracking)
    ├── tasks/
    │   ├── urgent-research.flag   ← written by Commander, read+deleted by Research
    │   ├── urgent-content.flag    ← written by Commander, read+deleted by Content
    │   ├── research-task.md       ← daily scheduled research assignments
    │   └── content-task.md        ← daily scheduled content assignments
    ├── briefs/                ← Commander morning/midday/evening briefs
    ├── reports/               ← research-latest.md, content-latest.md, performance-latest.md
    ├── content/               ← content drafts (all PR PENDING)
    └── memory/
        ├── telegram-offset.txt    ← last processed Telegram update ID
        └── drive-folder-id.txt    ← cached Google Drive folder ID
```

---

## Notion Requirements

The Notion integration must have these 3 capabilities enabled:

- Read content ✓ (was already set)
- Insert content ✓ (new — needed to create result pages)
- Update content ✓ (new — needed to update task status)

To check: Notion → Settings → Connections → your OpenClaw integration → Edit → make sure all 3 are checked.

The Tasks database must have these columns for the system to work:

| Column | Type | Values |
|--------|------|--------|
| Name | Title | task description |
| Agent | Select | Commander / Research / Content |
| Priority | Select | High / Medium / Low |
| Status | Select | Pending / Queued / Running / Complete |
| Notes | Text | optional extra context for the agent |

---

## Quick Start

### First Time Setup (fresh machine)

```bash
# 1. Go to project folder
cd ~/Desktop/openclaw-agents   # Mac
# or
cd /c/Users/razaa/Downloads/openclaw/openclaw-agents-team   # Windows WSL

# 2. Make sure .env has all keys filled in (open it and check)
cat .env

# 3. Run setup (creates workspace, deploys config, starts gateway)
bash setup.sh
# Choose LLM: 1 = MiniMax, 2 = Gemini, 3 = OpenAI

# 4. Register all 14 cron jobs
bash cron-jobs.sh
```

Done. The system is live.

---

### After Updating Agent Files

Any time you edit SOUL.md, AGENTS.md, or HEARTBEAT.md:

```bash
# Deploy updated agent files
bash deploy-agents.sh

# Re-register cron jobs with updated messages (gateway must be running)
bash reset-crons.sh
```

---

### Start / Restart Gateway

```bash
# Start gateway (foreground — see all output live)
cd ~/.openclaw && npx openclaw gateway

# Start gateway (background — log to file)
cd ~/.openclaw && nohup npx openclaw gateway >> /tmp/openclaw-gateway.log 2>&1 &

# Watch live logs
tail -f /tmp/openclaw-gateway.log

# Check cron jobs
npx openclaw cron list
```

---

### Test the Full Flow (end to end)

**Test 1: Chat task**
Open OpenClaw dashboard → select Commander → type:
```
Find me 10 Veo3 API providers for my ecommerce SaaS
```
Commander should:
- Create a Notion result page
- Write urgent-research.flag
- Reply: "Task assigned to Research agent. Results will appear in Notion."

Within 1 minute: Research agent fires, searches web, creates Notion page with table.

**Test 2: Telegram task**
Send to your Telegram bot:
```
Find 5 AI image generation APIs with pricing under $50/month
```
Commander reads it within 1 minute → dispatches Research → results in Notion.

**Test 3: Notion task**
In Notion Tasks database → create new row:
- Name: `Find TikTok trends for CreaClips`
- Agent: `Research`
- Priority: `High`
- Status: `Pending`

Within 1 minute: task-watcher fires → Commander dispatches → Research runs → Notion page created.

**Test 4: Iteration**
After Test 1 completes → in chat or Telegram say:
```
The APIs you found are too expensive. Find providers under $10/month.
```
Commander reads task-registry.json → writes flag with same Notion page ID → Research appends Section 2 to existing page.

---

### Check What's Running

```bash
# See all 14 cron jobs and their next run times
npx openclaw cron list

# See recent agent sessions
npx openclaw sessions list

# Watch gateway live output
tail -f /tmp/openclaw-gateway.log
```

---

## Telegram Commands

Send these to your bot at any time:

| Message | What happens |
|---------|-------------|
| Any task description | Commander routes to Research or Content agent |
| Feedback on previous result | Commander iterates — appends to same Notion page |
| `/status` | Commander replies with all current task statuses from registry |

Morning and evening Telegram reports are sent automatically. Reply to suggested tasks to approve and start them.

---

## Known Limitations

- **Minimum detection time**: 1 minute (cron minimum — not truly instant, but as close as possible without heartbeats)
- **Telegram network errors**: If the server has no outbound internet to Telegram, the bot cannot send messages. Check network/firewall settings.
- **Notion workspace permissions**: Result pages are created as children of the same parent page as the Tasks database. If the integration does not have access to that parent page, page creation will fail. Fix by sharing the parent page with the integration.
- **DALL-E image URLs expire**: OpenAI image URLs expire after ~1 hour. The Content agent downloads and uploads to Google Drive immediately. If this step fails, the URL will be dead.
- **Google Drive**: First-time folder creation requires a valid Google refresh token with Drive scope. If the token is expired, re-generate it from Google OAuth Playground.
- **Heartbeats are disabled**: This is by design (client requirement). Agents only run on cron schedule. Interactive chat responses may take up to 1 minute to trigger agent execution.
