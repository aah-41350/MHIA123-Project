FROM mcr.microsoft.com/devcontainers/base:debian

# Install tools
RUN apt-get update && apt-get install -y \
    curl iproute2 iptables \
    proxychains4 \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale (userspace mode)
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.gpg \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.list \
    | tee /etc/apt/sources.list.d/tailscale.list >/dev/null && \
    apt-get update && apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Tailscale launcher script
COPY tailscale/run-tailscale.sh /usr/local/bin/run-tailscale
RUN chmod +x /usr/local/bin/run-tailscale

# Proxychains config
COPY proxychains.conf /etc/proxychains.conf

WORKDIR /workspace
