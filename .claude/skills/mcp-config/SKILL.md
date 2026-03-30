---
name: mcp-config
description: Re-append che-mcp-server MCP config after zeroclaw onboard wipes config.toml
trigger: when user runs zeroclaw onboard or mentions MCP config is missing
---

# Skill: Re-append MCP Config After zeroclaw onboard

After running `zeroclaw onboard`, the `config.toml` file is regenerated and the MCP server configuration is wiped. This skill re-appends the MCP config for the `che-mcp-server` (already deployed in the same namespace).

## Steps

### 1. Get the current pod name

```bash
oc get pods -n akurinnoy-che -l controller.devfile.io/devworkspace_name=zeroclaw-terminal -o jsonpath='{.items[0].metadata.name}'
```

Save the pod name as `<pod>` for the commands below.

### 2. Check if MCP config already exists

```bash
oc exec -n akurinnoy-che <pod> -- grep -q '\[mcp\]' /zeroclaw-data/.zeroclaw/config.toml
```

- Exit code `0` means the `[mcp]` section is already present — nothing to do.
- Exit code `1` means the section is missing — proceed to step 3.

### 3. Append the MCP config (only if missing)

```bash
oc exec -n akurinnoy-che <pod> -- bash -c 'printf "\n[mcp]\nenabled = true\n\n[[mcp.servers]]\nname = \"che\"\ntransport = \"http\"\nurl = \"http://che-mcp-server:8080/mcp\"\n" >> /zeroclaw-data/.zeroclaw/config.toml'
```

### 4. Verify the config was written correctly

```bash
oc exec -n akurinnoy-che <pod> -- grep -A 8 '\[mcp\]' /zeroclaw-data/.zeroclaw/config.toml
```

Expected output:

```toml
[mcp]
enabled = true

[[mcp.servers]]
name = "che"
transport = "http"
url = "http://che-mcp-server:8080/mcp"
```

### 5. Remind the user

Tell the user: the MCP config has been appended. The zeroclaw daemon reads `config.toml` at startup, so the workspace must be restarted for the change to take effect.
