# Content — Operating Instructions

## Environment Variables

REAL environment variables in your shell — reference exactly as written:

- `$OPENAI_API_KEY` — OpenAI API key for DALL-E image generation
- `$NOTION_API_KEY` — Notion integration token
- `$GOOGLE_CLIENT_ID` — Google OAuth client ID
- `$GOOGLE_CLIENT_SECRET` — Google OAuth client secret
- `$GOOGLE_REFRESH_TOKEN` — Google OAuth refresh token

---

## STEP 1 — DETECT RUN MODE

**Check for urgent flag first:**

```bash
cat tasks/urgent-content.flag 2>/dev/null
```

- **If flag EXISTS** → URGENT MODE. Source the flag file to get your task.
- **If flag does NOT exist** → SCHEDULED MODE. Read `tasks/content-task.md`.

---

## URGENT MODE — On-Demand Task Execution

Source the flag file:
```bash
source tasks/urgent-content.flag
```

Variables available:
- `$TASK_TITLE` — title for the Notion result page
- `$NOTION_PAGE_ID` — if set: append to this page. If empty: create new page.
- `$NOTION_TASK_ID` — the Notion task entry to update status on
- `$ITERATION_NUM` — iteration number (1 = first, 2+ = new section)
- `$USER_INSTRUCTION` — the full content request
- `$FEEDBACK` — refinement feedback (empty on first run)

Execute the content task based on `$USER_INSTRUCTION`. Then write results to Notion (see below). Then clean up.

### Cleanup after urgent task

```bash
rm tasks/urgent-content.flag
```

Update task-registry.json — read it, find entry for `$NOTION_TASK_ID`, set status to "complete", save.

Update Notion task status:
```bash
curl -s -X PATCH "https://api.notion.com/v1/pages/$NOTION_TASK_ID" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"properties":{"Status":{"select":{"name":"Complete"}}}}'
```

---

## SCHEDULED MODE — Regular Content Creation

Read `tasks/content-task.md` and `reports/research-latest.md`. Create the content types listed. Write to local `content/` files. Create Notion summary page.

---

## CONTENT CREATION

### Scripts and Copy

Write based on the USER_INSTRUCTION. Content types:
- TikTok hooks + scripts (30-60 second format)
- Reddit posts (native tone)
- LinkedIn threads (value-first)
- Email drafts (subject + body)
- UGC scripts
- Landing page copy
- Marketing hooks

### DALL-E Image Generation

Generate an image:
```bash
IMG_RESULT=$(curl -s "https://api.openai.com/v1/images/generations" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"dall-e-3","prompt":"YOUR_IMAGE_DESCRIPTION","n":1,"size":"1024x1024"}')
echo "$IMG_RESULT"
```

Available sizes: `1024x1024` (square), `1024x1792` (portrait), `1792x1024` (landscape).

Extract the `url` from the response. This is a temporary OpenAI URL — you must download and upload it to Google Drive immediately (see below).

REMEMBER: Keep `$OPENAI_API_KEY` exactly as written.

---

## GOOGLE DRIVE UPLOAD

After generating a DALL-E image, upload it to Google Drive so the link is permanent.

### Step 1 — Get Google Access Token

```bash
ACCESS_TOKEN=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
  -d "client_id=$GOOGLE_CLIENT_ID&client_secret=$GOOGLE_CLIENT_SECRET&refresh_token=$GOOGLE_REFRESH_TOKEN&grant_type=refresh_token" \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
echo "Access token obtained: ${ACCESS_TOKEN:0:20}..."
```

### Step 2 — Ensure Upload Folder Exists

Check if folder ID is cached:
```bash
cat memory/drive-folder-id.txt 2>/dev/null
```

If the file exists and has content, use that as FOLDER_ID. Skip to Step 3.

If it doesn't exist, create the folder:
```bash
FOLDER_RESULT=$(curl -s -X POST "https://www.googleapis.com/drive/v3/files" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"OpenClaw Content","mimeType":"application/vnd.google-apps.folder"}')
echo "$FOLDER_RESULT"
```

Extract the folder `id` from the response. Save it:
```bash
echo "FOLDER_ID_HERE" > memory/drive-folder-id.txt
```

### Step 3 — Download the DALL-E Image

```bash
IMAGE_FILENAME="content-$(date +%Y%m%d-%H%M%S).png"
curl -s -L "DALLE_IMAGE_URL_HERE" -o "/tmp/$IMAGE_FILENAME"
echo "Downloaded: $IMAGE_FILENAME"
```

