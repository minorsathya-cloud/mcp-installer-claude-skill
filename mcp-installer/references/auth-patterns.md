# Auth Patterns

## How to Present Auth Options to the User

When auth selection is needed, explain the relevant options clearly. Use this template:

> "This MCP supports [N] ways to authenticate. Here's what each means:"
> [present relevant options from below]
> "Which would you like to use?"

Only present options that are actually supported by the MCP being installed. Don't list all five for every MCP.

---

## Auth Type 1: Service Account (JSON Key File)

**What it is:** A machine identity created in Google Cloud (or similar). You download a JSON file containing credentials. The MCP uses this file to authenticate — no human login required.

**Best for:** Google APIs (Sheets, Drive, Calendar, Gmail), GCP services.

**Pros:**
- Runs headlessly — no browser login, no tokens to refresh
- Works even if you're logged out of Google
- Scoped to exactly what you share with it
- Easy to revoke — just delete the service account

**Cons:**
- Requires a Google Cloud project (free, but takes 5 min to set up)
- You must explicitly share each resource (Sheet, Drive folder, etc.) with the service account email
- JSON key file must be kept secure — treat it like a password
- If lost, you generate a new key (no real recovery needed)

**Setup complexity:** Medium — 5-10 min one-time setup in Google Cloud Console.

**Setup steps:**
1. Go to console.cloud.google.com → create or select a project
2. Enable the relevant API (e.g. Google Sheets API, Google Drive API)
3. IAM & Admin → Service Accounts → Create Service Account
4. Download the JSON key file
5. Place the file at a stable absolute path (e.g. `~/[project]-credentials.json`)
6. Share the target resource with the `client_email` from the JSON file as Editor

**Config pattern:**
```json
{
  "command": "/absolute/path/to/uvx",
  "args": ["mcp-package@latest"],
  "env": {
    "GOOGLE_APPLICATION_CREDENTIALS": "/absolute/path/to/credentials.json"
  }
}
```

---

## Auth Type 2: OAuth (Browser-Based Login)

**What it is:** You log in with your own account via a browser popup. The MCP gets a token that acts on your behalf.

**Best for:** Notion, Slack, Atlassian, any service where you want Claude to act as you.

**Pros:**
- Uses your existing account — no separate credentials to manage
- No JSON files to handle
- Permissions match exactly what your account can access

**Cons:**
- Tokens expire — you may need to re-authenticate periodically
- Requires a browser step during setup (and again when token expires)
- Slightly more complex initial flow
- If your account permissions change, MCP access changes too

**Setup complexity:** Low-Medium — 2-5 min, but requires browser interaction.

**Setup steps:**
1. Configure MCP in Claude Desktop config (usually just the package + client ID)
2. On first use, Claude Desktop will open a browser window
3. Log in with your account and grant permissions
4. Token is stored locally — auto-refreshes until it expires

**Config pattern:**
```json
{
  "command": "/absolute/path/to/uvx",
  "args": ["mcp-package@latest"],
  "env": {
    "CLIENT_ID": "your-oauth-client-id",
    "CLIENT_SECRET": "your-oauth-client-secret"
  }
}
```

---

## Auth Type 3: API Key

**What it is:** A single string (usually 32-64 characters) that you copy from the service's settings page and paste into the config.

**Best for:** Linear, Anthropic API, OpenAI, weather APIs, most simple SaaS tools.

**Pros:**
- Simplest setup — copy, paste, done
- No files to manage, no browser login
- Usually available immediately from account settings

**Cons:**
- A single string with no expiry (unless you set one) — if leaked, it grants access until revoked
- Less granular than OAuth scopes in some services
- Must be regenerated and reconfigured if rotated

**Setup complexity:** Very low — 1-2 min.

**Setup steps:**
1. Go to the service's API settings page
2. Generate or copy your API key
3. Add it to the config as an environment variable

**Config pattern:**
```json
{
  "command": "/absolute/path/to/uvx",
  "args": ["mcp-package@latest"],
  "env": {
    "API_KEY": "your-api-key-here"
  }
}
```

---

## Auth Type 4: Personal Access Token (PAT)

**What it is:** Like an API key, but tied to your personal account and typically scoped to specific permissions (read issues, write PRs, etc.).

**Best for:** GitHub, GitLab, Jira, Confluence, Bitbucket.

**Pros:**
- Scoped — you choose exactly what access to grant
- Revocable without affecting other credentials
- Can set an expiry date for security
- Shows up in audit logs as you

**Cons:**
- Expires if you set a date — must be regenerated and reconfigured
- Slightly more setup than an API key (you must choose the right scopes)
- Wrong scopes = silent failures ("not found" instead of "unauthorized")

**Setup complexity:** Low — 3-5 min including choosing scopes.

**Setup steps:**
1. Go to account settings → Developer settings → Personal Access Tokens
2. Create a new token, select the required scopes (see known-MCP reference file for the exact scopes needed)
3. Copy the token immediately — it's only shown once
4. Add to config as environment variable

**Config pattern:**
```json
{
  "command": "/absolute/path/to/node",
  "args": ["/absolute/path/to/mcp-server.js"],
  "env": {
    "GITHUB_TOKEN": "ghp_your-token-here"
  }
}
```

---

## Auth Type 5: No Auth

**What it is:** The MCP connects to a local resource (files, local database, local server) and needs no credentials.

**Best for:** Filesystem MCP, SQLite, local Postgres, any localhost service.

**Pros:**
- Zero setup — just configure the path
- No credentials to manage or secure
- Instant

**Cons:**
- Only works with local resources — nothing in the cloud
- Security boundary is your Mac login, not a service credential

**Setup complexity:** Minimal — just a path in the config.

**Config pattern:**
```json
{
  "command": "/absolute/path/to/uvx",
  "args": ["mcp-package@latest", "--path", "/absolute/path/to/resource"]
}
```

---

## Quick Selection Guide

| MCP target | Recommended auth |
|---|---|
| Google Sheets / Drive / Calendar | Service Account |
| Notion | OAuth |
| Slack | OAuth |
| GitHub | PAT |
| GitLab | PAT |
| Linear | API Key |
| Jira / Confluence | PAT or API Key |
| Postgres / SQLite | No Auth (local) |
| Custom REST API | API Key |
| Anthropic / OpenAI | API Key |
| Local filesystem | No Auth |
