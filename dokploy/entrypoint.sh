#!/bin/sh
# Seed openclaw.json into the config dir if it doesn't exist yet.
# The host volume mount overlays /home/node/.openclaw at runtime,
# so we copy from a staging location baked into the image.
# Runs as root to handle permissions, then drops to uid 1000 (node).

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SEED_FILE="/opt/openclaw-seed/openclaw.seed.json"

mkdir -p "$CONFIG_DIR"
chown 1000:1000 "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[entrypoint] No config found at $CONFIG_FILE — seeding from $SEED_FILE"
  cp "$SEED_FILE" "$CONFIG_FILE"
  chown 1000:1000 "$CONFIG_FILE"
fi

# Drop to node user for the gateway process
exec gosu node "$@"
