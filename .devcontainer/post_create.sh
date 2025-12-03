#!/bin/bash

echo "Starting tailscaled in userspace mode..."

# Start tailscaled (no root privileges required)
nohup tailscaled \
    --tun=userspace-networking \
    --socks5-server=localhost:1055 \
    >/tmp/tailscaled.log 2>&1 &

sleep 2

echo "Bringing Tailscale up..."
tailscale up \
  --authkey="${TAILSCALE_AUTHKEY}" \
  --hostname="mimic-codespace" \
  --accept-routes \
  --netfilter=false

echo "Tailscale status:"
tailscale status || true

echo "Done! You can now connect to your NAS Postgres over Tailscale."
