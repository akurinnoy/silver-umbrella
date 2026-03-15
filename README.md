# ZeroClaw Terminal — DevWorkspace with Web Terminal

Run [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) on Eclipse Che with a browser-based terminal instead of VS Code.

## Architecture

Single container running both processes:

- **ttyd** (foreground) — web terminal on port 7681, serves the browser shell
- **zeroclaw daemon** (background) — gateway, channels, scheduler on port 42617

The `.che/che-editor.yaml` prevents Eclipse Che from injecting VS Code. The Dashboard opens the ttyd web terminal where you can run zeroclaw CLI commands and manage the daemon directly.

## Quick Start

### 1. Open in Eclipse Che

```
https://<che-host>#https://github.com/<org>/zeroclaw-terminal
```

The Che Dashboard will find `devfile.yaml` and `.che/che-editor.yaml` in this repo.

### 2. Run `zeroclaw onboard`

The Dashboard opens a browser-based terminal. Configure zeroclaw:

```sh
# Non-interactive:
zeroclaw onboard --api-key <your-key> --provider openrouter

# Or fully interactive:
zeroclaw onboard
```

### 3. Apply the configuration

Restart the daemon to pick up the new config:

```sh
zeroclaw-restart
```

This patches the config (fixes host binding for the Route), stops the old daemon, and starts a new one — all within the same container. No pod restart needed.

### 4. Access the zeroclaw web UI

The Route URL is shown in the Che Dashboard. Or get it manually:

```sh
# From your local terminal:
oc get route zeroclaw-terminal -n <namespace> -o jsonpath='https://{.spec.host}/'
```

### 5. Get the pairing code

```sh
# In the web terminal:
zeroclaw status
```

Or check the daemon output scrolled above in the terminal.

## Available Tools

The web terminal includes:

| Tool | Usage |
|------|-------|
| `zeroclaw` | CLI — `onboard`, `daemon`, `agent`, `status`, etc. |
| `zeroclaw-restart` | Restart the daemon after config changes |
| `vi` | Text editor (vim-tiny) |
| `mc` | Midnight Commander file manager |
| `curl`, `git` | Standard tools |

## Building the Image

```sh
podman build --platform linux/amd64 -t quay.io/okurinny/zeroclaw-full:v0.1.7 .
podman push quay.io/okurinny/zeroclaw-full:v0.1.7
```

Update the `image:` field in `devfile.yaml` if using a different registry.

## File Structure

```
.
├── .che/
│   └── che-editor.yaml   # minimal editor (prevents VS Code injection)
├── devfile.yaml           # workspace: zeroclaw + ttyd + Service + Route
├── Dockerfile             # image: ubuntu + zeroclaw + ttyd + tools
└── README.md
```

## Reset Pairing

```sh
rm /zeroclaw-data/.zeroclaw/config.toml
zeroclaw-restart
```

The daemon generates a fresh config and pairing code on next start.
