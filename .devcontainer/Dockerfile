FROM mcr.microsoft.com/devcontainers/base:debian

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl iproute2 iptables proxychains4 \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale (Debian Trixie correct repo)
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.list \
      -o /etc/apt/sources.list.d/tailscale.list && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.asc \
      -o /usr/share/keyrings/tailscale-archive-keyring.asc && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install Tailscale startup script
COPY tailscale/run-tailscale.sh /usr/local/bin/run-tailscale
RUN chmod +x /usr/local/bin/run-tailscale

# Install proxychains config
COPY proxychains.conf /etc/proxychains.conf

WORKDIR /workspace
