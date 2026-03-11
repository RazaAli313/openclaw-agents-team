# Research — Operating Instructions

## Environment Variables

REAL environment variables in your shell — reference exactly as written:

- `$YOUTUBE_API_KEY` — Google YouTube Data API key
- `$BRAVE_SEARCH_API_KEY` — Brave Search subscription token
- `$NOTION_API_KEY` — Notion integration token

---

## STEP 1 — DETECT RUN MODE

**Check for urgent flag first:**

```bash
cat tasks/urgent-research.flag 2>/dev/null
```

- **If the flag file EXISTS** → you are in URGENT MODE. Read the flag file to get your task. Follow "Urgent Mode" flow below.
- **If the flag file does NOT exist** → you are in SCHEDULED MODE. Read `tasks/research-task.md` for your assignment. Follow "Scheduled Mode" flow below.

---

## URGENT MODE — On-Demand Task Execution

When `tasks/urgent-research.flag` exists:

### Parse the flag file

Source the flag file to get variables:
```bash
source tasks/urgent-research.flag
```

This gives you:
- `$TASK_TITLE` — the page title for Notion
- `$NOTION_PAGE_ID` — if set: append to this page. If empty: create new page.
- `$NOTION_TASK_ID` — the Notion task entry to update status on
- `$ITERATION_NUM` — which iteration this is (1 = first, 2+ = adding sections)
- `$USER_INSTRUCTION` — the original user request
- `$FEEDBACK` — user's feedback (empty on first run, filled on iterations)

### Execute research based on USER_INSTRUCTION

Use the APIs below (YouTube + Brave Search) to execute the research requested. The USER_INSTRUCTION tells you exactly what to find. Apply your full research capability.

For task types:
- **API discovery** ("find Veo3 APIs", "find tools for X"): search web + product directories for providers, extract name/website/pricing/features
- **Competitor research** ("find competitors of X"): search for apps, compare features, pricing, positioning
- **Trend research** ("what's trending in X"): Reddit, YouTube, X.com searches
- **SaaS ideas** ("find new SaaS ideas"): Reddit, forums, niche searches

### Write to Notion

See the "NOTION WRITE — Research Results" section below. This is mandatory.

### Delete flag file when done

```bash
rm tasks/urgent-research.flag
```

### Update task-registry.json

```bash
cat task-registry.json 2>/dev/null
```

Read it, find the entry matching `$NOTION_TASK_ID`, update its status to "complete" and save the `notion_page_id` if you created a new page. Write back the full updated JSON.

### Update Notion task status to Complete

```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/$NOTION_TASK_ID" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"properties":{"Status":{"select":{"name":"Complete"}}}}'
```

(Only run this if NOTION_TASK_ID is a valid UUID, not a chat-timestamp.)

---

## SCHEDULED MODE — Regular Cron Research

Read `tasks/research-task.md` for the assignment from Commander. Execute research as instructed. Write to local reports. Also create a Notion summary page for the day's findings.

---

## RESEARCH EXECUTION

### YouTube API

Search for videos:
```bash
curl -s "https://www.googleapis.com/youtube/v3/search?part=snippet&q=KEYWORDS&type=video&maxResults=20&key=$YOUTUBE_API_KEY"
```

Get video details:
```bash
curl -s "https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=VIDEO_ID&key=$YOUTUBE_API_KEY"
```

Get channel info:
```bash
curl -s "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=CHANNEL_ID&key=$YOUTUBE_API_KEY"
```

### Brave Search API

General web search:
```bash
curl -s "https://api.search.brave.com/res/v1/web/search?q=KEYWORDS&count=20" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: $BRAVE_SEARCH_API_KEY"
```

Search Reddit:
```bash
curl -s "https://api.search.brave.com/res/v1/web/search?q=site%3Areddit.com+KEYWORDS&count=10" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: $BRAVE_SEARCH_API_KEY"
```

Search X/Twitter:
```bash
curl -s "https://api.search.brave.com/res/v1/web/search?q=site%3Ax.com+KEYWORDS&count=10" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: $BRAVE_SEARCH_API_KEY"
```

Search TikTok:
```bash
curl -s "https://api.search.brave.com/res/v1/web/search?q=site%3Atiktok.com+KEYWORDS&count=10" \
  -H "Accept: application/json" \
  -H "X-Subscription-Token: $BRAVE_SEARCH_API_KEY"
```

