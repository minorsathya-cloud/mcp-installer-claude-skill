# Known MCPs — Index

When a user names an MCP from this list, load the corresponding reference file for exact steps, gotchas, and verification patterns.

If the MCP is not listed here, proceed with the generic flow in SKILL.md — fetch the docs URL, read them, determine runtime and auth type, then follow the standard phases.

---

| MCP / Service | Package / Install | Runtime | Auth Type | Reference File |
|---|---|---|---|---|
| Google Sheets | `mcp-google-sheets@latest` | uvx | Service Account | `google-sheets.md` |
| Google Drive | `mcp-google-drive@latest` | uvx | Service Account | `google-drive.md` |
| Google Calendar | `mcp-google-calendar@latest` | uvx | Service Account or OAuth | `google-calendar.md` |
| Gmail | `mcp-gmail@latest` | uvx | OAuth | `gmail.md` |
| GitHub | `@modelcontextprotocol/server-github` | npx (Node) | PAT | `github.md` |
| GitLab | `@modelcontextprotocol/server-gitlab` | npx (Node) | PAT | `gitlab.md` |
| Notion | `@modelcontextprotocol/server-notion` | npx (Node) | OAuth or API Key | `notion.md` |
| Linear | `@linear/mcp-server` | npx (Node) | API Key | `linear.md` |
| Slack | `@modelcontextprotocol/server-slack` | npx (Node) | OAuth | `slack.md` |
| Jira / Confluence | `mcp-atlassian@latest` | uvx | PAT | `atlassian.md` |
| Postgres | `@modelcontextprotocol/server-postgres` | npx (Node) | No Auth (connection string) | `postgres.md` |
| SQLite | `mcp-server-sqlite@latest` | uvx | No Auth (file path) | `sqlite.md` |
| Filesystem | `@modelcontextprotocol/server-filesystem` | npx (Node) | No Auth (path) | `filesystem.md` |
| Brave Search | `@modelcontextprotocol/server-brave-search` | npx (Node) | API Key | `brave-search.md` |
| Puppeteer / Browser | `@modelcontextprotocol/server-puppeteer` | npx (Node) | No Auth | `puppeteer.md` |
| Sentry | `mcp-server-sentry@latest` | uvx | API Key | `sentry.md` |
| HubSpot | `@hubspot/mcp-server` | npx (Node) | API Key | `hubspot.md` |
| Shopify | `mcp-shopify@latest` | uvx | API Key | `shopify.md` |
| Airtable | `mcp-airtable@latest` | uvx | API Key | `airtable.md` |
| Asana | `mcp-asana@latest` | uvx | PAT or OAuth | `asana.md` |

---

## How to Handle Unknown MCPs

If the MCP is not in this index:

1. Ask the user for the docs URL or GitHub repo link
2. Fetch and read the docs — look for:
   - Install command (uvx, npx, pip, binary)
   - Required environment variables
   - Auth method
   - Any known limitations or gotchas
3. Determine which auth pattern from `auth-patterns.md` applies
4. Follow the generic flow in SKILL.md phases 2–7
5. After a successful install, offer to generate a reference file for this MCP so future installs are instant

---

## Runtime Quick Reference

| Runtime | Install command | Config `command` key |
|---|---|---|
| uvx | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | absolute path from `which uvx` |
| npx (Node) | `nvm install 20` | absolute path from `which npx` |
| pip / python | usually pre-installed | absolute path from `which python3` |
| binary | download and `chmod +x` | absolute path to the binary |
