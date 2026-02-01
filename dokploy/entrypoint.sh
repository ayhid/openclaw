#!/bin/sh
# Seed openclaw.json into the config volume if it doesn't exist yet.
# Docker named volumes start empty on first creation, so the seed
# always works on initial deploy. On subsequent deploys the volume
# retains data and the seed is skipped.

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SEED_FILE="/opt/openclaw-seed/openclaw.seed.json"

# Ensure correct ownership (volume may be owned by root initially)
chown -R 1000:1000 "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[entrypoint] Seeding config from $SEED_FILE"
  cp "$SEED_FILE" "$CONFIG_FILE"
  chown 1000:1000 "$CONFIG_FILE"
fi

# Ensure workspace dir exists
mkdir -p "$CONFIG_DIR/workspace"
chown 1000:1000 "$CONFIG_DIR/workspace"

# Drop to node user for the gateway process
exec gosu node "$@"