REMEMBER: Keep `$YOUTUBE_API_KEY` and `$BRAVE_SEARCH_API_KEY` exactly as written.

---

## NOTION WRITE — Research Results

This is MANDATORY after every research run. All results must go to Notion.

### Case A: New Research (NOTION_PAGE_ID is empty or this is a scheduled run)

First create a page:

```bash
PAGE_RESULT=$(curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"parent\":{\"type\":\"workspace\",\"workspace\":true},\"properties\":{\"title\":{\"title\":[{\"type\":\"text\",\"text\":{\"content\":\"$TASK_TITLE\"}}]}}}")
echo "$PAGE_RESULT"
```

Extract the `id` from the response — save it as NEW_PAGE_ID.

Then append results blocks (Section 1 heading + table) to the page — see "Appending Blocks" below.

### Case B: Iteration (NOTION_PAGE_ID is already set)

Do NOT create a new page. Append a new section directly to the existing page:

```bash
# PAGE_ID = $NOTION_PAGE_ID from the flag file
# Append Section N heading + new results table to the existing page
```

See "Appending Blocks" below. Use `$NOTION_PAGE_ID` as the PAGE_ID.

---

## APPENDING BLOCKS TO A NOTION PAGE

Use this command to add a section heading + data table to a page.

You must construct the full JSON with ALL your research rows included. Build the complete JSON response in your reasoning, then execute one PATCH call.

**Section heading + table structure:**

```bash
curl -s -X PATCH "https://api.notion.com/v1/blocks/PAGE_ID/children" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "children": [
      {
        "object": "block",
        "type": "heading_2",
        "heading_2": {
          "rich_text": [{"type": "text", "text": {"content": "Section 1 — Research Results"}}]
        }
      },
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [{"type": "text", "text": {"content": "Query: USER_INSTRUCTION_HERE | Sources: COUNT_HERE"}}]
        }
      },
      {
        "object": "block",
        "type": "table",
        "table": {
          "table_width": 4,
          "has_column_header": true,
          "has_row_header": false,
          "children": [
            {
              "object": "block",
              "type": "table_row",
              "table_row": {
                "cells": [
                  [{"type": "text", "text": {"content": "Provider / Item"}}],
                  [{"type": "text", "text": {"content": "Website"}}],
                  [{"type": "text", "text": {"content": "Pricing"}}],
                  [{"type": "text", "text": {"content": "Notes"}}]
                ]
              }
            },
            {
              "object": "block",
              "type": "table_row",
              "table_row": {
                "cells": [
                  [{"type": "text", "text": {"content": "Example Provider"}}],
                  [{"type": "text", "text": {"content": "https://example.com"}}],
                  [{"type": "text", "text": {"content": "$10/month"}}],
                  [{"type": "text", "text": {"content": "Key feature or note"}}]
                ]
              }
            }
          ]
        }
      }
    ]
  }'
```

**For iterations (Section 2, 3, etc.):** Change the heading text to `"Section 2 — Improved Results (Cheaper Providers)"` or similar that reflects the feedback. The ITERATION_NUM from the flag file tells you which section number to use.

**For different research types, adjust the table columns:**

- API/Tool discovery: Provider, Website, Pricing, Notes
- Competitor analysis: Competitor, What They Do, Pricing, Gap / Our Advantage
- YouTube research: Video Title, Channel, Views, Key Tactic
- Reddit/Social: Platform, Post/URL, Engagement, Hook / Insight
- SaaS ideas: Idea, Market, Demand Signal, Effort

**Important JSON rules:**
- All strings must be properly escaped
- URLs and special characters that appear in your data must be escaped (replace `"` with `\"` inside strings)
- Build the full JSON with all your actual research data before making the API call
- Maximum ~95 children per PATCH call — if you have more rows, make multiple PATCH calls

---

## LOCAL REPORT — Backup

Also write findings locally (secondary to Notion):

- Daily: `reports/research-YYYY-MM-DD-{morning|midday|evening}.md`
- Latest: `reports/research-latest.md`

---

## Research Depth Targets

- **Per scheduled run**: 40-60 sources (morning), 30-40 (midday), 20-30 (evening)
- **Urgent tasks**: research until you have enough quality data for the task (usually 10-30 sources minimum)
- **YouTube**: 20 results per query, pull stats for top 10
- **Brave Search**: 10-20 results per query
