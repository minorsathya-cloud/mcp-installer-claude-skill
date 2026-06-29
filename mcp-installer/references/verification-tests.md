# Verification Tests

Run these in sequence after every MCP installation. Each test must pass before the next runs. Do not declare success until all 4 pass.

---

## Pre-Test: Cmd+Q and Relaunch

Before any test:
1. Tell the user to press **Cmd+Q** in Claude Desktop — this is a full quit, not just closing the window
2. Relaunch Claude Desktop
3. Open a **new chat** (not an existing one — old chats cache tool lists)

This is mandatory. Config changes are only read at startup.

---

## Test 1 — Tool Discovery

**User types in new chat:**
> "What tools do you have available?"

**Expected:** The new MCP's tools appear in the list by name.

**Pass criteria:** At least one tool from the new MCP is listed.

**If tools are missing:**
- Check `references/error-diagnosis.md` → "MCP tools don't appear after relaunch"
- Most common cause: short command name (`uvx`) instead of absolute path
- Second most common: config JSON syntax error
- Check Mac logs: `cat ~/Library/Logs/Claude/mcp*.log 2>/dev/null | tail -50`

---

## Test 2 — Read

Construct a read test appropriate for the MCP. Use real data from the target resource.

| MCP | Read test prompt |
|---|---|
| Google Sheets | "Read the headers from the [TabName] tab of Sheet [ID]" |
| GitHub | "List the open issues in [owner/repo]" |
| Notion | "List my Notion databases" |
| Linear | "List my open Linear issues" |
| Slack | "List my Slack channels" |
| Postgres | "List all tables in the [database] database" |
| Filesystem | "List files in [path]" |
| Custom | Read the MCP docs for the simplest read operation |

**Pass criteria:** Real data returned. No auth error. No "tool not found" error.

**If auth error:** Check Phase 5 (Resource Access) was completed — the resource must be shared with the MCP's identity.

---

## Test 3 — Write

Construct a write test using a clearly labelled test value so it's easy to find and delete.

| MCP | Write test prompt |
|---|---|
| Google Sheets | "Add a row to the [TabName] tab with TEST in column A and today's date in column B" |
| GitHub | "Create a draft issue titled MCP-INSTALL-TEST in [owner/repo] with body 'test'" |
| Notion | "Create a page titled MCP-INSTALL-TEST in [database]" |
| Linear | "Create an issue titled MCP-INSTALL-TEST in [team]" |
| Slack | "Post 'MCP install test — delete me' to [channel]" |
| Postgres | "Create a table named mcp_test with one column: id integer" |
| Filesystem | "Create a file at [path]/mcp-test.txt with content 'test'" |

**Pass criteria:** Value appears in the resource when verified by opening it directly.

**If write fails silently:** The MCP loaded but the resource isn't shared correctly (service account without Editor access, PAT without write scope, OAuth without write permission).

---

## Test 4 — Delete / Cleanup

Remove the test value from Test 3. This confirms destructive operations work and leaves no test data behind.

| MCP | Delete test prompt |
|---|---|
| Google Sheets | "Delete the row where column A is TEST from the [TabName] tab" |
| GitHub | "Delete the issue titled MCP-INSTALL-TEST" |
| Notion | "Delete the page titled MCP-INSTALL-TEST" |
| Linear | "Delete the issue titled MCP-INSTALL-TEST" |
| Slack | "Delete the test message I just posted" (if API supports it) |
| Postgres | "Drop the table mcp_test" |
| Filesystem | "Delete the file [path]/mcp-test.txt" |

**Pass criteria:** Value is physically removed from the resource.

**Known deletion quirks:**
- **Google Sheets:** requires `batch_update` with `deleteDimension`. See `known-mcps/google-sheets.md` for the exact pattern.
- **Notion:** archived vs deleted — confirm the page is fully deleted, not just archived
- **GitHub:** issues can only be closed via API, not deleted — this is expected behavior, closing is the pass condition
- **Slack:** message deletion requires `chat:write` AND `chat:delete` scopes on the PAT

---

## Test Failure Recovery

If any test fails:

1. **Copy the exact error message**
2. Read `references/error-diagnosis.md` — find the matching symptom
3. Apply the fix
4. Re-run **from Test 1** (Cmd+Q, relaunch, new chat)
5. Don't skip tests after a fix — always verify from the start

---

## Logging for Hard Failures

If MCP tools don't appear and the config looks correct, check Claude Desktop's MCP logs:

```bash
# List MCP log files
ls ~/Library/Logs/Claude/

# Read the most recent log
ls -t ~/Library/Logs/Claude/mcp*.log 2>/dev/null | head -1 | xargs tail -100
```

The log shows exactly why the MCP server failed to start — missing package, auth error, wrong path, etc.
