# Error Diagnosis

Match the symptom exactly. Read the cause. Apply the fix. Re-run verification from Test 1.

---

## MCP Tools Don't Appear After Relaunch

**Symptom:** User asks "what tools do you have available?" and the new MCP's tools are not listed.

**Cause A: Short command name in config**
- Config has `"command": "uvx"` instead of the absolute path
- Claude Desktop's restricted PATH cannot find it
- **Fix:** Update config to use `"command": "/Users/[user]/.local/bin/uvx"`. Cmd+Q, relaunch.

**Cause B: JSON syntax error in config**
- A trailing comma, missing quote, or bracket mismatch makes the whole config invalid
- Claude Desktop silently ignores all MCPs when config is invalid JSON
- **Fix:** Run `python3 -m json.tool ~/Library/Application\ Support/Claude/claude_desktop_config.json` — it will show the exact error. Fix and relaunch.

**Cause C: Config not saved before quit**
- The file was written but the editor didn't save, or the script failed partway through
- **Fix:** `cat ~/Library/Application\ Support/Claude/claude_desktop_config.json` — verify the new server key is actually there. If not, re-run the install script.

**Cause D: Window closed instead of Cmd+Q**
- Claude Desktop only reads config at launch. Closing the window doesn't relaunch it.
- **Fix:** Cmd+Q → relaunch.

**Cause E: MCP package doesn't exist or failed to install**
- uvx couldn't find or install the package
- **Fix:** Check `~/Library/Logs/Claude/mcp-server-[name].log` for the actual error. Try running `uvx [package]@latest` manually in Terminal.

---

## Write Succeeds But Data Doesn't Appear in Resource

**Symptom:** Claude says the write worked, but opening the Sheet/Notion/repo shows nothing changed.

**Cause A: Resource not shared with service account**
- The MCP authenticated fine but the service account doesn't have access to the specific resource
- **Fix:** Open the resource → Share → paste the `client_email` from the credentials JSON → grant Editor access

**Cause B: Wrong resource ID**
- Claude wrote to a different Sheet/database/repo than intended
- **Fix:** Confirm the exact resource ID in the MCP call and the target resource

**Cause C: OAuth token has wrong scopes**
- Token was granted read-only scope
- **Fix:** Re-run the OAuth flow and explicitly grant write permissions

---

## "Unauthorized" or 403 Error on All Calls

**Symptom:** Every MCP call returns an auth error.

**Cause A: Credentials file path is wrong in config**
- Config has `"GOOGLE_APPLICATION_CREDENTIALS": "~/credentials.json"` (tilde doesn't expand in JSON)
- **Fix:** Replace `~` with the full absolute path: `/Users/[user]/credentials.json`

**Cause B: OAuth token expired**
- OAuth tokens expire — typically after 1 hour (access token) or weeks (refresh token)
- **Fix:** Delete the stored token and re-run the OAuth flow. Location varies by MCP.

**Cause C: API key revoked or invalid**
- The key was deleted or rotated in the service's dashboard
- **Fix:** Generate a new key, update the config env var, Cmd+Q, relaunch.

**Cause D: PAT missing required scopes**
- Token exists but was created without the write/delete scope
- **Fix:** Go to account settings → Personal Access Tokens → edit or recreate the token with the correct scopes. See the known-MCP reference for required scopes.

---

## "Tool Not Found" Error

**Symptom:** Claude says it doesn't have a specific tool (e.g. `delete_row`, `batch_update`).

**Cause:** The installed MCP version doesn't expose that tool, or the tool has a different name.

**Fix:** 
1. Ask "what tools do you have available?" to see the exact tool names
2. Cross-reference with the known-MCP reference file for the correct tool name
3. If the tool is genuinely missing, the MCP version may be outdated — try `@latest` explicitly

---

## Delete / Row Removal Doesn't Work (Google Sheets)

**Symptom:** Row isn't physically removed — either an error, or the row becomes blank instead of disappearing.

**Cause:** Simple "delete" doesn't exist in the Sheets API. Physical deletion requires `batch_update` with `deleteDimension`.

**Fix — exact pattern:**
```
Step 1: Get the numeric sheetId
  → Call get_sheet_data with include_grid_data=true
  → Extract sheetId from sheets[0].properties.sheetId (a number like 1738592675)
  → This is NOT the spreadsheet ID — it's the per-tab numeric ID

Step 2: Find the row index (0-based)
  → Row 2 in the Sheet = startIndex 1
  → Row 7 in the Sheet = startIndex 6
  → Formula: startIndex = (row number) - 1

Step 3: Call batch_update
  {
    "deleteDimension": {
      "range": {
        "sheetId": [numeric sheetId from Step 1],
        "dimension": "ROWS",
        "startIndex": [0-based row index],
        "endIndex": [startIndex + 1]
      }
    }
  }
```

---

## Config Already Has Servers, New One Is Missing

**Symptom:** Other MCPs work fine but the newly added one isn't loading.

**Cause:** The install script overwrote the config instead of merging — the existing servers are still listed but the new one wasn't added correctly, or vice versa.

**Fix:**
1. `cat ~/Library/Application\ Support/Claude/claude_desktop_config.json`
2. Confirm all servers including the new one are present under `mcpServers`
3. If the new server is missing, manually add it using the merge pattern from `config-writer.md`
4. Cmd+Q, relaunch

---

## Script Fails: "Permission Denied" on Credentials File

**Symptom:** Script reports `✗` when trying to read or use the credentials file.

**Fix:**
```bash
chmod 600 ~/[credentials-file].json
ls -la ~/[credentials-file].json  # should show -rw------- 
```

---

## "uvx: command not found" After Installation

**Symptom:** uvx was just installed but the script can't find it.

**Cause:** The shell session doesn't have the updated PATH yet.

**Fix:** Close Terminal and open a fresh one, then re-run the script. Alternatively:
```bash
source ~/.zshrc   # if using zsh (default on modern Mac)
source ~/.bashrc  # if using bash
```

---

## Claude Desktop Shows MCP Error Icon at Startup

**Symptom:** Claude Desktop shows a warning or error indicator next to the MCP name.

**Fix:** Click the error icon — it shows the exact error message from the MCP server. Common causes:
- Package not found (wrong package name in `args`)
- Python/Node version mismatch
- Missing env var
- Credentials file not found at the path specified

Read the error message and match to the relevant section above.
