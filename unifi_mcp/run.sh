#!/bin/sh
# POSIX sh script — dash-compatible only, no bashisms.
#
# Parses /data/options.json (written by HA Supervisor) and exports
# the env vars the mcp-unifi server reads directly.  Uses exec so
# the server replaces this script in PID 1 — signals propagate
# correctly and Supervisor lifecycle (stop/restart) works as expected.

set -e

OPTIONS_FILE="/data/options.json"

# Abort clearly if options file is absent (should always be present
# when Supervisor starts the container; nothing to do for bare docker).
if [ ! -f "$OPTIONS_FILE" ]; then
    echo "[run.sh] WARNING: $OPTIONS_FILE not found. Starting with defaults." >&2
    exec gosu mcp python -m mcp_unifi.server
fi

# Read each option; export only when non-empty (omit blank/optional fields).
# jq -r returns the raw string value (no quotes).
#
# NOTE: deliberately NOT using jq's `//` alternative operator for
# stub_mode. `//` treats JSON `false` the same as `null`/missing and
# substitutes the fallback — so `.stub_mode // true` would silently
# turn an explicit `false` back into `true`. Use an explicit null
# check instead so a real `false` value is respected.

STUB_MODE="$(jq -r 'if .stub_mode == null then true else .stub_mode end' "$OPTIONS_FILE")"
export STUB_MODE

UNIFI_HOST="$(jq -r '.unifi_host // ""' "$OPTIONS_FILE")"
[ -n "$UNIFI_HOST" ] && export UNIFI_HOST

UNIFI_API_KEY="$(jq -r '.unifi_api_key // ""' "$OPTIONS_FILE")"
[ -n "$UNIFI_API_KEY" ] && export UNIFI_API_KEY

MCP_UNIFI_MODULES_ENABLED="$(jq -r '.modules_enabled // "network"' "$OPTIONS_FILE")"
export MCP_UNIFI_MODULES_ENABLED

MCP_UNIFI_AUTH_TOKENS="$(jq -r '.auth_tokens // ""' "$OPTIONS_FILE")"
[ -n "$MCP_UNIFI_AUTH_TOKENS" ] && export MCP_UNIFI_AUTH_TOKENS

MCP_UNIFI_CONTROLLERS_FILE="$(jq -r '.controllers_file // ""' "$OPTIONS_FILE")"
[ -n "$MCP_UNIFI_CONTROLLERS_FILE" ] && export MCP_UNIFI_CONTROLLERS_FILE

# gosu preserves the exported environment across the user switch and
# exec's the server as PID 1 (no wrapper process left behind), so
# signals/Supervisor lifecycle still work correctly.
exec gosu mcp python -m mcp_unifi.server