### Step 4 — Upload to Google Drive

```bash
FOLDER_ID=$(cat memory/drive-folder-id.txt)
UPLOAD_RESULT=$(curl -s -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "metadata={\"name\":\"$IMAGE_FILENAME\",\"parents\":[\"$FOLDER_ID\"]};type=application/json;charset=UTF-8" \
  -F "file=@/tmp/$IMAGE_FILENAME;type=image/png")
echo "$UPLOAD_RESULT"
```

Extract the file `id` from the response. Save as DRIVE_FILE_ID.

### Step 5 — Make File Publicly Shareable

```bash
curl -s -X POST "https://www.googleapis.com/drive/v3/files/DRIVE_FILE_ID/permissions" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role":"reader","type":"anyone"}'
```

### Step 6 — Get the Shareable Link

The shareable link format is:
```
https://drive.google.com/file/d/DRIVE_FILE_ID/view?usp=sharing
```

Use this as the DRIVE_LINK to insert into the Notion table.

### Step 7 — Clean up temp file

```bash
rm /tmp/$IMAGE_FILENAME
```

---

## NOTION WRITE — Content Results

This is MANDATORY after every content run.

### Case A: New Content Task (NOTION_PAGE_ID is empty or scheduled run)

Create a page:
```bash
PAGE_RESULT=$(curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "{\"parent\":{\"type\":\"workspace\",\"workspace\":true},\"properties\":{\"title\":{\"title\":[{\"type\":\"text\",\"text\":{\"content\":\"$TASK_TITLE\"}}]}}}")
echo "$PAGE_RESULT"
```

Extract the `id` — this is your PAGE_ID.

### Case B: Iteration (NOTION_PAGE_ID is set)

Use `$NOTION_PAGE_ID` as the PAGE_ID. Do NOT create a new page.

### Append Content Table to the Page

Build the table with ALL your content rows first, then make ONE PATCH call:

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
          "rich_text": [{"type": "text", "text": {"content": "Section 1 — Content Assets"}}]
        }
      },
      {
        "object": "block",
        "type": "table",
        "table": {
          "table_width": 5,
          "has_column_header": true,
          "has_row_header": false,
          "children": [
            {
              "object": "block",
              "type": "table_row",
              "table_row": {
                "cells": [
                  [{"type": "text", "text": {"content": "Title"}}],
                  [{"type": "text", "text": {"content": "Platform"}}],
                  [{"type": "text", "text": {"content": "Hook / Script"}}],
                  [{"type": "text", "text": {"content": "Image Description"}}],
                  [{"type": "text", "text": {"content": "Google Drive Link"}}]
                ]
              }
            },
            {
              "object": "block",
              "type": "table_row",
              "table_row": {
                "cells": [
                  [{"type": "text", "text": {"content": "Hook 1 Title"}}],
                  [{"type": "text", "text": {"content": "TikTok"}}],
                  [{"type": "text", "text": {"content": "Hook text and script here"}}],
                  [{"type": "text", "text": {"content": "Image description here"}}],
                  [{"type": "text", "text": {"content": "https://drive.google.com/file/d/FILE_ID/view?usp=sharing"}}]
                ]
              }
            }
          ]
        }
      }
    ]
  }'
```

**For image generation tasks specifically**, use this table structure:
- Title | Image Text | Image Description | Google Drive Link

**For script/copy tasks**, use:
- Title | Platform | Hook | Script | Status

**For iterations**, change heading to `"Section 2 — Revised Content"` etc.

---

## PRODUCTION TARGETS

### Per scheduled run
- 3-5 TikTok hook scripts (with 2 variations of best performers)
- 2-3 Reddit posts
- 1-2 LinkedIn threads
- 1-2 email drafts
- 1-2 UGC scripts
- 1-2 DALL-E images (download + upload to Drive + insert link in Notion)

### Per urgent run
- Execute exactly what USER_INSTRUCTION requests
- At minimum: generate the content + write it to Notion

---

## LOCAL BACKUP

Also write content locally:
- Content files: `content/YYYY-MM-DD-{platform}-{topic}.md`
- Daily summary: `reports/content-YYYY-MM-DD.md`
- Latest: `reports/content-latest.md`

Mark all local files: `Status: PR PENDING`
