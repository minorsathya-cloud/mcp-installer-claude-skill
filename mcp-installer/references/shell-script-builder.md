# Shell Script Builder

## Why Scripts, Not Direct Commands

Claude cannot run commands on the user's Mac directly. The Cowork sandbox and Claude Code both run on a Linux VM — `~/Library/`, `~/.local/`, and other Mac paths do not exist there. Every Mac-side operation must be packaged as a shell script the user runs in Terminal.

---

## Script Rules (enforce all of these)

### 1. Always use absolute paths
Pull the exact `HOME`, uvx path, and node path from the pre-flight output. Never use:
- `uvx` → use `/Users/apple/.local/bin/uvx`
- `~` in JSON values → use `/Users/apple/` (tilde doesn't expand in JSON)
- `node` → use the exact path from `which node`

### 2. Check before acting (idempotent)
Every install step must be safe to re-run:
```bash
# Good
which uvx >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh

# Bad
curl -LsSf https://astral.sh/uv/install.sh | sh  # installs again even if present
```

### 3. Print a status line after every step
```bash
if command; then
  echo "✓ [step description]"
else
  echo "✗ [step description]: $(error details)"
fi
```

### 4. Merge config, never overwrite
If the config file exists, read it and add to it. Never `cat > config.json` without checking first.

### 5. Set file permissions on credentials
```bash
chmod 600 ~/credentials.json
echo "✓ Credentials file permissions set (600)"
```

### 6. End with a summary block
```bash
echo ""
echo "=== SUMMARY ==="
echo "Paste this output back to Claude"
echo "uvx path: $(which uvx 2>/dev/null || echo NOT FOUND)"
echo "Config: $(cat ~/Library/Application\ Support/Claude/claude_desktop_config.json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(list(d.get(\"mcpServers\",{}).keys()))' 2>/dev/null || echo 'could not parse')"
echo "Credentials: $(ls -la ~/[credentials-file] 2>/dev/null || echo NOT FOUND)"
```

---

## Script Template

```bash
#!/bin/bash
set -e  # Stop on first error unless you handle errors explicitly

HOME_DIR="$HOME"
UVX_PATH=""  # Will be set after install

echo "=== MCP Installer: [MCP NAME] ==="
echo "Running on: $(uname -m) Mac, user: $(whoami)"
echo ""

# ── Step 1: Install uvx if missing ──────────────────────────────────────────
echo "Checking uvx..."
if which uvx >/dev/null 2>&1; then
  UVX_PATH=$(which uvx)
  echo "✓ uvx already installed at $UVX_PATH"
else
  echo "  Installing uv/uvx..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source "$HOME_DIR/.cargo/env" 2>/dev/null || true
  source "$HOME_DIR/.local/bin/env" 2>/dev/null || true
  if which uvx >/dev/null 2>&1; then
    UVX_PATH=$(which uvx)
    echo "✓ uvx installed at $UVX_PATH"
  else
    echo "✗ uvx install failed — please install manually and re-run"
    exit 1
  fi
fi

# ── Step 2: Place credentials file ──────────────────────────────────────────
# (Only include this block for Service Account auth)
CREDS_PATH="$HOME_DIR/[project]-credentials.json"
if [ -f "$CREDS_PATH" ]; then
  echo "✓ Credentials file already at $CREDS_PATH"
else
  echo "✗ Credentials file not found at $CREDS_PATH"
  echo "  Please download the service account JSON from Google Cloud and save it there"
  exit 1
fi
chmod 600 "$CREDS_PATH"
echo "✓ Credentials file permissions set (600)"

# ── Step 3: Write / merge Claude Desktop config ──────────────────────────────
CONFIG_DIR="$HOME_DIR/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

mkdir -p "$CONFIG_DIR"

NEW_SERVER_KEY="[server-key-name]"
NEW_SERVER_JSON='{
  "command": "'"$UVX_PATH"'",
  "args": ["[mcp-package]@latest"],
  "env": {
    "GOOGLE_APPLICATION_CREDENTIALS": "'"$CREDS_PATH"'"
  }
}'

if [ ! -f "$CONFIG_FILE" ]; then
  # Config doesn't exist — create fresh
  echo "{\"mcpServers\":{\"$NEW_SERVER_KEY\":$NEW_SERVER_JSON}}" | \
    python3 -m json.tool > "$CONFIG_FILE"
  echo "✓ Created new Claude Desktop config"
else
  # Config exists — merge new server in
  python3 - <<PYEOF
import json, sys

config_path = "$CONFIG_FILE"
with open(config_path) as f:
    config = json.load(f)

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"]["$NEW_SERVER_KEY"] = $NEW_SERVER_JSON

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print("✓ Merged $NEW_SERVER_KEY into existing Claude Desktop config")
print(f"  Existing servers preserved: {[k for k in config['mcpServers'] if k != '$NEW_SERVER_KEY']}")
PYEOF
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=== SUMMARY — paste this back to Claude ==="
echo "uvx: $UVX_PATH"
echo "credentials: $CREDS_PATH"
echo "config servers: $(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(list(c.get('mcpServers',{}).keys()))" 2>/dev/null || echo 'parse error')"
echo ""
echo "Next: Cmd+Q Claude Desktop and relaunch it."
```

---

## Node-Based MCP Script Variant

For MCPs that run as Node servers rather than uvx:

```bash
# Check node version
NODE_PATH=$(which node 2>/dev/null || echo "")
if [ -z "$NODE_PATH" ]; then
  echo "✗ Node not found. Install via nvm:"
  echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
  echo "  source ~/.zshrc && nvm install 20"
  exit 1
fi
NODE_VERSION=$(node --version | sed 's/v//')
MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
if [ "$MAJOR" -lt 18 ]; then
  echo "✗ Node $NODE_VERSION found but 18+ required. Run: nvm install 20"
  exit 1
fi
echo "✓ Node $NODE_VERSION at $NODE_PATH"
```

Use `$NODE_PATH` in the config `command` field — never just `node`.

---

## API Key Script Variant

No credentials file — just an env var in the config:

```bash
NEW_SERVER_JSON='{
  "command": "'"$UVX_PATH"'",
  "args": ["[mcp-package]@latest"],
  "env": {
    "API_KEY": "[user-pastes-key-here]"
  }
}'
```

Prompt the user to substitute their actual API key before running the script. Never ask them to paste it into the chat — they edit the script file directly.
