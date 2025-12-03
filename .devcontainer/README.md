# Tailscale Userspace Mode in Codespaces

This Codespace runs Tailscale in **userspace networking mode**, which:

- Works without systemd
- Does not need NET_ADMIN or /dev/net/tun
- Fully compatible with GitHub Codespaces
- Gives this Codespace its own Tailnet IP (`100.x.x.x`)

## Verify Tailscale

```bash
tailscale status
tailscale ip
