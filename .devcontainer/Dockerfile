# Base image
FROM mcr.microsoft.com/devcontainers/python:3.13

# Install dependencies (curl, gnupg, tailscale, postgres client)
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y tailscale

# Python ML stack
RUN pip install --upgrade pip && pip install \
    psycopg2-binary \
    sqlalchemy \
    pandas \
    numpy \
    scikit-learn \
    xgboost \
    matplotlib \
    seaborn \
    jupyterlab \
    python-dotenv
    