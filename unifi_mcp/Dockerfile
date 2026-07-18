# syntax=docker/dockerfile:1.4
#
# Child image wrapping ghcr.io/pete-builds/mcp-unifi to:
#   1. Install jq (not present in upstream) so the HA Supervisor
#      options.json injection script can parse /data/options.json.
#   2. Install gosu, used to drop from root to the unprivileged
#      `mcp` user only for the final server process.
#   3. Run a POSIX /run.sh wrapper that exports env vars from
#      /data/options.json before handing off to the MCP server.
#
# NOTE on bashio:
#   The upstream image is built FROM python:3.14-slim (Debian-slim).
#   It is NOT an HA-supervisor base image, so bashio is not embedded.
#   We use plain POSIX /bin/sh and jq only — no bashisms, no bashio.
#
# NOTE on privilege handling (confirmed at runtime, not assumed):
#   Under this Supervisor, /data/options.json is NOT world-readable —
#   attempting to read it as the unprivileged `mcp` user (uid 1000)
#   fails with "Permission denied". So the container must start as
#   root: we deliberately do NOT set `USER mcp` before ENTRYPOINT.
#   run.sh (below) runs as root, parses options.json, exports env
#   vars, then uses `gosu mcp` to exec the actual server process as
#   uid 1000 — so the long-running MCP server itself is still
#   non-root, even though the parsing step needs root to read the
#   options file.
#
FROM ghcr.io/pete-builds/mcp-unifi:latest

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq gosu && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /app

ENTRYPOINT ["/run.sh"]
