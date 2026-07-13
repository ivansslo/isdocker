#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Clawdex Mobile
#  Clone: ivansslo/clawdex-mobile
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

CLAWDEX_DIR="$HOME/.roc-containers/apps/clawdex/clawdex-mobile"
CLAWDEX_REPO="https://github.com/ivansslo/clawdex-mobile"

# Clone or update clawdex-mobile repo
clawdex_ensure() {
  if [ ! -d "$CLAWDEX_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning Clawdex Mobile...${RESET}"
    git clone --depth 1 "$CLAWDEX_REPO" "$CLAWDEX_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}[✗] Gagal clone repo. Cek koneksi internet.${RESET}"
      exit 1
    fi
    echo -e "${GREEN}[✓] Repo berhasil di-clone${RESET}"
  else
    echo -e "${DIM}[*] Updating Clawdex Mobile...${RESET}"
    git -C "$CLAWDEX_DIR" pull --ff-only 2>/dev/null || true
  fi
}

# Show README / docs
clawdex_docs() {
  clawdex_ensure
  if [ -f "$CLAWDEX_DIR/README.md" ]; then
    cat "$CLAWDEX_DIR/README.md"
  else
    echo -e "${YELLOW}[!] README.md tidak ditemukan${RESET}"
  fi
}

# List contents
clawdex_list() {
  clawdex_ensure
  echo -e "${BOLD}Clawdex Mobile — Repo Contents:${RESET}\n"
  ls -1 "$CLAWDEX_DIR/" | head -40
  echo ""
  echo -e "${DIM}Path: $CLAWDEX_DIR${RESET}"
}

# Open shell in repo dir
clawdex_shell() {
  clawdex_ensure
  echo -e "${DIM}Clawdex Mobile dir: $CLAWDEX_DIR${RESET}"
  cd "$CLAWDEX_DIR" && exec bash
}

# Install / setup dependencies
clawdex_install() {
  clawdex_ensure
  echo -e "${YELLOW}[*] Setting up Clawdex Mobile...${RESET}"

  # Check for requirements.txt
  if [ -f "$CLAWDEX_DIR/requirements.txt" ]; then
    echo -e "${YELLOW}[*] Installing Python dependencies...${RESET}"
    if [ -x "$HOME/.hermes/python3_venv/bin/pip" ]; then
      "$HOME/.hermes/python3_venv/bin/pip" install -r "$CLAWDEX_DIR/requirements.txt" 2>/dev/null || true
    elif command -v pip &>/dev/null; then
      pip install -r "$CLAWDEX_DIR/requirements.txt" 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] pip not found. Install: pkg install python${RESET}"
    fi
  fi

  # Check for package.json
  if [ -f "$CLAWDEX_DIR/package.json" ]; then
    echo -e "${YELLOW}[*] Installing npm dependencies...${RESET}"
    if command -v npm &>/dev/null; then
      cd "$CLAWDEX_DIR" && npm install --silent 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] npm not found. Install: pkg install nodejs${RESET}"
    fi
  fi

  echo -e "${GREEN}[✓] Clawdex Mobile setup selesai${RESET}"
}

# Run / serve
clawdex_run() {
  clawdex_ensure
  echo -e "${YELLOW}[*] Starting Clawdex Mobile...${RESET}"

  # Try npm start first
  if [ -f "$CLAWDEX_DIR/package.json" ] && grep -q '"start"' "$CLAWDEX_DIR/package.json"; then
    cd "$CLAWDEX_DIR" && npm start
  # Try python app
  elif [ -f "$CLAWDEX_DIR/app.py" ]; then
    local py="python3"
    [ -x "$HOME/.hermes/python3_venv/bin/python" ] && py="$HOME/.hermes/python3_venv/bin/python"
    cd "$CLAWDEX_DIR" && exec "$py" app.py "$@"
  elif [ -f "$CLAWDEX_DIR/main.py" ]; then
    local py="python3"
    [ -x "$HOME/.hermes/python3_venv/bin/python" ] && py="$HOME/.hermes/python3_venv/bin/python"
    cd "$CLAWDEX_DIR" && exec "$py" main.py "$@"
  else
    echo -e "${YELLOW}[!] Tidak ada entry point otomatis. Buka shell manual:${RESET}"
    echo -e "  ${CYAN}roc-clawdex shell${RESET}"
  fi
}

# Main
clawdex_main() {
  local cmd="${1:-}"

  if [ -z "$cmd" ]; then
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  Clawdex Mobile — ivansslo/clawdex-mobile           ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}Usage:${RESET}"
    echo -e "  ${CYAN}roc-clawdex install${RESET}  Clone & install dependencies"
    echo -e "  ${CYAN}roc-clawdex run${RESET}      Run / serve Clawdex Mobile"
    echo -e "  ${CYAN}roc-clawdex docs${RESET}     View README"
    echo -e "  ${CYAN}roc-clawdex list${RESET}     List repo contents"
    echo -e "  ${CYAN}roc-clawdex shell${RESET}    Open shell in repo dir"
    echo -e "  ${CYAN}roc-clawdex update${RESET}   Pull latest changes"
    echo ""
    echo -e " ${DIM}Repo: ivansslo/clawdex-mobile${RESET}"
    echo -e " ${DIM}Path: $CLAWDEX_DIR${RESET}"
    return 0
  fi

  case "$cmd" in
    install|setup|i)
      clawdex_install
      ;;
    run|start|serve|s)
      shift
      clawdex_run "$@"
      ;;
    docs|readme|help|h)
      clawdex_docs
      ;;
    list|ls)
      clawdex_list
      ;;
    shell|sh)
      clawdex_shell
      ;;
    update|up|pull)
      echo -e "${YELLOW}[*] Updating Clawdex Mobile...${RESET}"
      git -C "$CLAWDEX_DIR" pull 2>/dev/null || clawdex_ensure
      echo -e "${GREEN}[✓] Updated${RESET}"
      ;;
    clone)
      clawdex_ensure
      ;;
    *)
      echo -e "${RED}Unknown command: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-clawdex${RESET} for usage"
      ;;
  esac
}

clawdex_main "$@"
