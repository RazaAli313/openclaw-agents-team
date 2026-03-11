# OpenClaw 4-Agent AI Company

**Founder: MT** | **Mac Mini M1 (8GB/256GB)** | **MiniMax, Gemini, or OpenAI**

Simple sequential 4-agent system. No heartbeats. No agent mesh. No communication loops. Everything runs on CRON. Commander → assigns → Research / Content / Performance. Performance → feeds Commander. No chaotic inter-agent looping.

## Agents

| # | Agent | API Tools | Does | Doesn't |
|---|-------|-----------|------|---------|
| 1 | **Commander** | Notion API | Reads tasks + all reports, writes briefs (2–3x/day), assigns all agents | Generate content, browse web |
| 2 | **Research** | YouTube API, Brave Search | Deep research 2–3x/day (90–120 sources/day) | Post or publish anything |
| 3 | **Content** | LLM + OpenAI DALL-E | Scripts, drafts, visuals, variations (daily) | Auto-publish, browse web |
| 4 | **Performance** | Stripe (read-only), optional ads/analytics | Revenue snapshot, Kill/Scale/Fix/Test (1x daily + weekly) | Change any external system, poll constantly |

## How It Works

```
Shared workspace (~/.openclaw/workspace/)
├── reports/          ← agents write reports here
│   ├── research-latest.md
│   ├── research-YYYY-MM-DD-{morning|midday|evening}.md
│   ├── content-latest.md
│   └── performance-latest.md   ← Performance (revenue insight)
├── tasks/            ← Commander writes assignments
│   ├── research-task.md
│   ├── content-task.md
│   └── performance-task.md
├── briefs/           ← Commander writes briefs
│   ├── YYYY-MM-DD-morning.md
│   ├── YYYY-MM-DD-midday.md
│   └── YYYY-MM-DD-evening.md
├── content/          ← Content agent writes drafts
├── memory/           ← Commander decision log
```

No inter-agent messaging. Agent A writes a file. Agent B reads it on its next CRON run.

## Schedule (UTC)

| Time | Agent | Task |
|------|-------|------|
| 06:00 | Performance | Revenue snapshot (Stripe read-only) |
| 07:00 | Research | Morning scan — 40–60 sources (YouTube + Brave) |
| 08:00 | Commander | Morning Brief — Notion + Performance + Research → 3 decisions, revenue insight |
| 13:00 | Research | Midday scan — competitor analysis, markets (30–40 sources) |
| 14:00 | Commander | Midday check — update priorities if urgent |
| 17:00 | Research | Evening scan — trending content (20–30 sources) |
| 18:00 | Content | Produce assets — 3–5 TikTok, 2–3 Reddit, LinkedIn, email, 1–2 images |
| 21:00 | Commander | Evening Report — full day review |
| Mon 05:00 | Performance | Weekly Optimization Report — Kill/Scale/Fix/Test |
| Mon 06:00 | Research | Weekly Growth Intel — 60+ sources, 5+ competitors |

10 CRON jobs. Morning: Performance + Research reports ready → Commander assigns focus. Evening: Content prepares assets.

## Setup

```bash
chmod +x setup.sh && ./setup.sh
```

Setup prompts for:
1. LLM choice (MiniMax, Gemini 2.5 Flash, or OpenAI GPT-4o-mini)
2. LLM API key (required)
3. Notion API key (Commander)
4. YouTube API key (Research)
5. Brave Search API key (Research)
6. OpenAI API key (Content — DALL-E images; reused if OpenAI chosen as LLM)
7. Stripe secret key (Performance — read-only revenue/ads; optional)
8. Telegram bot token + chat ID (optional)
9. Google OAuth credentials for Gmail/Drive (optional)

## What MT Wakes Up To (Final Objective)

- **3 actionable decisions** (Morning Brief)
- **5 ready-to-post scripts** (TikTok, Reddit, LinkedIn, email)
- **Clear revenue insight** (Performance: Kill/Scale/Fix/Test, MRR, bottleneck)
- **Bottleneck identified** (from Notion + reports)
- **Next experiment defined** (no noise, no fluff, no random content)

Plus: 90–120 research sources/day, 1–2 DALL-E visuals.

## Commands

```bash
npx openclaw agents list              # list agents
npx openclaw cron list                # list scheduled jobs
npx openclaw agent --agent commander -m "test"   # test agent
npx openclaw agent --agent performance -m "test" # test Performance (Stripe read-only)
npx openclaw gateway stop             # stop
npx openclaw gateway                  # start
npx openclaw stats                    # token usage
```

## File Structure

```
openclaw-agents/
├── openclaw.json          # config: 4 agents + model + cron
├── setup.sh               # one-command installer with LLM picker
├── .env.example
├── README.md
├── DESCRIPTION.md
└── agents/
    ├── commander/         # Notion API, briefs, task assignment
    │   ├── SOUL.md
    │   ├── AGENTS.md
    │   └── HEARTBEAT.md
    ├── research/          # YouTube API + Brave Search API
    │   ├── SOUL.md
    │   ├── AGENTS.md
    │   └── HEARTBEAT.md
    ├── content/           # LLM + DALL-E, scripts/drafts/visuals, PR only
    │   ├── SOUL.md
    │   ├── AGENTS.md
    │   └── HEARTBEAT.md
    └── performance/       # Stripe (read-only), revenue/ads, Kill/Scale/Fix/Test
        ├── SOUL.md
        ├── AGENTS.md
        └── HEARTBEAT.md
```

## Cost

| Provider | Cost |
|----------|------|
| MiniMax M2.1 | $10–20/month |
| Gemini 2.5 Flash | Free tier (rate limits) or paid |
| OpenAI GPT-4o-mini | Paid plan (per token) |
| OpenAI DALL-E (Content) | Per image |
| YouTube Data API | Free tier (10k queries/day) |
| Brave Search API | Free tier (2k queries/month) |
| Stripe API (Performance) | Read-only, no extra cost |
| OpenClaw | Free (MIT) |
