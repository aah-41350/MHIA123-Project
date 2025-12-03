# Codespaces + Tailscale Userspace + Remote PostgreSQL

This Codespace configuration connects your Codespace to your NAS-hosted
PostgreSQL over your Tailnet using Tailscale in userspace mode + SOCKS5.

## How it works

- GitHub Codespaces does not allow privileged containers or TUN devices.
- Therefore, Tailscale must run in userspace mode with a SOCKS5 proxy.
- All outbound connections to the Tailnet must pass through 127.0.0.1:1055.

## Usage

### 1. Verify Tailscale is running:

tailscale status
tailscale ip

### 2. Connect to PostgreSQL:

ts-psql

- This runs psql through tsocks → SOCKS5 → Tailscale → NAS → PostgreSQL.

### 3. Change Database Parameters

Edit `.devcontainer/connect-db.sh`.

## Troubleshooting

If you see: "connection timed out"  
→ You forgot to wrap connections through SOCKS5. Use ts-psql.

If Tailscale isn't up:

sudo pkill tailscaled
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sudo tailscale up --authkey=tskey-xxxx