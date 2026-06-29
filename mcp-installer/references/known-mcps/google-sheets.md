# Google Sheets MCP

**Package:** `mcp-google-sheets@latest`
**Runtime:** uvx
**Auth:** Service Account (JSON key file)
**Docs:** https://github.com/isaacwasserman/mcp-google-sheets

---

## Key Tools Exposed

- `get_sheet_data` — read a tab. Use `include_grid_data=true` to get the numeric `sheetId` needed for deletion.
- `update_cells` — write to a cell range
- `batch_update` — batch operations including `deleteDimension` for physical row deletion
- `append_rows` — append rows to a tab

---

## Required Google Cloud Setup

1. Go to console.cloud.google.com
2. Create or select a project
3. Enable: **Google Sheets API** and **Google Drive API** (both required)
4. IAM & Admin → Service Accounts → Create Service Account
   - Name it descriptively (e.g. `delhi-openings-sheets`)
   - Role: Editor (at project level) — or grant per-Sheet below
5. Click the service account → Keys → Add Key → JSON → Download
6. Save the JSON to an absolute path: `~/[project]-credentials.json`
7. Run: `chmod 600 ~/[project]-credentials.json`
8. Find the `client_email` field in the JSON — you'll need this for sharing

---

## Sharing the Sheet

**This step is the most commonly missed and causes silent write failures.**

1. Open the target Google Sheet
2. Click Share
3. Paste the `client_email` from the credentials JSON
4. Set permission to **Editor**
5. Uncheck "Notify people" (the service account has no inbox)
6. Click Share

Repeat for every Sheet the MCP needs to access. The service account only has access to Sheets it's been explicitly shared on.

---

## Config Block

```json
"google-sheets": {
  "command": "/absolute/path/to/uvx",
  "args": ["mcp-google-sheets@latest"],
  "env": {
    "GOOGLE_APPLICATION_CREDENTIALS": "/absolute/path/to/credentials.json"
  }
}
```

---

## Physical Row Deletion (Critical Gotcha)

The Sheets API has no simple "delete row" operation. Physical deletion (so rows shift up, not just blank out) requires `batch_update` with `deleteDimension`.

**Step 1: Get the numeric sheetId**
```
Call: get_sheet_data(spreadsheet_id=[ID], sheet=[TabName], include_grid_data=true)
Extract: sheets[0].properties.sheetId  →  e.g. 1738592675
```
This numeric sheetId is per-tab and different from the spreadsheet ID in the URL. It doesn't change.

**Step 2: Find the 0-based row index**
```
Row 1 (header)  →  startIndex 0
Row 2           →  startIndex 1
Row 7           →  startIndex 6
Formula: startIndex = row_number - 1
```

**Step 3: Call batch_update**
```json
{
  "requests": [{
    "deleteDimension": {
      "range": {
        "sheetId": 1738592675,
        "dimension": "ROWS",
        "startIndex": 6,
        "endIndex": 7
      }
    }
  }]
}
```

Always include `endIndex = startIndex + 1` for a single row.

---

## Verification Tests (Sheets-Specific)

**Test 2 — Read:**
> "Read the headers from the [TabName] tab of Sheet [ID]"

**Test 3 — Write:**
> "Add a row to [TabName] with TEST in column A"

**Test 4 — Delete:**
> "Delete the row where column A is TEST from [TabName]"
Must use `deleteDimension` pattern above. Row must physically disappear (row count decreases), not just become blank.

---

## Common Issues

| Issue | Fix |
|---|---|
| Writes succeed but nothing changes in Sheet | Service account not shared as Editor on this specific Sheet |
| `get_sheet_data` returns data but `batch_update` fails | API enabled in wrong GCP project, or wrong credentials file |
| `sheetId` not found in response | Must pass `include_grid_data=true` to get sheet properties |
| Row becomes blank instead of deleted | Used `update_cells` to blank instead of `deleteDimension` — redo with `batch_update` |
| "The caller does not have permission" | Sheet not shared, or shared as Viewer not Editor |
