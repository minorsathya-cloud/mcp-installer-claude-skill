# Environment Profiles

Read the pre-flight output and build a profile before any setup begins.

## Parsing the Output

### Runtimes section
Extract:
- `uvx`: installed or not. If installed, note the version.
- `node`: installed or not. Note the version — some MCPs require Node 18+.
- `python3`: installed or not. Note the version — some MCPs require 3.10+.

### Claude Config section
Three possible states:
1. **FILE MISSING** — config doesn't exist yet. Script must create it with full JSON structure.
2. **Empty `{}`** — config exists but has no servers. Script must add `mcpServers` key.
3. **Has existing servers** — config has other MCPs already configured. Script must MERGE, never overwrite. Extract the existing `mcpServers` object and add the new server to it.

### Paths section
- Capture the absolute path to `uvx` (e.g. `/Users/apple/.local/bin/uvx`)
- Capture the absolute path to `node` (e.g. `/usr/local/bin/node` or `/Users/x/.nvm/versions/node/v20.0.0/bin/node`)
- **These exact paths go into the config — never the short command name.**

### System section
- `arm64` = Apple Silicon (M1/M2/M3). Note: some packages have different install commands for arm64 vs x86_64.
- `x86_64` = Intel Mac.

### Identity section
- Capture `USER` and `HOME`. Use `HOME` to construct all absolute paths in the config and script.
- Never hardcode `/Users/apple/` — always use the actual `$HOME` value from this output.

---

## Environment Profiles → Shortest Path

### Profile A: Clean Mac, nothing installed
- uvx: NOT INSTALLED
- config: FILE MISSING
- **Path:** Install uvx → write fresh config → place credentials → share resource → verify

### Profile B: uvx installed, no config
- uvx: installed, path known
- config: FILE MISSING
- **Path:** Write fresh config using absolute uvx path → place credentials → share resource → verify

### Profile C: uvx installed, config exists (no servers)
- uvx: installed
- config: exists, empty
- **Path:** Add `mcpServers` block to config → place credentials → share resource → verify

### Profile D: uvx installed, config exists (has other servers) ← most common
- uvx: installed
- config: has existing MCPs
- **Path:** Merge new server into existing `mcpServers` → place credentials → share resource → verify
- **Critical:** preserve all existing server entries. Only add the new one.

### Profile E: Node-based MCP, node installed
- node: installed, version adequate
- **Path:** Use npx or global npm install → config with absolute node path → verify

### Profile F: Node-based MCP, node not installed
- node: NOT INSTALLED
- **Path:** Install node via nvm (not homebrew — avoids PATH issues with Claude Desktop) → then Profile E

### Profile G: Python-based MCP, python installed
- python3: installed, version adequate
- **Path:** Use uvx (preferred) or pip install → config → verify

---

## Runtime Requirements by MCP Type

| Runtime | Minimum Version | Install command |
|---|---|---|
| uvx | any | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| node (via nvm) | 18.0.0 | `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh \| bash && nvm install 20` |
| python3 | 3.10 | Usually pre-installed on Mac. If not: `brew install python3` |

Always prefer uvx for Python-based MCPs — it handles virtual environments automatically.

---

## Config Merge Template

When config already has servers, merge like this:

**Existing config:**
```json
{
  "mcpServers": {
    "existing-server": {
      "command": "/usr/local/bin/node",
      "args": ["path/to/server.js"]
    }
  }
}
```

**After merge (add new server, preserve existing):**
```json
{
  "mcpServers": {
    "existing-server": {
      "command": "/usr/local/bin/node",
      "args": ["path/to/server.js"]
    },
    "new-server": {
      "command": "/Users/x/.local/bin/uvx",
      "args": ["new-mcp-package@latest"],
      "env": {
        "KEY": "value"
      }
    }
  }
}
```

Never touch keys outside `mcpServers`. Never remove existing servers.
