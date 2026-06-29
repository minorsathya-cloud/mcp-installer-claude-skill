---
name: mcp-installer
description: Install, configure, and verify any MCP (Model Context Protocol) server for Claude Desktop. Use this skill whenever the user wants to connect Claude to an external service or tool via MCP — including Google Sheets, GitHub, Notion, Linear, Slack, Postgres, filesystem tools, or any custom MCP package. Triggers on phrases like "set up MCP", "install MCP", "connect Claude to [service]", "configure MCP server", "I want Claude to access [tool/service]", "add MCP to Claude Desktop", or any mention of mcp- packages. Also triggers when a user wants to give Claude access to a database, API, file system, or external service through Claude Desktop. Always use this skill rather than improvising MCP setup steps — it prevents the most common failure modes including silent uvx path errors, config overwrites, missing resource sharing, and unverified installations.
---

# MCP Installer

A structured 7-phase process for installing any MCP server into Claude Desktop without errors, assumptions, or wasted steps. Each phase gates the next — nothing proceeds on assumption.

---

## Core Principles (enforce throughout)

1. **Never assume the environment.** Always read it first via pre-flight.
2. **Never write to Mac paths from the sandbox.** Generate shell scripts for the user to run in Terminal.
3. **Always use absolute paths** for uvx, node, python in Claude Desktop config. Never short names.
4. **Always merge** into existing claude_desktop_config.json. Never overwrite.
5. **Success is not declared until all verification tests pass.**
6. **On any failure:** diagnose from actual error output before suggesting a fix. Read `references/error-diagnosis.md`.

---

## Phase 1 — Discover

