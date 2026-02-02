FROM node:22-bookworm

# Install socat (port forwarding), gosu (lightweight privilege drop),
# and gettext-base (envsubst for config template expansion)
RUN apt-get update && apt-get install -y socat gosu gettext-base && rm -rf /var/lib/apt/lists/*

# Add skill binaries here when needed. Example pattern:
# RUN curl -L <release-url>.tar.gz | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/<binary>

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Copy seed config and entrypoint for Dokploy deployments
# The entrypoint writes openclaw.json (with env var substitution) on every start
COPY dokploy/openclaw.seed.json /opt/openclaw-seed/openclaw.seed.json
COPY dokploy/entrypoint.sh /opt/openclaw-seed/entrypoint.sh
RUN chmod +x /opt/openclaw-seed/entrypoint.sh

# Entrypoint runs as root to write config (envsubst) + fix permissions,
# then drops to node (uid 1000) via gosu before starting the gateway.
ENTRYPOINT ["/opt/openclaw-seed/entrypoint.sh"]
CMD ["node", "dist/index.js"]
