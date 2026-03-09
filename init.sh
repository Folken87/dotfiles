#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✔]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✘]${NC} $1"; exit 1; }

echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}        VPS Initial Setup Script        ${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

# ── 0. Root check ─────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "This script must be run as root"

# ── 0b. OS detection ──────────────────────────────────────────────────────────
[ -f /etc/os-release ] || err "Cannot detect OS: /etc/os-release not found"
. /etc/os-release

case "$ID" in
  ubuntu|debian) ;;
  *) err "Unsupported OS: $ID. Only Ubuntu and Debian are supported." ;;
esac

DISTRO="$ID"
CODENAME="${VERSION_CODENAME}"
[ -z "$CODENAME" ] && err "Could not determine OS codename from /etc/os-release"

info "Detected OS: $DISTRO $CODENAME"

# ── 1. System update ──────────────────────────────────────────────────────────
info "Updating system packages..."
apt update -q && apt upgrade -y -q
apt install -y -q curl git wget unzip zsh
log "System updated"

# ── 2. Docker ─────────────────────────────────────────────────────────────────
info "Installing Docker..."

# Remove old versions if present
apt remove -y -q docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key and repo
apt install -y -q ca-certificates gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/${DISTRO} \
  ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt update -q
apt install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
log "Docker $(docker --version | awk '{print $3}' | tr -d ',') installed"
log "Docker Compose $(docker compose version | awk '{print $4}') installed"

# ── 3. Oh My Zsh ──────────────────────────────────────────────────────────────
info "Installing Oh My Zsh..."

# Install for root (RUNZSH=no prevents dropping into zsh mid-script)
export RUNZSH=no
export CHSH=yes
export KEEP_ZSHRC=no

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Plugin: zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Plugin: zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  info "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Patch .zshrc: theme → random, plugins
ZSHRC="$HOME/.zshrc"

sed -i 's/^ZSH_THEME=.*/ZSH_THEME="random"/' "$ZSHRC"
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"

# Set zsh as default shell for root
chsh -s "$(which zsh)" root

log "Oh My Zsh installed (theme: random, plugins: git zsh-autosuggestions zsh-syntax-highlighting)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}           Setup complete! 🎉            ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e ""
echo -e "  OS:            $DISTRO $CODENAME"
echo -e "  Docker:        $(docker --version | awk '{print $3}' | tr -d ',')"
echo -e "  Docker Compose: $(docker compose version | awk '{print $4}')"
echo -e "  Shell:         zsh + Oh My Zsh"
echo -e ""
warn "Run 'exec zsh' or reconnect to start using zsh"
echo ""
