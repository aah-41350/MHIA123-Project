FROM mcr.microsoft.com/devcontainers/base:debian

# Core tools
RUN apt-get update && apt-get install -y \
    curl sudo iproute2 iptables ca-certificates \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# --------------------------
# Install Tailscale (Debian 13 / Trixie)
# Using Debian SID repo (official method)
# --------------------------
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/unstable.noarmor.list \
      -o /etc/apt/sources.list.d/tailscale.list && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/unstable.asc \
      -o /usr/share/keyrings/tailscale-archive-keyring.asc && \
    apt-get update && \
    apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Allow tailscaled runtime
RUN mkdir -p /var/run/tailscale /var/lib/tailscale

# devcontainer entry
COPY dev-start.sh /usr/local/bin/dev-start.sh
RUN chmod +x /usr/local/bin/dev-start.sh
