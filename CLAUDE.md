# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is a **deployment configuration** repository for `openclaw-dima-assistant` on Fly.io. It does not contain application source code — it deploys a pre-built Docker image (`ghcr.io/openclaw/openclaw:latest`).

## Key files

- `fly.toml` — Fly.io deployment config: app name, region (`fra`), VM size (shared-cpu-2x, 2GB RAM), persistent volume mount at `/data`, and the startup command.
- `openclaw.json` — OpenClaw application config: gateway port and allowed CORS origins.

## Deployment

```powershell
# Deploy to Fly.io
fly deploy

# Check app status
fly status

# View logs
fly logs

# SSH into the running machine
fly ssh console
```

The app runs as a gateway process: `node dist/index.js gateway --allow-unconfigured --port 3000 --bind lan`. Auto-stop is disabled (`auto_stop_machines = "off"`) so the agent stays running 24/7.

## Persistent storage

A Fly volume named `openclaw_data` is mounted at `/data`. The app uses `OPENCLAW_STATE_DIR=/data` for state persistence. Be cautious with operations that might affect this volume.
