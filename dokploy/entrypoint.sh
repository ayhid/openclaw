#!/bin/sh
# Seed openclaw.json into the config dir if it doesn't exist yet.
# The host volume mount overlays /home/node/.openclaw at runtime,
# so we copy from a staging location baked into the image.

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SEED_FILE="/opt/openclaw-seed/openclaw.seed.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[entrypoint] No config found at $CONFIG_FILE — seeding from $SEED_FILE"
  mkdir -p "$CONFIG_DIR"
  cp "$SEED_FILE" "$CONFIG_FILE"
fi

exec "$@"
