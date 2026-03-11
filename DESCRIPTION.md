# OpenClaw 3-Agent AI Company

A lean, 24/7 AI-powered business operation running on a Mac Mini M1.

## Agents

**Commander** — Reads Notion tasks via API, reads agent reports, decides priorities. Produces Morning Brief (3 actions for MT) and Evening Report. Never generates content.

**Growth Research** — Uses YouTube Data API and Brave Search API to mine YouTube channels/transcripts, Reddit viral posts, X threads, and TikTok trends. Produces weekly intel reports with 10 ideas and 5 experiments.

**Content & Distribution** — Turns research into TikTok scripts, Reddit posts, LinkedIn threads, email drafts, and creative plans. Everything marked "PR PENDING" for MT's approval. Never auto-publishes.

## Design

- 3 agents, sequential CRON, shared filesystem
- MiniMax or Gemini (user picks during setup)
- No heartbeats, no agent mesh, no communication loops
- One task per agent at a time
- All outputs are PRs for MT's approval

## What MT Wakes Up To

- 3 actionable decisions
- 5 ready-to-post scripts
- Bottleneck identified
- Next experiment defined
