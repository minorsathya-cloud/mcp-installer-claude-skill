#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# DOPL — MCP Setup Installer
# Installs the mcp-installer Claude skill + Google Sheets MCP for Claude Desktop
# Run with: bash install-dopl-mcp.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}DOPL — Claude MCP Setup${RESET}"
echo "─────────────────────────────────────────────────────"
echo "This script will:"
echo "  1. Install the mcp-installer Claude skill"
echo "  2. Install the Google Sheets MCP for Claude Desktop"
echo "  3. Verify everything is configured correctly"
echo ""
echo -e "${YELLOW}You will need:${RESET}"
echo "  • Your Google Service Account credentials JSON file"
echo "  • Claude Desktop installed on this Mac"
echo "  • Internet connection"
echo ""
read -p "Press Enter to start, or Ctrl+C to cancel..."

# ── ENVIRONMENT CHECK ────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 1 — Checking environment...${RESET}"

OS_ARCH=$(uname -m)
HOME_DIR="$HOME"
USERNAME=$(whoami)
echo "  Mac architecture: $OS_ARCH"
echo "  Home directory:   $HOME_DIR"
echo "  User:             $USERNAME"

# Check Claude Desktop
CLAUDE_CONFIG_DIR="$HOME_DIR/Library/Application Support/Claude"
CLAUDE_CONFIG="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
  echo -e "  ${GREEN}✓ Claude Desktop found${RESET}"
else
  echo -e "  ${RED}✗ Claude Desktop not found at expected location${RESET}"
  echo "    Please install Claude Desktop from https://claude.ai/download and re-run this script."
  exit 1
fi

# ── INSTALL UVX ──────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 2 — Checking uvx (Python package runner)...${RESET}"

if which uvx >/dev/null 2>&1; then
  UVX_PATH=$(which uvx)
  echo -e "  ${GREEN}✓ uvx already installed at $UVX_PATH${RESET}"
else
  echo "  Installing uv/uvx..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Source the new path
  source "$HOME_DIR/.cargo/env" 2>/dev/null || true
  source "$HOME_DIR/.local/bin/env" 2>/dev/null || true
  export PATH="$HOME_DIR/.local/bin:$PATH"

  if which uvx >/dev/null 2>&1; then
    UVX_PATH=$(which uvx)
    echo -e "  ${GREEN}✓ uvx installed at $UVX_PATH${RESET}"
  else
    echo -e "  ${RED}✗ uvx installation failed.${RESET}"
    echo "    Try manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
  fi
fi

# ── CREDENTIALS FILE ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 3 — Google Service Account credentials${RESET}"
echo ""
echo "  You need a Google Service Account JSON credentials file."
echo "  This file gives Claude access to the Delhi Openings Google Sheet."
echo ""
echo "  If you already have it, enter the full path below."
echo "  Example: /Users/$USERNAME/Downloads/delhi-sheets-credentials.json"
echo ""

while true; do
  read -p "  Path to credentials JSON file: " CREDS_INPUT
  # Expand tilde manually
  CREDS_PATH="${CREDS_INPUT/#\~/$HOME_DIR}"

  if [ -f "$CREDS_PATH" ]; then
    # Validate it looks like a service account JSON
    if python3 -c "import json; d=json.load(open('$CREDS_PATH')); assert 'client_email' in d" 2>/dev/null; then
      CLIENT_EMAIL=$(python3 -c "import json; print(json.load(open('$CREDS_PATH'))['client_email'])")
      echo -e "  ${GREEN}✓ Valid credentials file found${RESET}"
      echo "    Service account: $CLIENT_EMAIL"
      break
    else
      echo -e "  ${RED}✗ File found but doesn't look like a valid service account JSON.${RESET}"
      echo "    Make sure you downloaded the JSON key from Google Cloud → IAM → Service Accounts."
    fi
  else
    echo -e "  ${RED}✗ File not found at: $CREDS_PATH${RESET}"
    echo "    Please check the path and try again."
  fi
done

# Copy credentials to a stable location
STABLE_CREDS="$HOME_DIR/dopl-sheets-credentials.json"
if [ "$CREDS_PATH" != "$STABLE_CREDS" ]; then
  cp "$CREDS_PATH" "$STABLE_CREDS"
  echo "  Copied to stable location: $STABLE_CREDS"
fi
chmod 600 "$STABLE_CREDS"
echo -e "  ${GREEN}✓ Credentials file secured (permissions: 600)${RESET}"

