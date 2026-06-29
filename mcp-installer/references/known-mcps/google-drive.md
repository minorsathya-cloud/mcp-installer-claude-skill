# Google Drive MCP

**Package:** `mcp-google-drive@latest`
**Runtime:** uvx
**Auth:** Service Account

---

## Status: Stub

This reference file is a placeholder. The generic install flow in SKILL.md applies.

When this MCP is installed for the first time, expand this file with:
- Exact setup steps specific to this service
- Required API scopes or permissions
- Any known gotchas or non-obvious steps
- Verified config block with correct args format
- Service-specific verification test prompts
- Common issues and fixes

---

## Quick Reference

**Install package:** `mcp-google-drive@latest`
**Runtime:** uvx
**Auth type:** Service Account — see `references/auth-patterns.md` for full explanation

**Config skeleton:**
```json
"google-drive": {
  "command": "/absolute/path/to/runtime",
  "args": ["mcp-google-drive@latest"],
  "env": {
    "REPLACE_WITH_CORRECT_ENV_VARS": "value"
  }
}
```

**To get exact env vars and args:** fetch and read the official docs or GitHub README for `mcp-google-drive@latest`.

---

## Expanding This Stub

After a successful install, document:
1. The exact working config block
2. Any steps that weren't obvious from the docs
3. The resource-sharing step (if applicable)
4. Verification test prompts that worked
5. Any errors encountered and their fixes

This becomes the reference for all future installs of this MCP.
