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
echo -e "${BLUE}          Go Installer Script           ${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

# ── 0. Root check ─────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "This script must be run as root"

# ── 1. Architecture detection ─────────────────────────────────────────────────
DEB_ARCH=$(dpkg --print-architecture)
case "$DEB_ARCH" in
  amd64)  GO_ARCH="amd64"   ;;
  arm64)  GO_ARCH="arm64"   ;;
  armhf)  GO_ARCH="armv6l"  ;;
  i386)   GO_ARCH="386"     ;;
  *) err "Unsupported architecture: $DEB_ARCH" ;;
esac

info "Architecture: $DEB_ARCH → go/$GO_ARCH"

# ── 2. Fetch latest Go version ────────────────────────────────────────────────
info "Fetching latest Go version..."

command -v curl >/dev/null 2>&1 || err "curl is required but not installed"

GO_JSON=$(curl -fsSL "https://go.dev/dl/?mode=json") \
  || err "Failed to connect to go.dev (check network/DNS)"

GO_VERSION=$(echo "$GO_JSON" \
  | grep -o '"version": *"go[^"]*"' \
  | head -1 \
  | grep -o 'go[0-9.]*' || true)

[ -z "$GO_VERSION" ] && err "Failed to parse Go version. Response preview: $(echo "$GO_JSON" | head -c 300)"

log "Latest Go version: $GO_VERSION"

# ── 3. Check if already installed ────────────────────────────────────────────
if [ -d /usr/local/go ]; then
  INSTALLED=$(</usr/local/go/VERSION)
  if [ "$INSTALLED" = "$GO_VERSION" ]; then
    log "Go $GO_VERSION is already installed, nothing to do"
    exit 0
  fi
  warn "Replacing existing $INSTALLED with $GO_VERSION"
fi

# ── 4. Download ───────────────────────────────────────────────────────────────
TARBALL="${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
DOWNLOAD_URL="https://dl.google.com/go/${TARBALL}"
TMP_FILE="/tmp/${TARBALL}"

info "Downloading ${TARBALL}..."
curl -fsSL -o "$TMP_FILE" "$DOWNLOAD_URL"
log "Downloaded to $TMP_FILE"

# ── 5. Install ────────────────────────────────────────────────────────────────
info "Installing to /usr/local/go..."
rm -rf /usr/local/go
tar -C /usr/local -xzf "$TMP_FILE"
rm -f "$TMP_FILE"
log "Extracted to /usr/local/go"

# ── 6. PATH setup ─────────────────────────────────────────────────────────────
PROFILE_FILE="/etc/profile.d/go.sh"
if [ ! -f "$PROFILE_FILE" ]; then
  echo 'export PATH=$PATH:/usr/local/go/bin' > "$PROFILE_FILE"
  log "Added /usr/local/go/bin to PATH via $PROFILE_FILE"
else
  log "PATH already configured in $PROFILE_FILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}           Setup complete! 🎉            ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e ""
echo -e "  Go version:  $GO_VERSION"
echo -e "  Install dir: /usr/local/go"
echo -e "  Binary:      /usr/local/go/bin/go"
echo -e ""
warn "Run 'source /etc/profile.d/go.sh' or reconnect to update PATH"
echo ""
