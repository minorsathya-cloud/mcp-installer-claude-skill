#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# DOPL — One-Click MCP Setup
# Installs the Google Sheets MCP + mcp-installer Claude skill
# ─────────────────────────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

clear
echo ""
echo -e "${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        DOPL — Claude MCP Setup             ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${RESET}"
echo ""
echo "This will set up two things on your Mac:"
echo ""
echo -e "  ${BLUE}1.${RESET} Google Sheets MCP — lets Claude read and write"
echo "     to the Delhi Openings scheduling sheet"
echo ""
echo -e "  ${BLUE}2.${RESET} MCP Installer skill — lets Claude install any"
echo "     future MCP tools without errors"
echo ""
echo -e "${YELLOW}Before you start, make sure you have:${RESET}"
echo "  • Claude Desktop open on this Mac"
echo "  • The credentials file Apoorv sent you"
echo "    (a file ending in .json)"
echo ""
read -p "Ready? Press Enter to begin..."

# ── STEP 1: Check Claude Desktop ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}[1/5] Checking Claude Desktop...${RESET}"

CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
  echo ""
  echo -e "${RED}✗ Claude Desktop is not installed.${RESET}"
  echo ""
  echo "  Please download it from: https://claude.ai/download"
  echo "  Install it, then run this script again."
  echo ""
  read -p "Press Enter to exit..."
  exit 1
fi
echo -e "  ${GREEN}✓ Claude Desktop found${RESET}"

# ── STEP 2: Install uvx ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[2/5] Checking package installer (uvx)...${RESET}"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if which uvx >/dev/null 2>&1; then
  UVX_PATH=$(which uvx)
  echo -e "  ${GREEN}✓ Already installed at $UVX_PATH${RESET}"
else
  echo "  Installing uvx — this takes about 30 seconds..."
  curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1
  source "$HOME/.local/bin/env" 2>/dev/null || true
  source "$HOME/.cargo/env" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

  if which uvx >/dev/null 2>&1; then
    UVX_PATH=$(which uvx)
    echo -e "  ${GREEN}✓ Installed at $UVX_PATH${RESET}"
  else
    echo -e "  ${RED}✗ Installation failed.${RESET}"
    echo "  Please contact Apoorv."
    read -p "Press Enter to exit..."
    exit 1
  fi
fi

# ── STEP 3: Credentials file ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[3/5] Setting up Google credentials...${RESET}"
echo ""
echo "  Apoorv should have sent you a file that ends in .json"
echo "  It is probably in your Downloads folder."
echo ""
echo "  Drag the file into this window and press Enter,"
echo "  or type the full path to it."
echo ""

STABLE_CREDS="$HOME/dopl-sheets-credentials.json"

# Check if already installed from a previous run
if [ -f "$STABLE_CREDS" ]; then
  if python3 -c "import json; d=json.load(open('$STABLE_CREDS')); assert 'client_email' in d" 2>/dev/null; then
    CLIENT_EMAIL=$(python3 -c "import json; print(json.load(open('$STABLE_CREDS'))['client_email'])")
    echo -e "  ${GREEN}✓ Credentials already set up from a previous install${RESET}"
    echo "    ($CLIENT_EMAIL)"
    SKIP_CREDS=true
  fi
fi

if [ -z "$SKIP_CREDS" ]; then
  while true; do
    read -p "  Path to .json file: " CREDS_INPUT
    # Strip quotes (from drag and drop) and expand tilde
    CREDS_INPUT="${CREDS_INPUT%\'}"
    CREDS_INPUT="${CREDS_INPUT#\'}"
    CREDS_INPUT="${CREDS_INPUT%\"}"
    CREDS_INPUT="${CREDS_INPUT#\"}"
    CREDS_PATH="${CREDS_INPUT/#\~/$HOME}"

    if [ ! -f "$CREDS_PATH" ]; then
      echo -e "  ${RED}✗ Can't find a file at that path. Try again.${RESET}"
      continue
    fi

    if ! python3 -c "import json; d=json.load(open('$CREDS_PATH')); assert 'client_email' in d" 2>/dev/null; then
      echo -e "  ${RED}✗ That doesn't look like the right file. It should be a Google credentials JSON.${RESET}"
      continue
    fi

    CLIENT_EMAIL=$(python3 -c "import json; print(json.load(open('$CREDS_PATH'))['client_email'])")
    cp "$CREDS_PATH" "$STABLE_CREDS"
    chmod 600 "$STABLE_CREDS"
    echo -e "  ${GREEN}✓ Credentials saved securely${RESET}"
    break
  done