# ── CONFIGURE CLAUDE DESKTOP ─────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 4 — Configuring Claude Desktop...${RESET}"

mkdir -p "$CLAUDE_CONFIG_DIR"

NEW_SERVER_KEY="google-sheets"
NEW_SERVER_JSON="{
  \"command\": \"$UVX_PATH\",
  \"args\": [\"mcp-google-sheets@latest\"],
  \"env\": {
    \"GOOGLE_APPLICATION_CREDENTIALS\": \"$STABLE_CREDS\"
  }
}"

if [ ! -f "$CLAUDE_CONFIG" ]; then
  # Create fresh config
  echo "{\"mcpServers\":{\"$NEW_SERVER_KEY\":$NEW_SERVER_JSON}}" | \
    python3 -m json.tool > "$CLAUDE_CONFIG"
  echo -e "  ${GREEN}✓ Created new Claude Desktop config${RESET}"
else
  # Merge into existing config
  python3 - <<PYEOF
import json

config_path = "$CLAUDE_CONFIG"
with open(config_path) as f:
    config = json.load(f)

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"]["$NEW_SERVER_KEY"] = $NEW_SERVER_JSON

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

existing = [k for k in config["mcpServers"] if k != "$NEW_SERVER_KEY"]
if existing:
    print(f"  Existing servers preserved: {existing}")
print("  ✓ Merged google-sheets into Claude Desktop config")
PYEOF
  echo -e "  ${GREEN}✓ Claude Desktop config updated${RESET}"
fi

# Validate JSON
if python3 -m json.tool "$CLAUDE_CONFIG" >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓ Config JSON is valid${RESET}"
else
  echo -e "  ${RED}✗ Config JSON is invalid — something went wrong${RESET}"
  echo "    Check: $CLAUDE_CONFIG"
  exit 1
fi

# ── DOWNLOAD AND INSTALL THE CLAUDE SKILL ────────────────────────────────────
echo ""
echo -e "${BOLD}Step 5 — Downloading mcp-installer Claude skill...${RESET}"

SKILL_URL="https://github.com/minorsathya-cloud/mcp-installer-claude-skill/releases/latest/download/mcp-installer.skill"
SKILL_DEST="$HOME_DIR/Downloads/mcp-installer.skill"

if curl -fsSL "$SKILL_URL" -o "$SKILL_DEST" 2>/dev/null; then
  echo -e "  ${GREEN}✓ Skill downloaded to $SKILL_DEST${RESET}"
else
  echo -e "  ${YELLOW}⚠ Could not auto-download the skill file.${RESET}"
  echo "    Download it manually from:"
  echo "    https://github.com/minorsathya-cloud/mcp-installer-claude-skill/releases/latest"
  echo "    Save as: mcp-installer.skill"
  SKILL_DEST=""
fi

# ── SUMMARY ──────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────"
echo -e "${BOLD}${GREEN}Setup Complete!${RESET}"
echo "─────────────────────────────────────────────────────"
echo ""
echo -e "${GREEN}✓ uvx:${RESET}         $UVX_PATH"
echo -e "${GREEN}✓ Credentials:${RESET} $STABLE_CREDS"
echo -e "${GREEN}✓ Config:${RESET}      $CLAUDE_CONFIG"
echo -e "${GREEN}✓ Sheet access:${RESET} Share your Google Sheet with:"
echo "               $CLIENT_EMAIL"
echo "               (give Editor access)"
echo ""
if [ -n "$SKILL_DEST" ]; then
  echo -e "${BOLD}One manual step — install the Claude skill:${RESET}"
  echo "  1. Go to claude.ai → Settings → Skills"
  echo "  2. Click Upload Skill"
  echo "  3. Select: $SKILL_DEST"
  echo ""
fi
echo -e "${BOLD}Then restart Claude Desktop:${RESET}"
echo "  Press Cmd+Q to fully quit, then relaunch."
echo ""
echo -e "${BOLD}Verify it worked:${RESET}"
echo "  Open a new Claude chat and ask:"
echo "  \"What tools do you have available?\""
echo "  You should see Google Sheets tools listed."
echo ""
echo -e "${BOLD}Important reminder:${RESET}"
echo "  Share the Delhi Openings Google Sheet with:"
echo "  $CLIENT_EMAIL"
echo "  as Editor — otherwise Claude can read but not write."
echo ""
echo "─────────────────────────────────────────────────────"
