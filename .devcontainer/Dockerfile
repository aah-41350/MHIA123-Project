FROM mcr.microsoft.com/devcontainers/base:bookworm

USER root

# Install system tools & PostgreSQL client
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    iproute2 \
    iputils-ping \
    iptables \
    postgresql-client \
    git-lfs \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale (userspace mode compatible)
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
        -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list \
        | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y tailscale

RUN mkdir -p /var/lib/tailscale && chmod 700 /var/lib/tailscale

USER vscode
