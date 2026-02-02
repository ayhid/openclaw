#!/bin/sh
# Always overwrite openclaw.json from the seed baked into the image.
# This ensures config changes committed to git propagate on every deploy.
# The seed file is the single source of truth for gateway configuration.

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SEED_FILE="/opt/openclaw-seed/openclaw.seed.json"

# Ensure correct ownership (volume may be owned by root initially)
chown -R 1000:1000 "$CONFIG_DIR"

# Build the trusted proxy list dynamically.
# OpenClaw's isTrustedProxyAddress() does exact IP matching (no CIDR),
# so we enumerate all gateway IPs from every Docker network this container
# is attached to. This covers Traefik regardless of which network it uses.
PROXY_IPS=""
for iface in $(ip -4 route | awk '/^default/ {print $5}' | sort -u); do
  gw=$(ip -4 route | awk "/^default.*dev $iface/ {print \$3}")
  if [ -n "$gw" ]; then
    PROXY_IPS="$PROXY_IPS \"$gw\","
  fi
done
# Also grab all known gateway IPs from non-default routes (docker networks)
for gw in $(ip -4 route | awk '/via/ {print $3}' | sort -u); do
  # avoid duplicates
  case "$PROXY_IPS" in
    *"\"$gw\""*) ;;
    *) PROXY_IPS="$PROXY_IPS \"$gw\"," ;;
  esac
done
# Strip trailing comma and wrap in JSON array
PROXY_IPS=$(echo "$PROXY_IPS" | sed 's/,$//')
export OPENCLAW_TRUSTED_PROXIES="[$PROXY_IPS]"
echo "[entrypoint] Discovered trusted proxies: $OPENCLAW_TRUSTED_PROXIES"

# Substitute environment variables (e.g. ${OPENCLAW_GATEWAY_TOKEN}) in the
# seed template and write the result to the config volume.
echo "[entrypoint] Writing config from $SEED_FILE (with env substitution)"
envsubst < "$SEED_FILE" > "$CONFIG_FILE"
chown 1000:1000 "$CONFIG_FILE"

# Log the final config for debugging (mask the token)
echo "[entrypoint] Final config:"
sed 's/"token": *"[^"]*"/"token": "***"/' "$CONFIG_FILE"

# Ensure workspace dir exists
mkdir -p "$CONFIG_DIR/workspace"
chown 1000:1000 "$CONFIG_DIR/workspace"

# Drop to node user for the gateway process
exec gosu node "$@"
