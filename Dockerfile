ARG OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
FROM ${OPENCLAW_IMAGE}
USER root
RUN npx playwright install-deps chromium
USER node
