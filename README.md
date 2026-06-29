# mcp-installer

A Claude skill that installs any MCP server into Claude Desktop correctly — first time, every time.

Built after a real session where every common failure mode was hit: silent uvx path errors, config overwrites, missing Sheet sharing, unverified installs. This skill encodes those fixes as a structured process so you never hit them again.

---

## What It Does

Guides Claude through a 7-phase installation process:

1. **Discover** — identifies the MCP, fetches docs if unknown
2. **Pre-flight** — reads your actual Mac environment before touching anything
3. **Auth Selection** — explains all auth options with pros/cons, waits for your choice
4. **Execute** — generates a single shell script that does all Mac-side work safely
5. **Resource Access** — walks through sharing/granting access to the target resource
6. **Verify** — runs 4 tests (tool discovery, read, write, delete) before declaring success
7. **Handoff** — updates Claude Project instructions, offers a setup reference file

---

## Why This Exists

Most MCP setup instructions assume a clean environment and a linear path. They don't account for:

- uvx not being installed
- Claude Desktop needing absolute paths (not just `uvx`)
- Config files that already have other servers
- Resources that must be explicitly shared with the MCP's identity
- The difference between a window close and a full Cmd+Q quit

This skill handles all of it.

---

## Supported MCPs

Full reference files (exact steps, gotchas, verified config):
- **Google Sheets** — including the `deleteDimension` pattern for physical row deletion

Stubs ready to expand after first install (20 total):

| Service | Auth | Runtime |
|---|---|---|
| Google Drive | Service Account | uvx |
| Google Calendar | Service Account / OAuth | uvx |
| Gmail | OAuth | uvx |
| GitHub | PAT | npx |
| GitLab | PAT | npx |
| Notion | OAuth / API Key | npx |
| Linear | API Key | npx |
| Slack | OAuth | npx |
| Jira / Confluence | PAT | uvx |
| Postgres | No Auth | npx |
| SQLite | No Auth | uvx |
| Filesystem | No Auth | npx |
| Brave Search | API Key | npx |
| Puppeteer | No Auth | npx |
| Sentry | API Key | uvx |
| HubSpot | API Key | npx |
| Shopify | API Key | uvx |
| Airtable | API Key | uvx |
| Asana | PAT / OAuth | uvx |

Any MCP not on this list is handled by the generic flow — fetch the docs, determine runtime and auth, follow the same 7 phases.

---

## Auth Types Supported

The skill explains each option with pros, cons, and setup complexity before asking you to choose:

- **Service Account** — JSON key file, best for Google APIs
- **OAuth** — browser login, best for Notion/Slack/Gmail
- **API Key** — single string, best for Linear/Sentry/HubSpot
- **PAT (Personal Access Token)** — scoped token, best for GitHub/GitLab/Jira
- **No Auth** — local resources (filesystem, SQLite, local Postgres)

---

## Key Failure Modes It Prevents

| Failure | How the skill prevents it |
|---|---|
| `uvx` short name in config | Pre-flight captures absolute path, script uses it |
| Config overwrite | Merge logic required — existing servers always preserved |
| Tilde in JSON paths | Blocked by config-writer rules — full path always used |
| Missing resource sharing | Phase 5 explicitly walks through it before verification |
| Window close instead of Cmd+Q | Called out explicitly at verification phase |
| No verification before declaring success | 4 tests must pass — read, write, delete, tool discovery |
| Wrong deletion method (Sheets) | `deleteDimension` pattern documented in google-sheets.md |

---

## File Structure

```
mcp-installer/
├── SKILL.md                              # Orchestration — all 7 phases
└── references/
    ├── environment-profiles.md           # How to read pre-flight output
    ├── auth-patterns.md                  # All 5 auth types with pros/cons
    ├── shell-script-builder.md           # Rules for safe Mac shell scripts
    ├── config-writer.md                  # Config rules, merge logic, JSON validation
    ├── verification-tests.md             # 4-test verification sequence
    ├── error-diagnosis.md                # Symptom → cause → fix lookup
    └── known-mcps/
        ├── INDEX.md                      # All supported MCPs at a glance
        ├── google-sheets.md              # Full reference
        └── [18 stub files]               # Expand after first install
```

---

## Installation

### Option 1 — Install the packaged skill (easiest)

Download `mcp-installer.skill` from [Releases](../../releases) and upload it:

1. Go to **claude.ai → Settings → Skills**
2. Click **Upload Skill**
3. Select `mcp-installer.skill`

### Option 2 — Build from source

```bash
git clone https://github.com/[yourhandle]/mcp-installer-skill
cd mcp-installer-skill

# Package the skill
python3 scripts/package_skill.py mcp-installer/ ./dist

# Upload dist/mcp-installer.skill via claude.ai Settings → Skills
```

### Option 3 — Org-wide install (Claude Team plan)

1. Go to **claude.ai → Admin Settings → Skills**
2. Upload `mcp-installer.skill`
3. Available to everyone in your org immediately

---

## Usage

Once installed, trigger it by saying:

- *"Set up the Google Sheets MCP"*
- *"Install MCP for GitHub"*
- *"Connect Claude Desktop to Notion"*
- *"I want Claude to access my Postgres database"*
- *"Configure an MCP server for Linear"*

Claude will run the 7-phase process, ask only what it needs to know, and not declare success until everything is verified.

---

## Expanding a Stub

After successfully installing a stub MCP for the first time, Claude will offer to generate a reference file. Accept — it captures the exact working config, any non-obvious steps, and the verification prompts that worked. This makes the next install of that MCP instant.

To add it back to the skill: open `references/known-mcps/[name].md`, replace the stub content with the generated reference, rebuild the `.skill` file.

---

## Contributing

The most useful contributions are **completed reference files** for stub MCPs. If you've successfully installed Notion, Linear, Slack, or any other stub MCP using this skill, open a PR with the completed reference file. Include:

- Exact working config block
- Steps that weren't obvious from the official docs
- Resource sharing step (if applicable)
- Verification prompts that worked
- Any errors you hit and their fixes

---

## Background

Built at [Distinct Origins Private Limited](https://almondhouse.in) during the setup of a natural language scheduling system for Delhi store openings. The Google Sheets MCP was the first install — every failure mode in the error-diagnosis file was hit in that session.

---

## License

MIT
