#!/bin/bash
# Creates a double-clickable .app on Mac that runs the DOPL MCP installer

APP_NAME="DOPL MCP Installer"
APP_DIR="$HOME/Downloads/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS" "$RESOURCES"

# ── Info.plist ────────────────────────────────────────────────────────────────
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>CFBundleIdentifier</key>
  <string>com.dopl.mcp-installer</string>
  <key>CFBundleName</key>
  <string>DOPL MCP Installer</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
PLIST

# ── Main launcher script ──────────────────────────────────────────────────────
cat > "$MACOS/launcher" << 'LAUNCHER'
#!/bin/bash
# Open a Terminal window and run the installer inside it
osascript << 'APPLESCRIPT'
tell application "Terminal"
  activate
  do script "curl -fsSL https://raw.githubusercontent.com/minorsathya-cloud/mcp-installer-claude-skill/main/install-dopl-mcp.sh -o /tmp/install-dopl-mcp.sh && bash /tmp/install-dopl-mcp.sh"
end tell
APPLESCRIPT
LAUNCHER

chmod +x "$MACOS/launcher"

echo "✓ App created at: $APP_DIR"
echo ""
echo "To use:"
echo "  1. Go to ~/Downloads"
echo "  2. Double-click 'DOPL MCP Installer'"
echo "  3. If Mac blocks it: right-click → Open → Open anyway"
