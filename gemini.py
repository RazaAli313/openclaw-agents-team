import os, json, urllib.request, urllib.error

key = os.environ.get("GEMINI_API_KEY", "")
if not key:
    from pathlib import Path
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            if line.startswith("GEMINI_API_KEY="):
                key = line.split("=", 1)[1].strip()

if not key:
    print("ERROR: GEMINI_API_KEY not set")
    exit(1)

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={key}"
body = json.dumps({"contents": [{"parts": [{"text": "Say hello in one sentence."}]}]}).encode()

req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        print(f"OK — Gemini responded: {text}")
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    code = err.get("error", {}).get("code", "?")
    msg = err.get("error", {}).get("message", "unknown")
    if code == 429:
        print(f"QUOTA EXCEEDED — Key is valid but rate limited. Wait and retry.\n{msg}")
    elif code in (401, 403):
        print(f"AUTH FAILED ({code}) — Key is invalid or disabled.\n{msg}")
    else:
        print(f"ERROR ({code}): {msg}")
