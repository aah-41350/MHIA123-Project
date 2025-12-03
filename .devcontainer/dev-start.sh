#!/bin/bash
set -e

echo "Starting tailscaled..."
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

sleep 2

if [ -n "$TS_AUTHKEY" ]; then
    echo "Bringing Tailscale up..."
    sudo tailscale up --authkey=${TS_AUTHKEY} --reset --accept-routes --accept-dns || true
else
    echo "No TS_AUTHKEY provided. Run manually:"
    echo "   sudo tailscale up --authkey <key>"
fi

echo "Tailscale IP:"
tailscale ip

echo "Dev container ready."

exec bash
