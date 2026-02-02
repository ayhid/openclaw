#!/bin/sh
# Always overwrite openclaw.json from the seed baked into the image.
# This ensures config changes committed to git propagate on every deploy.
# The seed file is the single source of truth for gateway configuration.

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SEED_FILE="/opt/openclaw-seed/openclaw.seed.json"

# Ensure correct ownership (volume may be owned by root initially)
chown -R 1000:1000 "$CONFIG_DIR"

# Substitute environment variables (e.g. ${OPENCLAW_GATEWAY_TOKEN}) in the
# seed template and write the result to the config volume.
echo "[entrypoint] Writing config from $SEED_FILE (with env substitution)"
envsubst < "$SEED_FILE" > "$CONFIG_FILE"
chown 1000:1000 "$CONFIG_FILE"

# Ensure workspace dir exists
mkdir -p "$CONFIG_DIR/workspace"
chown 1000:1000 "$CONFIG_DIR/workspace"

# Drop to node user for the gateway process
exec gosu node "$@"
