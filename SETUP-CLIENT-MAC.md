OpenClaw 3-Agent System — Client Mac Setup Guide
================================================

Use this when setting up the pipeline on the client's Mac Mini (e.g. via AnyDesk). Do steps in order. Have all API keys ready before you start.


1. Install prerequisites
------------------------

Install Homebrew if not already installed:

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Follow the on-screen instructions. Then install Node.js 22:

brew install node@22
brew link node@22

Verify:

node -v
npm -v

Node should show v22.x.x. If python3 is needed for test scripts, check with:

python3 --version

Install with brew install python3 if missing.


2. Get the project onto the Mac
-------------------------------

Option A: Clone the repo (if client has git):

cd ~/Desktop
git clone YOUR_REPO_URL openclaw-agents
cd openclaw-agents

Option B: Copy the project folder via AnyDesk file transfer to the client's Desktop, then:

cd ~/Desktop/openclaw-agents


3. Prepare the .env file
------------------------

Copy the example and fill in every key the client will use. Do this before running setup so the client does not have to paste keys during setup.

cd ~/Desktop/openclaw-agents
cp .env.example .env

Edit .env and set:

  OPENAI_API_KEY          — From client's OpenAI account (paid plan recommended)
  GEMINI_API_KEY          — From Google AI Studio (aistudio.google.com)
  MINIMAX_API_KEY         — From MiniMax; paid plan required (minimaxi.com)
  NOTION_API_KEY          — From Notion: create integration at notion.so/my-integrations; key starts with ntn_
  YOUTUBE_API_KEY         — From Google Cloud Console; enable YouTube Data API v3
  BRAVE_SEARCH_API_KEY    — From brave.com/search/api
  TELEGRAM_BOT_TOKEN      — From Telegram BotFather
  TELEGRAM_CHAT_ID        — Numeric chat ID for notifications
  GOOGLE_CLIENT_ID        — From Google Cloud OAuth 2.0 credentials (Desktop app)
  GOOGLE_CLIENT_SECRET    — Same OAuth client
  GOOGLE_REFRESH_TOKEN    — From OAuth Playground with Gmail + Drive scopes

Leave any key empty if the client will not use that service. setup.sh will prompt only for the LLM choice and any missing keys.


4. Notion setup (do before running setup.sh)
---------------------------------------------

The Commander agent reads tasks from Notion. The API key alone is not enough; pages must be shared with the integration.

4a. Go to notion.so/my-integrations and create an integration (e.g. name: OpenClaw Commander). Copy the Internal Integration Secret (starts with ntn_) into .env as NOTION_API_KEY.

4b. In Notion, open each page or database the client wants the Commander to read. Click the three-dots menu at the top right, then Connections, then connect the integration you created. Repeat for every relevant page or connect one top-level page to give access to all sub-pages.


5. Google APIs setup (Gmail and Drive)
-------------------------------------

5a. In Google Cloud Console (console.cloud.google.com), enable: Gmail API, Google Drive API, YouTube Data API v3.

5b. Create OAuth 2.0 credentials: APIs & Services > Credentials > Create Credentials > OAuth client ID. Application type: Desktop app. Copy Client ID and Client Secret into .env.

5c. Go to developers.google.com/oauthplayground. Click the gear icon, enable "Use your own OAuth credentials", and enter the Client ID and Client Secret. In the left panel, select scope "https://mail.google.com/" under Gmail API v1 and "https://www.googleapis.com/auth/drive" under Drive API v3. Click Authorize APIs, sign in with the client's Google account, then Exchange authorization code for tokens. Copy the refresh_token into .env as GOOGLE_REFRESH_TOKEN.


6. Run setup
------------

cd ~/Desktop/openclaw-agents
chmod +x setup.sh
./setup.sh

When prompted, choose the LLM: 1 = MiniMax, 2 = Gemini, 3 = OpenAI. If all keys are already in .env, you can press Enter through the optional key prompts. At the end, setup starts the gateway and registers the CRON jobs.


7. Auto-start the gateway (optional, for 24/7 after reboot)
-----------------------------------------------------------

So the pipeline keeps running after the Mac restarts, install a Launch Agent. Replace CLIENT_USERNAME with the actual macOS username (e.g. the output of whoami). On Apple Silicon Macs, npx is usually under /opt/homebrew/bin/npx.

Create the file:

nano ~/Library/LaunchAgents/com.openclaw.gateway.plist

Paste this, then fix the WorkingDirectory path and the path to npx if needed:

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/npx</string>
        <string>--yes</string>
        <string>openclaw</string>
        <string>gateway</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/Users/CLIENT_USERNAME</string>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-gateway.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-gateway.err</string>
</dict>
</plist>

Save and exit (Ctrl+O, Enter, Ctrl+X in nano). Then load it:

launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist

On Intel Macs with Homebrew, npx may be at /usr/local/bin/npx. Check with: which npx.


8. Verify
---------

Quick smoke test (run from project directory):

npx openclaw agent --agent commander -m "Write 'Commander OK' to briefs/health-check.md"
npx openclaw agent --agent research -m "Write 'Research OK' to reports/health-check.md"
npx openclaw agent --agent content -m "Write 'Content OK' to content/health-check.md"

Check that files exist:

ls ~/.openclaw/workspace/briefs/
ls ~/.openclaw/workspace/reports/
ls ~/.openclaw/workspace/content/

List CRON jobs:

npx openclaw cron list

You should see the five scheduled jobs (research-morning, commander-morning, content-evening, commander-evening, research-weekly).


9. Where outputs live
---------------------

All agent outputs are under:

~/.openclaw/workspace/

  briefs/     — Morning and evening briefs from Commander
  reports/    — Research and content summaries
  tasks/      — Research and content task files
  content/    — Scripts, drafts, image URLs (all PR PENDING)

The client reviews and approves content from the content/ folder; nothing is auto-published.


10. Summary
-----------

  Install Homebrew and Node 22.
  Copy or clone the project to the client's Mac.
  Pre-fill .env with all API keys.
  Create Notion integration and share the right pages with it.
  Enable Google APIs and create OAuth refresh token for Gmail and Drive.
  Run ./setup.sh and choose LLM (1 MiniMax, 2 Gemini, 3 OpenAI).
  Optionally install the Launch Agent so the gateway starts after reboot.
  Run the three smoke-test commands and npx openclaw cron list to confirm.

Estimated time with keys ready: about 30–45 minutes over AnyDesk.
