# OpenClaw on Hetzner — Step-by-Step Setup Guide

Based on the official docs and the YouTube video "How To Setup OpenClaw on Hetzner in 5 minutes".
Credentials template: [hetzner-credentials.md](hetzner-credentials.md) (gitignored).

---

## Prerequisites

- Hetzner Cloud account (hetzner.com/cloud)
- SSH key pair on your machine (`~/.ssh/id_ed25519` or similar)
- `openssl` available locally (for generating secrets)
- ~20 minutes

---

## Step 1 — Create the VPS on Hetzner Cloud

1. Log in to [console.hetzner.cloud](https://console.hetzner.cloud)
2. Create a new project (e.g. `openclaw`)
3. Click **Add Server**:
   - **Location:** pick one close to you (e.g. Falkenstein `fsn1`)
   - **Image:** Ubuntu 24.04
   - **Type:** make sure to select **Shared CPU** (not Dedicated CPU / CCX series). Pick `CPX22` — 3 vCPU AMD shared, 4 GB RAM (~€10/mo). Dedicated CPU (CCX) is unnecessary and ~2× more expensive.
   - **SSH keys:** add your public key
   - **Name:** `openclaw-server`
4. Click **Create & Buy**
5. Note the server IP → save it in [hetzner-credentials.md](hetzner-credentials.md)

---

## Step 2 — First SSH login & system update

```bash
ssh root@YOUR_VPS_IP
apt-get update && apt-get upgrade -y
```

---

## Step 3 — Install Docker

```bash
apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sh

# Verify
docker --version
docker compose version
```

---

## Step 4 — Generate secrets (do this locally or on the server)

```bash
openssl rand -hex 32   # → OPENCLAW_GATEWAY_TOKEN
openssl rand -hex 32   # → GOG_KEYRING_PASSWORD
```

Save both values in [hetzner-credentials.md](hetzner-credentials.md).

---

## Step 5 — Create persistent state directory

```bash
mkdir -p /root/.openclaw/workspace
chown -R 1000:1000 /root/.openclaw
```

This directory survives container restarts and image upgrades.

---

## Step 6 — Set up the working directory

```bash
mkdir -p /opt/openclaw
cd /opt/openclaw
```

---

## Step 7 — Create the `.env` file

```bash
nano /opt/openclaw/.env
```

Paste and fill in your values:

```dotenv
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
OPENCLAW_GATEWAY_TOKEN=<your generated token>
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789

OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace

GOG_KEYRING_PASSWORD=<your generated password>
XDG_CONFIG_HOME=/home/node/.openclaw
```

---

## Step 8 — Create `docker-compose.yml`

```bash
nano /opt/openclaw/docker-compose.yml
```

```yaml
services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE}
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - HOME=/home/node
      - NODE_ENV=production
      - TERM=xterm-256color
      - OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND}
      - OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT}
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - GOG_KEYRING_PASSWORD=${GOG_KEYRING_PASSWORD}
      - XDG_CONFIG_HOME=${XDG_CONFIG_HOME}
      - PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      - "127.0.0.1:${OPENCLAW_GATEWAY_PORT}:18789"
    command:
      - "node"
      - "dist/index.js"
      - "gateway"
      - "--bind"
      - "${OPENCLAW_GATEWAY_BIND}"
      - "--port"
      - "${OPENCLAW_GATEWAY_PORT}"
      - "--allow-unconfigured"
```

Port is bound to `127.0.0.1` only — the gateway is NOT exposed to the public internet.

---

## Step 9 — Pull the image & start

```bash
cd /opt/openclaw
docker compose pull
docker compose up -d

# Watch logs
docker compose logs -f
```

Wait for the line: `Gateway listening on ...` before proceeding.

---

## Step 10 — Enable SSH TCP forwarding on the server

Check `/etc/ssh/sshd_config` has:

```
AllowTcpForwarding local
```

If you had to change it:

```bash
systemctl restart ssh
```

---

## Step 11 — Open the SSH tunnel from your laptop

Run this **on your local machine** (keep the terminal open):

```bash
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_VPS_IP
```

Now open your browser: **http://127.0.0.1:18789/**

Log in with the `OPENCLAW_GATEWAY_TOKEN` you generated.

---

## Step 12 — Configure your first agent

Inside the OpenClaw UI:

1. Create a new agent
2. Add an AI provider key (Anthropic / OpenAI) under **Settings → Providers**
3. Optionally connect messaging channels (Telegram, Gmail, WhatsApp)
4. Start the agent

State is stored in `/root/.openclaw/agents/<agentId>/` on the server.

---

## Ongoing maintenance

```bash
# Update to latest image
cd /opt/openclaw
docker compose pull && docker compose up -d

# View logs
docker compose logs -f

# Restart
docker compose restart
```

---

## Security notes

- Never open port 18789 in the Hetzner firewall — always use the SSH tunnel or a VPN (Tailscale)
- Keep `.env` readable only by root: `chmod 600 /opt/openclaw/.env`
- Rotate `OPENCLAW_GATEWAY_TOKEN` if you suspect compromise (restart container after change)

---

## Recommended Hetzner instance sizes

| Use case | Instance | RAM | Cost |
|---|---|---|---|
| Production / multiple channels | **CPX22** (pick this) | 3 vCPU AMD, 4 GB | ~€10/mo |
| Browser automation skills | CPX31 | 4 vCPU AMD, 8 GB | ~€18/mo |
| ~~Dedicated CPU (CCX series)~~ | ~~CCX13+~~ | — | ~~€19+/mo — overkill~~ |

---

Sources:
- [Hetzner · OpenClaw official docs](https://docs.openclaw.ai/install/hetzner)
- [YouTube: How To Setup OpenClaw on Hetzner in 5 minutes](https://www.youtube.com/watch?v=HQ_X2i11BDc)
