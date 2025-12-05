#!/bin/bash

echo "Bringing Tailscale up..."
sudo tailscale up \
  --authkey="${TS_AUTHKEY}" \
  --hostname="mimic-codespace" \
  --accept-routes

echo "Tailscale status:"
tailscale status || true

echo "Done! You can now connect to your NAS Postgres over Tailscale."