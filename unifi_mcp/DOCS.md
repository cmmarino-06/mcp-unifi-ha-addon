# mcp-unifi Home Assistant Supervisor Add-on — Installation & Configuration

## Overview

This add-on wraps [pete-builds/mcp-unifi](https://github.com/pete-builds/mcp-unifi),
an MCP server that exposes the UniFi Network local API as Model Context Protocol
tools. Installing it as a Supervisor-managed add-on avoids the "Unsupported software"
Repairs warning that appears when running the upstream image as a standalone
Docker container on HAOS.

---

## Prerequisites

- Home Assistant OS or Supervised installation with the Supervisor add-on API.
- UniFi gateway/controller on the same network (e.g. `192.168.1.1`).
- A UniFi **local API key** (System → API Keys in the UniFi OS console).
  *Not* your Ubiquiti SSO/cloud credentials.
- Architecture: **amd64** (Intel/AMD) or **aarch64** (ARM64, e.g. UCG-Ultra).

---

## Installation

### 1. Add as a custom repository

In Home Assistant:
**Settings → Add-ons → Add-on Store → ⋮ (top-right) → Manage add-on repositories**

Add this URL:

```
https://github.com/pete-builds/mcp-unifi
```

> In the current draft stage, the repository YAML and add-on are hosted in a
> local outputs folder. For development testing, copy the `mcp-unifi-ha-addon/`
> folder to `/addons` on your HA machine and add `path: /addons/mcp-unifi-ha-addon`
> to your `configuration.yaml` under `homeassistant:` or reference it directly.

### 2. Install the add-on

Search for **mcp-unifi** in the add-on store and click **Install**.

---

## Configuration

Open the add-on and fill in the options:

| Field | Default | Required | Description |
|---|---|---|---|
| **stub_mode** | `true` | Yes | Demo mode with simulated devices. Set `false` for real use. |
| **unifi_host** | `""` | Conditional | IP/hostname of your UniFi gateway (e.g. `192.168.1.1`). Required when stub_mode is false. |
| **unifi_api_key** | `""` | Conditional | Local API key from UniFi OS console (System > API Keys). Required when stub_mode is false. |
| **modules_enabled** | `network` | No | Comma-separated list of MCP modules |
| **auth_tokens** | `""` | **Yes** | Bearer token for the MCP HTTP transport's client authentication. Generate with `openssl rand -hex 32`. Without this the server refuses to start. |
| **controllers_file** | `""` | No | Path to multi-controller JSON file |

- **stub_mode: true** (default) — no UniFi credentials needed, but `auth_tokens` is still required.
- **stub_mode: false** — also fill in `unifi_host` and `unifi_api_key`.

### Example (real UniFi controller)

```
stub_mode: false
unifi_host: 192.168.1.1
unifi_api_key: <your-local-api-key>
modules_enabled: network
auth_tokens: <output of: openssl rand -hex 32>

```

---

## Starting the Add-on

Click **Start**. Wait a few seconds for the MCP server to initialise.

Expected log output:
```
INFO     [mcp_unifi.server] Starting MCP server ...
INFO     [mcp_unifi.server] Transport: streamable-http
INFO     [mcp_unifi.server] Serving on http://0.0.0.0:3714
```

---

## Verifying the MCP Server is Running

From any machine on the same network (including your Mac):

```bash
curl -i http://<home-assistant-ip>:3714/mcp
```

**Expected response:** `HTTP/1.1 401 Unauthorized`  
This is correct — the MCP server requires a valid MCP protocol handshake;
`curl` without the proper protocol headers returns 401, confirming the server
is listening and rejecting unauthenticated requests.

If you get `Connection refused` → the add-on is not running or port mapping
failed — check the Supervisor logs.

---

## Connecting Claude Desktop

1. Open **Claude Desktop** → **Settings → Extensions**.
2. Find **mcp-unifi** and click the gear icon.
3. Fill in:
   - **Host:** `http://<home-assistant-ip>:3714` (your HA machine's IP, port 3714)
   - **Transport:** `streamable-http`
   - **stub_mode / unifi_host / unifi_api_key** — same values as configured above.

> **Note:** If Claude Desktop and your HA are on the same network you do *not*
> need Cloudflare Tunnel for local access. The MCP server listens on all
> interfaces (`0.0.0.0:3714`) inside the HA network.

---

## About `/usr/sbin/nologin` and `/bin/sh` — Clarification

The upstream `mcp` user's login shell is set to `/usr/sbin/nologin`. This is
**not** a contradiction with the `run.sh` wrapper approach.

- `/usr/sbin/nologin` prevents the `mcp` user from opening an *interactive*
  login shell (e.g. via `su mcp`, `ssh mcp@host`, or terminal login). It does
  **not** remove or hide any binaries.
- The `/bin/sh` binary (Debian's `dash`) is present in the image layers owned
  by root, just like every other file in a standard Debian-slim image.
- When root runs `COPY`, `chmod`, or `sh -c '...'`, it can directly `exec()`
  `/bin/sh` regardless of what login shell any other user has configured.
- `USER mcp` is set in the Dockerfile *before* `ENTRYPOINT`, so `run.sh`
  itself runs entirely as non-root `mcp` (uid 1000) from container start —
  it never runs as root. jq is installed as root only during the image
  *build* (a separate layer), not at container runtime. `run.sh` parses
  `/data/options.json` and `exec`s `python -m mcp_unifi.server` as `mcp`
  throughout — no privileged operations, no interactive shell access, yet
  all functionality preserved.

---

## Troubleshooting

### Connection refused on port 3714

1. Check the add-on is **running** (green indicator in HA).
2. Check **Ports** in the Supervisor UI — port 3714 should be mapped.
3. Disable any HA firewall rules blocking local network access to 3714.

### 401 on `curl http://<ha-ip>:3714/mcp`

This is **expected**. The MCP server is up; it just requires a valid MCP
protocol handshake. Use the Claude Desktop extension UI (gear icon) to
connect properly.

### "Unsupported software" Repairs warning still appears

Make sure the upstream image is **not** also running as a standalone container
on the same host. The HA Supervisor add-on manages the lifecycle — if a raw
`docker run` also exists, Supervisor sees duplicate containers and flags it.

### Add-on fails to start

Check Supervisor → System → Logs for the add-on container.
Common causes:
- Wrong architecture selected (only `amd64` and `aarch64` are supported).
- `unifi_host` is blank while `stub_mode: false` — the server requires a host.

---

## Security Notes

- `unifi_api_key` and `auth_tokens` are stored encrypted by HA Supervisor.
- The MCP server runs as non-root user `mcp` (uid 1000) with no login shell.
- The UniFi local API key grants access to your LAN devices — do not expose
  port 3714 to the public internet; keep it on the local network or behind
  a VPN.
