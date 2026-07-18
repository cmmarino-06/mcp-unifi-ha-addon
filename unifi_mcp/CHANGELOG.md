# Changelog — mcp-unifi Home Assistant Supervisor Add-on

## [0.0.1] — Initial build (corrected)

### Changes vs. earlier draft
- **Dockerfile rebuilt from confirmed source:** The upstream `ghcr.io/pete-builds/mcp-unifi`
  Dockerfile was obtained directly and parsed. The earlier draft made several
  unverified assumptions about shell availability, the `mcp` user's nologin
  shell, and base image capabilities — all now resolved from primary source.
- **Child image strategy confirmed:** Upstream uses `python:3.14-slim` (Debian-slim),
  which ships `/bin/sh` (dash) as the standard POSIX shell. No bash or bashio needed.
- **jq installed in root build layer:** The upstream image has no jq. Since the
  wrapper must parse HA Supervisor's `/data/options.json`, jq is installed via apt-get
  in the child Dockerfile's root-user layer before switching to USER mcp.
- **Wrapper uses POSIX sh only:** No bashisms — the script is `/bin/sh`-compatible
  (`dash` on Debian). This matches the upstream runtime environment exactly.
- **nologin clarification documented:** Added an explicit explanation of why the
  `mcp` user's `/usr/sbin/nologin` shell setting does not prevent `/bin/sh` from
  being used in the root-level wrapper script.
- **Env vars confirmed from README:** `STUB_MODE`, `UNIFI_HOST`, `UNIFI_API_KEY`,
  `MCP_UNIFI_MODULES_ENABLED`, `MCP_UNIFI_AUTH_TOKENS`,
  `MCP_UNIFI_CONTROLLERS_FILE` — all sourced from the upstream README. Unverified
  env var names (e.g. `MCP_UNIFI_LOG_AUDIT`, port-override vars) are omitted from
  config.yaml and documented as such.
- **Port 3714 curl-verify test documented:** The `curl -i http://<ha-ip>:3714/mcp`
  → 401 response is now documented as the correct verification step.
