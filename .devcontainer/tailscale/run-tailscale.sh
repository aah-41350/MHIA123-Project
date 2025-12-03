#!/bin/bash

echo "[Tailscale] Starting userspace daemon..."

# Start daemon in userspace mode
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

sleep 2

echo "[Tailscale] Bringing interface up..."
tailscale up --auth-key=${TS_AUTHKEY} --ssh --accept-dns=false --netfilter-mode=off

echo "[Tailscale] Status:"
tailscale status

echo "[Tailscale] Tailscale IP:"
tailscale ip
