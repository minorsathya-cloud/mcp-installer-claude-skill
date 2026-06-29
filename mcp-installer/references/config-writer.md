# Config Writer

## claude_desktop_config.json — Rules

**Location (Mac):** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Location (Windows):** `%APPDATA%\Claude\claude_desktop_config.json`

Claude Desktop reads this file **only at launch**. After any change: Cmd+Q (full quit) and relaunch.

---

## Absolute Path Rule

Claude Desktop launches with a restricted system PATH that does not include `~/.local/bin`, `/usr/local/bin`, or nvm paths.

**Always use the absolute path from `which [command]`:**

```json
// ✗ WRONG — fails silently, MCP doesn't load
"command": "uvx"

// ✓ CORRECT — always works
"command": "/Users/apple/.local/bin/uvx"
```

Same rule applies to `node`, `python3`, `npx`, and any other runtime.

---

## Tilde in JSON

Tilde (`~`) does NOT expand inside JSON values. Always use the full path.

```json
// ✗ WRONG
"GOOGLE_APPLICATION_CREDENTIALS": "~/credentials.json"

// ✓ CORRECT
"GOOGLE_APPLICATION_CREDENTIALS": "/Users/apple/credentials.json"
```

---

## Valid Config Structure

```json
{
  "mcpServers": {
    "server-key-name": {
      "command": "/absolute/path/to/runtime",
      "args": ["package@version", "--optional-flag"],
      "env": {
        "ENV_VAR_NAME": "value"
      }
    }
  }
}
```

- `mcpServers` is the only required top-level key for MCP configuration
- `server-key-name` can be anything — use the MCP's package name or service name, lowercase with hyphens
- `env` is optional — only include if the MCP needs environment variables
- Valid JSON only — trailing commas will cause silent failure

---

## Merge Logic

When adding a new server to an existing config:

1. Read the existing file
2. Parse as JSON (fail loudly if invalid)
3. Add the new server key to `mcpServers`
4. Write back the full object

Never touch any keys outside `mcpServers`. Never remove existing servers.

---

## Common Config Examples

### uvx-based (Python MCP via uvx)
```json
{
  "mcpServers": {
    "google-sheets": {
      "command": "/Users/apple/.local/bin/uvx",
      "args": ["mcp-google-sheets@latest"],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/apple/delhi-sheets-credentials.json"
      }
    }
  }
}
```

### Node-based (npx)
```json
{
  "mcpServers": {
    "github": {
      "command": "/Users/apple/.nvm/versions/node/v20.11.0/bin/npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

### No auth (local filesystem)
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "/Users/apple/.local/bin/uvx",
      "args": ["mcp-server-filesystem", "/Users/apple/Documents"]
    }
  }
}
```

### Multiple servers (merged)
```json
{
  "mcpServers": {
    "google-sheets": {
      "command": "/Users/apple/.local/bin/uvx",
      "args": ["mcp-google-sheets@latest"],
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "/Users/apple/sheets-credentials.json"
      }
    },
    "github": {
      "command": "/Users/apple/.nvm/versions/node/v20.11.0/bin/npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

---

## Validation Before Saving

Always validate JSON before writing to the config file:

```bash
python3 -m json.tool config.json >/dev/null && echo "✓ Valid JSON" || echo "✗ Invalid JSON — do not save"
```

Invalid JSON in the config causes Claude Desktop to silently ignore all MCP servers at startup.
