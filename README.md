# openclaw-deploy

Deployment configuration for **DAISHA** — a personal AI assistant running [OpenClaw](https://openclaw.ai) on a Hetzner VPS.

## What's in this repo

| File | Purpose |
|---|---|
| `hetzner-setup-guide.md` | Step-by-step guide to provision a new server from scratch |
| `openclaw.json.template` | OpenClaw config with secrets redacted — the source of truth for agent structure |
| `restore-config.sh` | Script to fill secrets into the template and push to the server |
| `fly.toml` | Legacy Fly.io config (superseded by Hetzner) |

**Not committed (gitignored):**
- `hetzner-credentials.md` — all secrets and credentials, keep this safe locally
- `.env` — Docker Compose secrets

---

## Prerequisites

- SSH access to the server (`ssh root@49.13.76.210`)
- All secrets from `hetzner-credentials.md`
- Docker installed on the server (covered in setup guide step 3)

---

## Setting up a new server from scratch

Follow `hetzner-setup-guide.md` steps 1–11, then run:

```bash
# Clone this repo locally
git clone <this-repo-url>
cd openclaw-deploy

# Export all secrets (get values from hetzner-credentials.md or your password manager)
export GATEWAY_TOKEN="..."
export TELEGRAM_BOT_TOKEN="..."
export TELEGRAM_OWNER_ID="..."        # your Telegram user ID
export TELEGRAM_OWNER_ID_2="..."      # second owner ID (optional)
export OPENROUTER_API_KEY="..."
export DEEPSEEK_API_KEY="..."
export GOOGLE_API_KEY="..."

# Push config to server and restart
./restore-config.sh
```

Then re-approve Telegram pairing on the server:

```bash
ssh root@49.13.76.210 'cd /opt/openclaw && \
  docker compose exec openclaw-gateway node dist/index.js pairing approve telegram <TELEGRAM_OWNER_ID>'
```

---

## Restoring config after a change

If you've manually edited the config on the server and want to snapshot it back to the template:

```bash
# Pull current live config
ssh root@49.13.76.210 'cat /root/.openclaw/openclaw.json'
```

Manually update `openclaw.json.template` with any structural changes (model list, fallback chain, channel settings), keeping `__PLACEHOLDER__` values for all secrets. Then commit.

---

## Backing up agent history

Agent conversation history lives at `/root/.openclaw/agents/` on the server. Config, memory, and sessions are all here.

```bash
# Backup to local machine
ssh root@49.13.76.210 'tar czf /tmp/openclaw-backup.tar.gz /root/.openclaw --exclude=/root/.openclaw/agents/*/sessions --exclude=/root/.openclaw/logs'
scp root@49.13.76.210:/tmp/openclaw-backup.tar.gz ./openclaw-backup-$(date +%Y%m%d).tar.gz

# Restore on a new server (after running restore-config.sh)
scp openclaw-backup-YYYYMMDD.tar.gz root@<new-server>:/tmp/
ssh root@<new-server> 'tar xzf /tmp/openclaw-backup.tar.gz -C / && chown -R 1000:1000 /root/.openclaw'
```

Sessions are excluded from the backup — they are large transcripts that don't survive model/config changes cleanly anyway. The agent's memory (stored in `agents/main/agent/`) and auth profiles are included.

---

## Day-to-day management

```bash
# SSH tunnel to access the UI
ssh -N -L 18789:127.0.0.1:18789 root@49.13.76.210
# then open http://127.0.0.1:18789/

# Update to latest OpenClaw image
ssh root@49.13.76.210 'cd /opt/openclaw && docker compose pull && docker compose up -d'

# View live logs
ssh root@49.13.76.210 'cd /opt/openclaw && docker compose logs -f'

# Fix stuck Telegram spool (bot stops responding after a hard restart)
ssh root@49.13.76.210 'rm -f /root/.openclaw/telegram/ingress-spool-default/*.processing'
```

---

## Model configuration

Current fallback chain (edit `openclaw.json.template` to change defaults):

1. `openrouter/meta-llama/llama-3.3-70b-instruct:free` — primary, no cost
2. `openrouter/google/gemma-4-31b-it:free` — fallback, no cost
3. `deepseek/deepseek-chat` — fallback, paid (api.deepseek.com)
4. `google/gemini-3.1-flash-lite` — last resort, daily rate limit applies

Free OpenRouter models require no credits but are shared-tier — expect occasional slowness. Add an Anthropic API key for the most reliable experience.

---

## Server details

| Field | Value |
|---|---|
| Provider | Hetzner Cloud |
| Instance | CPX22 (3 vCPU, 4 GB RAM, ~€10/mo) |
| Location | Falkenstein (`fsn1`) |
| OS | Ubuntu 26.04 LTS |
| IP | `49.13.76.210` |
| Config dir | `/root/.openclaw/` |
| Compose dir | `/opt/openclaw/` |
