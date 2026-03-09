# VPS Init

One-command setup for a fresh **Ubuntu** or **Debian 12** VPS.

## What it installs

| Component | Details |
|---|---|
| Docker Engine | Latest CE from the official Docker repository |
| Docker Compose | Plugin (`docker compose`) bundled with Docker CE |
| Zsh | Replaces bash as the default root shell |
| Oh My Zsh | With `zsh-autosuggestions` and `zsh-syntax-highlighting`, theme: `random` |

## Requirements

- Ubuntu 22.04 / 24.04 **or** Debian 12 (bookworm)
- Run as **root**
- Outbound internet access

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/folken87/dotfiles/main/init.sh | bash
```

> The script detects the OS automatically — the same command works on both Ubuntu and Debian.

## After installation

Reconnect to your SSH session or run `exec zsh` to switch to the new shell.
