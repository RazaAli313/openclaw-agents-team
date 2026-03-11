import os, json, urllib.request, urllib.error
from pathlib import Path

key = os.environ.get("GEMINI_API_KEY", "")
if not key:
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            if line.startswith("GEMINI_API_KEY="):
                key = line.split("=", 1)[1].strip()

if not key:
    print("ERROR: GEMINI_API_KEY not set")
    exit(1)

# Simulate what OpenClaw sends: system prompt + SOUL.md + AGENTS.md + user message
# This is ~1500+ tokens input, asking for ~1000+ tokens output

system_prompt = """You are the Content & Distribution Agent — the execution engine that converts research into ready-to-post assets. Founder: MT.

Rules:
- Read your assignment from tasks/content-task.md
- Read latest research from reports/research-latest.md
- Write content pieces to content/YYYY-MM-DD-{platform}-{topic}.md
- Write daily summary to reports/content-YYYY-MM-DD.md
- Everything is a draft for MT's approval — mark as PR PENDING
- Do NOT auto-publish anything
- One campaign focus per run

What You Create:
1. Scripts: TikTok hooks, UGC scripts, Reddit posts, LinkedIn threads, email drafts
2. Creative Plans: AI video prompts, thumbnail concepts, storyboards, caption optimization
3. Images: Use OpenAI DALL-E API for thumbnail images, social media visuals
4. Platform Prep: Rewrite top-performing posts, draft contextual SaaS mentions
5. Logging: Track what was produced, send summary to Commander"""

user_message = """Generate 2 TikTok scripts about AI automation for small businesses. 
Each script should have:
- A 3-second hook opener
- Full script (30-60 seconds)
- Caption with hashtags
- Thumbnail concept description

Also generate 2 Reddit posts for r/SaaS about how AI agents can save time.
Each post should have a title, body text, and suggested subreddit.

Mark everything as PR PENDING."""

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
body = json.dumps({
    "contents": [
        {"role": "user", "parts": [{"text": system_prompt + "\n\n" + user_message}]}
    ]
}).encode()

req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})

print(f"Sending ~{len(body)} bytes to Gemini 2.5 Flash...")
print(f"(This simulates what OpenClaw sends — large prompt + large output request)")
print()

try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        print(f"OK — Got {len(text)} chars back.\n")
        print(text[:500] + "..." if len(text) > 500 else text)
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    code = err.get("error", {}).get("code", "?")
    msg = err.get("error", {}).get("message", "unknown")
    if code == 429:
        print(f"RATE LIMITED (429) — Large prompt exceeded free tier quota.")
        print(f"This is why OpenClaw agents get rate limited but gemini.py works.")
        print(f"\n{msg[:300]}")
    else:
        print(f"ERROR ({code}): {msg[:300]}")
except Exception as e:
    print(f"ERROR: {e}")
