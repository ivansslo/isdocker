#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · MAAGBA
#  Multi-Agent Architectural Guidance - Bedrock AgentCore
#  Clone: mongodb-partners/Multi-Agent-Architectural-Guidance-Bedrock-AgentCore
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

MAAGBA_DIR="$HOME/.roc-containers/apps/maagba/maagba-repo"
MAAGBA_REPO="https://github.com/mongodb-partners/Multi-Agent-Architectural-Guidance-Bedrock-AgentCore"

# Clone or update MAAGBA repo
maagba_ensure() {
  if [ ! -d "$MAAGBA_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning Multi-Agent Architectural Guidance (Bedrock AgentCore)...${RESET}"
    git clone --depth 1 "$MAAGBA_REPO" "$MAAGBA_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}[✗] Gagal clone repo. Cek koneksi internet.${RESET}"
      exit 1
    fi
    echo -e "${GREEN}[✓] Repo berhasil di-clone${RESET}"
  else
    echo -e "${DIM}[*] Updating MAAGBA...${RESET}"
    git -C "$MAAGBA_DIR" pull --ff-only 2>/dev/null || true
  fi
}

# Show README / docs
maagba_docs() {
  maagba_ensure
  if [ -f "$MAAGBA_DIR/README.md" ]; then
    cat "$MAAGBA_DIR/README.md"
  else
    echo -e "${YELLOW}[!] README.md tidak ditemukan${RESET}"
  fi
}

# List contents
maagba_list() {
  maagba_ensure
  echo -e "${BOLD}MAAGBA — Repo Contents:${RESET}\n"
  ls -1 "$MAAGBA_DIR/" | head -40
  echo ""
  echo -e "${DIM}Path: $MAAGBA_DIR${RESET}"
}

# Open shell in repo dir
maagba_shell() {
  maagba_ensure
  echo -e "${DIM}MAAGBA dir: $MAAGBA_DIR${RESET}"
  cd "$MAAGBA_DIR" && exec bash
}

# Install / setup dependencies
maagba_install() {
  maagba_ensure
  echo -e "${YELLOW}[*] Setting up MAAGBA...${RESET}"

  # Check for requirements.txt
  if [ -f "$MAAGBA_DIR/requirements.txt" ]; then
    echo -e "${YELLOW}[*] Installing Python dependencies...${RESET}"
    if [ -x "$HOME/.hermes/python3_venv/bin/pip" ]; then
      "$HOME/.hermes/python3_venv/bin/pip" install -r "$MAAGBA_DIR/requirements.txt" 2>/dev/null || true
    elif command -v pip &>/dev/null; then
      pip install -r "$MAAGBA_DIR/requirements.txt" 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] pip not found. Install: pkg install python${RESET}"
    fi
  fi

  # Check for package.json
  if [ -f "$MAAGBA_DIR/package.json" ]; then
    echo -e "${YELLOW}[*] Installing npm dependencies...${RESET}"
    if command -v npm &>/dev/null; then
      cd "$MAAGBA_DIR" && npm install --silent 2>/dev/null || true
    else
      echo -e "${YELLOW}[!] npm not found. Install: pkg install nodejs${RESET}"
    fi
  fi

  echo -e "${GREEN}[✓] MAAGBA setup selesai${RESET}"
}

# Main
maagba_run() {
  local cmd="${1:-}"

  if [ -z "$cmd" ]; then
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  MAAGBA — Multi-Agent Architectural Guidance        ║"
    echo " ║  Bedrock AgentCore                                  ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}Usage:${RESET}"
    echo -e "  ${CYAN}roc-maagba install${RESET}  Clone & install dependencies"
    echo -e "  ${CYAN}roc-maagba docs${RESET}     View README"
    echo -e "  ${CYAN}roc-maagba list${RESET}     List repo contents"
    echo -e "  ${CYAN}roc-maagba shell${RESET}    Open shell in repo dir"
    echo -e "  ${CYAN}roc-maagba update${RESET}   Pull latest changes"
    echo ""
    echo -e " ${DIM}Repo: mongodb-partners/Multi-Agent-Architectural-Guidance-Bedrock-AgentCore${RESET}"
    echo -e " ${DIM}Path: $MAAGBA_DIR${RESET}"
    return 0
  fi

  case "$cmd" in
    install|setup|i)
      maagba_install
      ;;
    docs|readme|help|h)
      maagba_docs
      ;;
    list|ls)
      maagba_list
      ;;
    shell|sh)
      maagba_shell
      ;;
    update|up|pull)
      echo -e "${YELLOW}[*] Updating MAAGBA...${RESET}"
      git -C "$MAAGBA_DIR" pull 2>/dev/null || maagba_ensure
      echo -e "${GREEN}[✓] Updated${RESET}"
      ;;
    clone)
      maagba_ensure
      ;;
    *)
      echo -e "${RED}Unknown command: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-maagba${RESET} for usage"
      ;;
  esac
}

maagba_run "$@"
