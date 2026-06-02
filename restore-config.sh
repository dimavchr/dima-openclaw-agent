#!/usr/bin/env bash
# Restore openclaw.json to the Hetzner server from the template + secrets.
# Run this locally after cloning the repo on a new machine.
#
# Usage: ./restore-config.sh
# Requires: hetzner-credentials.md with all secrets filled in, ssh access to the server.

set -euo pipefail

SERVER="root@49.13.76.210"
TEMPLATE="openclaw.json.template"
DEST="/root/.openclaw/openclaw.json"

# ── Read secrets from hetzner-credentials.md ─────────────────────────────────
# Edit these lines to match however you prefer to supply secrets.
# Option 1: export them as env vars before running this script.
# Option 2: hardcode paths to a local secrets file (gitignored).

: "${GATEWAY_TOKEN:?Set GATEWAY_TOKEN}"
: "${TELEGRAM_BOT_TOKEN:?Set TELEGRAM_BOT_TOKEN}"
: "${TELEGRAM_OWNER_ID:?Set TELEGRAM_OWNER_ID}"
: "${TELEGRAM_OWNER_ID_2:?Set TELEGRAM_OWNER_ID_2}"
: "${OPENROUTER_API_KEY:?Set OPENROUTER_API_KEY}"
: "${DEEPSEEK_API_KEY:?Set DEEPSEEK_API_KEY}"
: "${GOOGLE_API_KEY:?Set GOOGLE_API_KEY}"

# ── Substitute placeholders ───────────────────────────────────────────────────
CONFIG=$(cat "$TEMPLATE")
CONFIG="${CONFIG//__GATEWAY_TOKEN__/$GATEWAY_TOKEN}"
CONFIG="${CONFIG//__TELEGRAM_BOT_TOKEN__/$TELEGRAM_BOT_TOKEN}"
CONFIG="${CONFIG//__TELEGRAM_OWNER_ID__/$TELEGRAM_OWNER_ID}"
CONFIG="${CONFIG//__TELEGRAM_OWNER_ID_2__/$TELEGRAM_OWNER_ID_2}"
CONFIG="${CONFIG//__OPENROUTER_API_KEY__/$OPENROUTER_API_KEY}"
CONFIG="${CONFIG//__DEEPSEEK_API_KEY__/$DEEPSEEK_API_KEY}"
CONFIG="${CONFIG//__GOOGLE_API_KEY__/$GOOGLE_API_KEY}"

# ── Push to server ────────────────────────────────────────────────────────────
echo "$CONFIG" | ssh "$SERVER" "cat > $DEST && chmod 600 $DEST"
ssh "$SERVER" "cd /opt/openclaw && docker compose restart"

echo "Config restored and container restarted."
