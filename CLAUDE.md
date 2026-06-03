# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is a **deployment configuration** repository for **DAISHA** — a personal AI assistant running [OpenClaw](https://openclaw.ai) on a Hetzner VPS. It does not contain application source code — it deploys a pre-built Docker image (`ghcr.io/openclaw/openclaw:latest`).

## Key files

- `openclaw.json.template` — OpenClaw config with secrets redacted; source of truth for agent structure.
- `restore-config.sh` — fills secrets into the template and pushes config to the server.
- `hetzner-setup-guide.md` — step-by-step guide to provision a new server from scratch.

## Server

| Field | Value |
|---|---|
| Provider | Hetzner Cloud |
| IP | `49.13.76.210` |
| Config dir | `/root/.openclaw/` |
| Compose dir | `/opt/openclaw/` |

## Common operations

```bash
# SSH into the server
ssh root@49.13.76.210

# SSH tunnel to access the UI locally
ssh -N -L 18789:127.0.0.1:18789 root@49.13.76.210
# then open http://127.0.0.1:18789/

# View live logs
ssh root@49.13.76.210 'cd /opt/openclaw && docker compose logs -f'

# Update to latest OpenClaw image
ssh root@49.13.76.210 'cd /opt/openclaw && docker compose pull && docker compose up -d'

# Restart the container
ssh root@49.13.76.210 'cd /opt/openclaw && docker compose restart'

# Fix stuck Telegram spool (bot stops responding after a hard restart)
ssh root@49.13.76.210 'rm -f /root/.openclaw/telegram/ingress-spool-default/*.processing'
```

## Persistent storage

All state lives in `/root/.openclaw/` on the server. Be cautious with operations that might affect this directory — it contains agent memory, credentials, and conversation history.
