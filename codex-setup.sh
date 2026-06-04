#!/usr/bin/env bash
#
# Codex relay one-click setup script
# Recommended usage (paste your API Key when prompted):
#   curl -fsSL https://your-domain/codex-setup.sh | bash
# Or pass the key as an argument (non-interactive):
#   curl -fsSL https://your-domain/codex-setup.sh | bash -s -- <API_KEY>
#   bash codex-setup.sh <API_KEY>
#
set -euo pipefail

# ============ Operator-editable config ============
RELAY_BASE_URL="https://codex.gogogpt.net"     # relay base_url (note: no /v1 suffix)
DEFAULT_MODEL="gpt-5.5"                          # default model
PROVIDER_ID="OpenAI"                             # provider id
PROVIDER_NAME="OpenAI"                           # provider display name
# ==================================================

CODEX_DIR="$HOME/.codex"
CONFIG_FILE="$CODEX_DIR/config.toml"
AUTH_FILE="$CODEX_DIR/auth.json"

# Whether Codex CLI is already installed
codex_installed() { command -v codex >/dev/null 2>&1; }

# Whether the terminal is truly interactive (can open /dev/tty).
# In CI / pure pipe it cannot, so we silently treat it as non-interactive.
tty_available() { { true < /dev/tty; } 2>/dev/null; }

# Read y/n. Works under curl|bash: stdin is the script itself there,
# so read real keyboard input from /dev/tty.
# When non-interactive (no tty) return non-zero (treated as No), so
# automation is never blocked.
prompt_yes_no() {
  local ans=""
  tty_available || return 1
  printf '%s' "$1" > /dev/tty
  read -r ans < /dev/tty 2>/dev/null || ans=""
  case "$ans" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# Get API Key: prefer the command-line argument; otherwise prompt interactively.
# Under curl|bash, stdin is taken by the script, so read from /dev/tty too.
API_KEY="${1:-}"
if [ -z "$API_KEY" ]; then
  if tty_available; then
    printf 'Paste your API Key and press Enter: ' > /dev/tty
    read -r API_KEY < /dev/tty 2>/dev/null || API_KEY=""
  fi
fi
# Trim surrounding whitespace
API_KEY="$(printf '%s' "$API_KEY" | tr -d '[:space:]')"
if [ -z "$API_KEY" ]; then
  echo "No API Key entered, aborted." >&2
  echo "Retry (interactive): curl -fsSL <script-url> | bash" >&2
  echo "Or pass it as arg:   bash codex-setup.sh <YOUR_API_KEY>" >&2
  exit 1
fi

mkdir -p "$CODEX_DIR"

# Back up existing config (compatible with macOS built-in bash 3.2)
ts="$(date +%Y%m%d%H%M%S)"
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$ts"
  echo "Backed up old config.toml -> config.toml.bak.$ts"
fi
if [ -f "$AUTH_FILE" ]; then
  cp "$AUTH_FILE" "$AUTH_FILE.bak.$ts"
  echo "Backed up old auth.json -> auth.json.bak.$ts"
fi

# Write config.toml
cat > "$CONFIG_FILE" <<EOF
model_provider = "$PROVIDER_ID"
model = "$DEFAULT_MODEL"
review_model = "$DEFAULT_MODEL"
model_reasoning_effort = "xhigh"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

[model_providers.$PROVIDER_ID]
name = "$PROVIDER_NAME"
base_url = "$RELAY_BASE_URL"
wire_api = "responses"
requires_openai_auth = true

[features]
goals = true
EOF

# Write auth.json (Codex reads OPENAI_API_KEY from here for auth)
cat > "$AUTH_FILE" <<EOF
{
  "OPENAI_API_KEY": "$API_KEY"
}
EOF
chmod 600 "$AUTH_FILE"

echo ""
echo "Setup complete"
echo "  config:   $CONFIG_FILE"
echo "  relay:    $RELAY_BASE_URL"
echo "  model:    $DEFAULT_MODEL"
echo ""

# Detect Codex CLI; if missing, prompt and try interactive install
if codex_installed; then
  echo "You can run it now: codex"
else
  echo "Note: Codex CLI is not installed yet; once installed it will use the config above."
  if command -v npm >/dev/null 2>&1; then
    if prompt_yes_no "Install Codex CLI globally via npm now? [y/N] "; then
      if npm install -g @openai/codex; then
        echo "Installed. Now run: codex"
      else
        echo "Install failed. Run manually: npm install -g @openai/codex"
      fi
    else
      echo "Install later manually: npm install -g @openai/codex"
    fi
  else
    echo "npm not found. Install Node.js first, then run one of:"
    echo "  npm install -g @openai/codex"
    echo "  brew install codex"
  fi
fi
