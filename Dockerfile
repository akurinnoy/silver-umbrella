# ZeroClaw — full-featured image for DevWorkspace
#
# The official ghcr.io/zeroclaw-labs/zeroclaw image is distroless: no shell,
# no git, no curl. This image adds those tools so the zeroclaw agent can
# execute shell commands and the container can be used as an interactive
# terminal via kubectl exec.
#
# Build:
#   docker buildx build \
#     --platform linux/amd64,linux/arm64 \
#     -f samples/zeroclaw.Dockerfile \
#     -t <your-registry>/zeroclaw-full:v0.1.7 \
#     --push .
#
# Or single-arch:
#   docker build -f samples/zeroclaw.Dockerfile -t <your-registry>/zeroclaw-full:v0.1.7 .

FROM ubuntu:24.04

# Install tools the zeroclaw agent uses at runtime.
# git and curl are required by many agent workflows; ca-certificates is needed
# for TLS connections to AI providers.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       git \
       ca-certificates \
       vim-tiny \
       mc \
    && rm -rf /var/lib/apt/lists/*

# Download and install the zeroclaw binary.
# TARGETARCH is set automatically by buildx (amd64 or arm64).
# For a plain `docker build` (no buildx) it defaults to amd64.
ARG ZEROCLAW_VERSION=v0.1.7
ARG TARGETARCH=amd64
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ASSET="zeroclaw-x86_64-unknown-linux-gnu.tar.gz" ;; \
        arm64) ASSET="zeroclaw-aarch64-unknown-linux-gnu.tar.gz" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://github.com/zeroclaw-labs/zeroclaw/releases/download/${ZEROCLAW_VERSION}/${ASSET}" \
        | tar -xz -C /usr/local/bin; \
    chmod +x /usr/local/bin/zeroclaw

# Install ttyd — a lightweight web terminal that serves a browser-based
# shell on port 7681. Used by the zeroclaw-terminal devfile variant to
# give users browser access to the zeroclaw CLI.
ARG TTYD_VERSION=1.7.7
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) TTYD_ARCH="x86_64" ;; \
        arm64) TTYD_ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}" \
        -o /usr/local/bin/ttyd; \
    chmod +x /usr/local/bin/ttyd

# Script to restart the zeroclaw daemon after config changes (e.g. after
# running `zeroclaw onboard`). Patches config, kills the old daemon, and
# starts a new one in the background.
COPY <<'SCRIPT' /usr/local/bin/zeroclaw-restart
#!/bin/bash
CONFIG=/zeroclaw-data/.zeroclaw/config.toml

if [ -f "$CONFIG" ]; then
  echo "Patching config..."
  sed -i 's/^host = .*/host = "[::]"/' "$CONFIG"
  sed -i 's/^allow_public_bind = .*/allow_public_bind = true/' "$CONFIG"
fi

echo "Stopping daemon..."
pkill -f "zeroclaw daemon" 2>/dev/null
sleep 1

echo "Starting daemon..."
zeroclaw daemon &
echo "Daemon restarted (PID $!)"
SCRIPT
RUN chmod +x /usr/local/bin/zeroclaw-restart

# zeroclaw writes all state to $HOME/.zeroclaw. In the DevWorkspace the PVC
# is mounted at /zeroclaw-data, so setting HOME there means config, pairing
# tokens, and daemon state all persist across pod restarts.
ENV HOME=/zeroclaw-data
ENV SHELL=/bin/bash
ENV ZEROCLAW_ALLOW_PUBLIC_BIND=true

EXPOSE 42617

# The daemon manages the gateway internally as one of its components.
CMD ["/bin/bash", "-c", "exec zeroclaw daemon"]
