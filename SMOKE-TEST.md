OpenClaw 3-Agent System — Smoke Tests
======================================

Run these tests after setup to verify the full pipeline. Run each command one at a time. Wait for it to finish before running the next.


Quick Health Check
------------------

These confirm each agent can boot and write a file.

npx openclaw agent --agent commander -m "Write 'Commander OK' to briefs/health-check.md"

npx openclaw agent --agent research -m "Write 'Research OK' to reports/health-check.md"

npx openclaw agent --agent content -m "Write 'Content OK' to content/health-check.md"

Verify:

cat ~/.openclaw/workspace/briefs/health-check.md
cat ~/.openclaw/workspace/reports/health-check.md
cat ~/.openclaw/workspace/content/health-check.md


Full Day Simulation
-------------------

These simulate a real day cycle: Commander assigns work, Research gathers intel, Content creates assets, Commander reviews at night.


TEST 1 — Commander Morning Brief

npx openclaw agent --agent commander -m "Today is 2026-02-22. Query Notion API via curl to discover available databases. Read reports/research-latest.md if it exists. Write a Morning Brief to briefs/morning-brief-2026-02-22.md covering: top priorities, 3 high-leverage actions for the founder. Assign a research task to tasks/research-task.md with keywords: AI SaaS tools, TikTok growth hacks, Reddit marketing. Assign a content task to tasks/content-task.md: create 2 TikTok scripts and 1 Reddit post based on research. Keep total output under 400 words."

Expected output:
  briefs/morning-brief-2026-02-22.md
  tasks/research-task.md
  tasks/content-task.md


TEST 2 — Research Agent

npx openclaw agent --agent research -m "Read tasks/research-task.md. Use YouTube Data API via curl (env YOUTUBE_API_KEY) to search 'AI SaaS tools for startups' and return top 3 videos with titles, channels, and view counts. Use Brave Search API via curl (env BRAVE_SEARCH_API_KEY) to find 3 trending Reddit posts about 'TikTok growth hacks for SaaS' using site:reddit.com in the query. Write structured findings to reports/research-2026-02-22.md and copy to reports/research-latest.md."

Expected output:
  reports/research-2026-02-22.md
  reports/research-latest.md


TEST 3 — Content Agent

npx openclaw agent --agent content -m "Read tasks/content-task.md and reports/research-latest.md. Create: 1) Two 30-second TikTok scripts with strong hooks about AI tools for startups, 2) One Reddit post for r/SaaS about underrated AI automation tools, 3) One email subject line and 3-sentence preview for a newsletter. Then call OpenAI DALL-E API via curl (env OPENAI_API_KEY) to generate an image with prompt: futuristic AI robot working at a laptop in a modern startup office, neon purple lighting. Save scripts to content/campaign-2026-02-22.md and image URL to content/thumbnails-2026-02-22.md. Mark everything PR PENDING."

Expected output:
  content/campaign-2026-02-22.md
  content/thumbnails-2026-02-22.md


TEST 4 — Commander Evening Report

npx openclaw agent --agent commander -m "Review all files in reports/ and content/ directories. Write an Evening Report to briefs/evening-report-2026-02-22.md covering: what was produced today, what worked, what needs improvement, and 3 priorities for tomorrow. Update tasks/research-task.md and tasks/content-task.md with tomorrow's assignments. Keep total under 300 words."

Expected output:
  briefs/evening-report-2026-02-22.md
  tasks/research-task.md (updated)
  tasks/content-task.md (updated)


Verify All Outputs
------------------

After running all 4 tests, check the workspace:

ls ~/.openclaw/workspace/briefs/
ls ~/.openclaw/workspace/reports/
ls ~/.openclaw/workspace/tasks/
ls ~/.openclaw/workspace/content/

You should see all the files listed under Expected output above.


Verify CRON Jobs
----------------

npx openclaw cron list

Should show 5 jobs: research-morning, commander-morning, content-evening, commander-evening, research-weekly.


What Each Test Validates
------------------------

Test 1 (Commander Morning):
  LLM connection
  Notion API access (via curl)
  File reading (reports)
  File writing (briefs, tasks)
  Task assignment logic

Test 2 (Research):
  YouTube Data API (via curl)
  Brave Search API (via curl)
  Task file reading
  Report writing

Test 3 (Content):
  Task and report reading
  Script generation (TikTok, Reddit, email)
  OpenAI DALL-E image generation (via curl)
  PR PENDING marking
  Content file writing

Test 4 (Commander Evening):
  Directory scanning
  Report summarization
  Task updating for next day
  Evening brief writing


Troubleshooting
---------------

Rate limit error:
  Wait 60 seconds between tests if using Gemini free tier.
  Switch to OpenAI or MiniMax to avoid rate limits.

Gateway agent failed:
  Run: pkill -f openclaw
  Run: npx openclaw doctor --fix
  Restart: npx openclaw gateway (in a separate terminal)
  Then retry the test.

Notion API invalid token:
  Check NOTION_API_KEY starts with ntn_ in .env and ~/.openclaw/.env.
  Make sure Notion pages are shared with the integration.

npm ENOTEMPTY error:
  Run: rm -rf ~/.npm/_npx && npm cache clean --force
  Then retry.
