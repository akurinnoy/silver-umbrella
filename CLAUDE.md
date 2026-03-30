# zeroclaw-terminal

Che DevWorkspace that runs the zeroclaw AI agent gateway in a browser-based terminal on Eclipse Che / OpenShift.

## Architecture

| File | Purpose |
|------|---------|
| `devfile.yaml` | Workspace definition: zeroclaw container + Service + Route (OpenShift) |
| `.che/che-editor.yaml` | ttyd web terminal editor (container-contribution pattern, NOT baked into the image) |
| `Dockerfile` | zeroclaw-full image: ubuntu:24.04 + zeroclaw binary (NO ttyd) |

- Image: `quay.io/okurinny/zeroclaw-full:v0.1.7`
- ttyd image: `docker.io/tsl0922/ttyd:1.7.7-alpine`

## Editor Injection (How ttyd Gets In)

`.che/che-editor.yaml` uses `controller.devfile.io/container-contribution: true`. DWO merges the ttyd endpoint and volume mount into the zeroclaw container. A preStart init container copies the ttyd binary to a shared ephemeral volume. ttyd is then launched alongside `zeroclaw daemon` at startup.

## Startup Script

```bash
mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace
/ttyd-vol/ttyd -W bash &
exec zeroclaw daemon --host '[::]'
```

`--host '[::]'` is REQUIRED — without it the gateway binds to 127.0.0.1 and the Route returns 503.

## Config Management

- Config lives in PVC at `/zeroclaw-data/.zeroclaw/config.toml`
- Survives workspace restarts, NOT workspace deletion
- After `zeroclaw onboard`, MCP config is wiped — re-add manually (see `mcp-config` skill)

## Cluster Info

- Namespace: `akurinnoy-che`
- Cluster: `api.che-dev.x6e0.p1.openshiftapps.com`
- zeroclaw Route: `zeroclaw-terminal-akurinnoy-che.apps.che-dev.x6e0.p1.openshiftapps.com`
- ttyd terminal URL: shown in Che Dashboard as the main workspace URL

## Common oc Commands

```bash
# Get pod name
oc get pods -n akurinnoy-che -l controller.devfile.io/devworkspace_name=zeroclaw-terminal -o jsonpath='{.items[0].metadata.name}'

# Restart workspace
oc patch devworkspace zeroclaw-terminal -n akurinnoy-che --type=merge -p '{"spec":{"started":true}}'

# Get Route URL
oc get route zeroclaw-terminal -n akurinnoy-che -o jsonpath='https://{.spec.host}/'
```

## Available Skills

- `.claude/skills/mcp-config/` — re-append MCP config after `zeroclaw onboard`
- `.claude/skills/image-build/` — build and push multi-arch zeroclaw-full image
- `.claude/skills/validate-devfile/` — validate devfile.yaml schema before pushing
