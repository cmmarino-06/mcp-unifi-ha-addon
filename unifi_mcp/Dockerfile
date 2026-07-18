# syntax=docker/dockerfile:1.4
#
# Child image wrapping ghcr.io/pete-builds/mcp-unifi to:
#   1. Install jq (not present in upstream) so the HA Supervisor
#      options.json injection script can parse /data/options.json.
#   2. Run a POSIX /run.sh wrapper that exports env vars from
#      /data/options.json before handing off to the MCP server.
#
# NOTE on bashio:
#   The upstream image is built FROM python:3.14-slim (Debian-slim).
#   It is NOT an HA-supervisor base image, so bashio is not embedded.
#   We use plain POSIX /bin/sh and jq only — no bashisms, no bashio.
#
# NOTE on the mcp user:
#   The upstream Dockerfile creates a user `mcp` with
#   --shell /usr/sbin/nologin. This means the mcp user cannot
#   open an interactive login shell (su -, ssh, etc.) — but it does
#   NOT prevent direct exec() of /bin/sh or any other binary.
#   /bin/sh (dash on Debian) still exists in the image layers owned
#   by root; it is only the user's interactive shell that is denied.
#   USER is a build-time directive, not a runtime switch: since
#   `USER mcp` (below) is set before ENTRYPOINT, run.sh itself runs
#   entirely as uid 1000 from PID 1 onward, never as root. jq is
#   installed as root only during the image build, in the layer
#   above. run.sh must be able to read /data/options.json as uid
#   1000 — Supervisor ships it world-readable, so this holds, but
#   it's a runtime permission, not a root-then-drop-privileges dance.
#
FROM ghcr.io/pete-builds/mcp-unifi:latest

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

USER mcp
WORKDIR /app

ENTRYPOINT ["/run.sh"]