Ask the user (only what you can't infer):

1. **What MCP?** Get the package name, GitHub URL, or service name.
   - Check `references/known-mcps/INDEX.md` to see if it's a known MCP.
   - If known: load its reference file — it has exact steps and gotchas.
   - If unknown: ask for the docs URL. Fetch and read it before proceeding.

2. **What does it connect to?** Sheet ID, workspace URL, repo name, database URL, etc.

3. **What's the goal?** Read-only or full CRUD? This determines which auth scope to request.

Never ask for information you can determine from the docs or the pre-flight output.

---

## Phase 2 — Pre-Flight Diagnostic

Tell the user:

> "Before I write any steps, I need to see your environment. Run these 5 commands in Mac Terminal and paste the full output:"

```bash
# 1. Runtimes
echo "=== RUNTIMES ===" && \
which uvx && uvx --version 2>/dev/null || echo "UVX: NOT INSTALLED" && \
which node && node --version 2>/dev/null || echo "NODE: NOT INSTALLED" && \
which python3 && python3 --version 2>/dev/null || echo "PYTHON: NOT INSTALLED"

# 2. Claude Desktop config
echo "=== CLAUDE CONFIG ===" && \
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json \
  2>/dev/null || echo "CONFIG: FILE MISSING"

# 3. Absolute path to uvx (critical)
echo "=== PATHS ===" && \
which uvx 2>/dev/null || echo "UVX PATH: NOT FOUND" && \
which node 2>/dev/null || echo "NODE PATH: NOT FOUND"

# 4. System
echo "=== SYSTEM ===" && \
uname -m && sw_vers -productVersion 2>/dev/null || uname -s

# 5. Identity
echo "=== IDENTITY ===" && \
echo "USER: $(whoami)" && echo "HOME: $HOME"
```

Read `references/environment-profiles.md` to parse the output and build an environment profile before proceeding. The profile determines the shortest path.

---

## Phase 3 — Auth Selection

Determine what auth the MCP requires. If the known-MCP reference specifies it, explain it to the user directly. If unknown, infer from the docs.

**If multiple auth methods are available:** explain each one. Read `references/auth-patterns.md` for the full explanation template including pros, cons, and setup complexity. Present options clearly and wait for the user to choose before proceeding.

**If only one auth method exists:** explain it briefly and confirm before proceeding.

Never begin auth setup without explicit user confirmation of which method to use.

---

## Phase 4 — Execute (Shell Script)

Generate a single shell script that does all Mac-side work in one pass. Read `references/shell-script-builder.md` for the exact rules before writing any script.

The script always:
- Uses absolute paths from the pre-flight output
- Checks before installing (idempotent — safe to re-run)
- Merges into existing config, never overwrites
- Prints `✓ [step]` or `✗ [step]: [reason]` after each action
- Ends with a `=== SUMMARY ===` block the user pastes back

Present the script as a downloadable file. Tell the user:
> "Save this as `install-mcp.sh`, then run: `bash ~/Downloads/install-mcp.sh`"
> "Paste the full output back here."

Read the output. Confirm every `✓` before proceeding. If any `✗` appears, diagnose using `references/error-diagnosis.md` before continuing.

---

## Phase 5 — Resource Access

If the MCP connects to a specific resource (Google Sheet, Notion workspace, GitHub repo, database, etc.) — the resource must be explicitly shared with the MCP's identity before verification.

For each auth type:
- **Service Account:** share the resource with the `client_email` from the JSON credentials file as Editor/Member/Contributor
- **OAuth:** the resource is accessible via the user's own account — confirm the user has access
- **API Key / PAT:** confirm the key has the correct scopes for the intended operations
- **No auth:** skip this phase

Walk the user through the exact sharing step. Confirm they've done it before proceeding to verification.

---

## Phase 6 — Verify

Tell the user:
> "Now Cmd+Q Claude Desktop (full quit, not just close the window), then relaunch it."

Run 4 verification tests in sequence. Each must pass before the next runs.

**Test 1 — Tool Discovery**
Ask the user to open a new Claude chat and type:
> "What tools do you have available?"

Expected: MCP tools from the new server appear in the list.
If missing: the MCP failed to load. Read `references/error-diagnosis.md` → "MCP tools don't appear".

**Test 2 — Read**
Construct a read test specific to the MCP. Examples:
- Google Sheets: "Read the headers from tab [TabName] of Sheet [ID]"
- GitHub: "List the open issues in repo [owner/repo]"
- Notion: "List my Notion databases"
- Postgres: "List all tables in the database"

Expected: real data returned, no auth error.

**Test 3 — Write**
Construct a write test using a clearly labelled test value. Examples:
- Google Sheets: "Add a row with TEST in column A to tab [TabName]"
- GitHub: "Create a draft issue titled MCP-TEST in repo [owner/repo]"
- Notion: "Create a test page titled MCP-TEST in [database]"

Expected: value appears in the resource.

**Test 4 — Delete / Cleanup**
Remove the test value written in Test 3. Examples:
- Google Sheets: "Delete the row where column A is TEST from tab [TabName]"
- GitHub: "Delete the draft issue titled MCP-TEST"
- Notion: "Delete the page titled MCP-TEST"

Expected: value is physically removed. Verify by opening the resource.

**All 4 tests must pass.** On any failure: diagnose first, fix, re-run from the failing test.

For MCPs with known deletion quirks (e.g. Google Sheets requires `deleteDimension` via `batch_update`), read the known-MCP reference file for the exact pattern.

---

## Phase 7 — Handoff

Once all tests pass:

1. **Confirm setup summary** — one clean block:
   ```
   ✓ MCP installed:     [package name]
   ✓ Runtime:           [uvx / node / python] at [absolute path]
   ✓ Auth:              [type used]
   ✓ Config location:   ~/Library/Application Support/Claude/claude_desktop_config.json
   ✓ Resource access:   [confirmed]
   ✓ Tests passed:      Read / Write / Delete
   ```

2. **Claude Project update** — ask:
   > "Is there a Claude Project whose instructions should know about this MCP?"
   If yes: generate a `## [MCP NAME] OPERATIONS` instructions block tailored to that project's use case.

3. **Documentation offer** — ask:
   > "Want me to save a setup reference file for this MCP so future reinstalls are instant?"
   If yes: generate a markdown reference file with the exact config, credentials path, and any known gotchas. Present as a downloadable file.

4. **Done.** Do not declare success before this point.

---

## Reference Files

Load these only when needed — do not load all upfront:

| File | Load when |
|---|---|
| `references/environment-profiles.md` | After pre-flight output is pasted (Phase 2) |
| `references/auth-patterns.md` | Explaining auth options to user (Phase 3) |
| `references/shell-script-builder.md` | Before generating any shell script (Phase 4) |
| `references/config-writer.md` | Before writing claude_desktop_config.json |
| `references/verification-tests.md` | Before running verification (Phase 6) |
| `references/error-diagnosis.md` | When any step fails |
| `references/known-mcps/INDEX.md` | At Phase 1 to check if MCP is known |
| `references/known-mcps/[name].md` | When a known MCP is identified |