fi

# ── STEP 4: Configure Claude Desktop ─────────────────────────────────────────
echo ""
echo -e "${BOLD}[4/5] Configuring Claude Desktop...${RESET}"

NEW_SERVER_JSON="{
  \"command\": \"$UVX_PATH\",
  \"args\": [\"mcp-google-sheets@latest\"],
  \"env\": {
    \"GOOGLE_APPLICATION_CREDENTIALS\": \"$STABLE_CREDS\"
  }
}"

mkdir -p "$CLAUDE_CONFIG_DIR"

if [ ! -f "$CLAUDE_CONFIG" ]; then
  echo "{\"mcpServers\":{\"google-sheets\":$NEW_SERVER_JSON}}" | \
    python3 -m json.tool > "$CLAUDE_CONFIG"
else
  python3 - << PYEOF
import json
with open("$CLAUDE_CONFIG") as f:
    config = json.load(f)
if "mcpServers" not in config:
    config["mcpServers"] = {}
config["mcpServers"]["google-sheets"] = $NEW_SERVER_JSON
with open("$CLAUDE_CONFIG", "w") as f:
    json.dump(config, f, indent=2)
PYEOF
fi

if python3 -m json.tool "$CLAUDE_CONFIG" >/dev/null 2>&1; then
  echo -e "  ${GREEN}✓ Claude Desktop configured${RESET}"
else
  echo -e "  ${RED}✗ Configuration file has an error. Please contact Apoorv.${RESET}"
  exit 1
fi

# ── STEP 5: Download Claude skill ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}[5/5] Downloading MCP Installer skill...${RESET}"

SKILL_URL="https://github.com/minorsathya-cloud/mcp-installer-claude-skill/releases/latest/download/mcp-installer.skill"
SKILL_DEST="$HOME/Downloads/mcp-installer.skill"

if curl -fsSL "$SKILL_URL" -o "$SKILL_DEST" 2>/dev/null; then
  echo -e "  ${GREEN}✓ Skill downloaded to Downloads folder${RESET}"
  SKILL_DOWNLOADED=true
else
  echo -e "  ${YELLOW}⚠ Could not download skill automatically${RESET}"
  echo "    You can get it from Apoorv or download it from:"
  echo "    github.com/minorsathya-cloud/mcp-installer-claude-skill/releases"
fi

# ── DONE ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║            Setup Complete! 🎉              ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}Two quick things to finish:${RESET}"
echo ""
echo -e "${BLUE}Thing 1 — Restart Claude Desktop${RESET}"
echo "  Press Cmd+Q to fully quit Claude Desktop"
echo "  Then reopen it"
echo "  (just closing the window is not enough)"
echo ""
if [ "$SKILL_DOWNLOADED" = true ]; then
echo -e "${BLUE}Thing 2 — Install the Claude skill${RESET}"
echo "  1. Go to claude.ai → Settings → Skills"
echo "  2. Click Upload Skill"
echo "  3. Select this file from your Downloads:"
echo "     mcp-installer.skill"
echo ""
fi
echo -e "${BOLD}To verify it worked:${RESET}"
echo "  Open a new Claude chat and type:"
echo "  \"What tools do you have available?\""
echo "  You should see Google Sheets tools in the list."
echo ""
echo -e "${YELLOW}Important — share the Sheet:${RESET}"
echo "  The scheduling sheet must be shared with:"
echo -e "  ${BOLD}$CLIENT_EMAIL${RESET}"
echo "  as Editor. Ask Apoorv if this hasn't been done."
echo ""
read -p "Press Enter to close..."
