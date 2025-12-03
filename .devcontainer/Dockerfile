FROM mcr.microsoft.com/devcontainers/base:bookworm

USER root

# Install required tools, psql, and tsocks for SOCKS5 proxying
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    iproute2 \
    iputils-ping \
    iptables \
    postgresql-client \
    tsocks \
    git-lfs \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale repository (noarmor version works best in containers)
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list \
    -o /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale

# Make directory for Tailscale state file
RUN mkdir -p /var/lib/tailscale && chmod 700 /var/lib/tailscale

# Install tsocks config runtime
COPY tsocks.conf /etc/tsocks.conf

# Make wrapper script executable
COPY connect-db.sh /usr/local/bin/ts-psql
RUN chmod +x /usr/local/bin/ts-psql

USER vscode
