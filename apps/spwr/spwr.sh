#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Superpowers (spwr)
#  Coding agent skills & methodology
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

SPWR_DIR="$HOME/.roc-containers/apps/spwr"
SPWR_REPO="https://github.com/ivansslo/spwr"

# Clone or update spwr repo
spwr_ensure() {
  if [ ! -d "$SPWR_DIR/skills" ]; then
    echo -e "${YELLOW}[*] Cloning Superpowers...${RESET}"
    git clone --depth 1 "$SPWR_REPO" "$SPWR_DIR" 2>/dev/null
  else
    echo -e "${DIM}[*] Updating Superpowers...${RESET}"
    git -C "$SPWR_DIR" pull --ff-only 2>/dev/null || true
  fi
}

# Install dependencies
spwr_install() {
  spwr_ensure
  if command -v npm &>/dev/null; then
    echo -e "${YELLOW}[*] Installing npm dependencies...${RESET}"
    cd "$SPWR_DIR" && npm install --silent 2>/dev/null || true
    echo -e "${GREEN}[✓] Superpowers installed${RESET}"
  else
    echo -e "${YELLOW}[!] npm not found. Install: pkg install nodejs${RESET}"
  fi
}

# Run skills
spwr_run() {
  spwr_ensure
  local skill="${1:-}"
  if [ -z "$skill" ]; then
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  Superpowers — Coding Agent Skills                  ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}Usage:${RESET}"
    echo -e "  ${CYAN}roc-spwr install${RESET}    Install/update Superpowers"
    echo -e "  ${CYAN}roc-spwr skills${RESET}     List available skills"
    echo -e "  ${CYAN}roc-spwr docs${RESET}       Open documentation"
    echo -e "  ${CYAN}roc-spwr shell${RESET}      Open shell in spwr dir"
    echo ""
    return 0
  fi

  case "$skill" in
    install|setup|i)
      spwr_install
      ;;
    skills|list|ls)
      spwr_ensure
      echo -e "${BOLD}Available Skills:${RESET}\n"
      if [ -d "$SPWR_DIR/skills" ]; then
        for s in "$SPWR_DIR/skills"/*; do
          [ -d "$s" ] && echo -e "  ${GREEN}•${RESET} $(basename "$s")"
        done
      fi
      ;;
    docs|help|h)
      spwr_ensure
      if [ -f "$SPWR_DIR/README.md" ]; then
        cat "$SPWR_DIR/README.md" | head -80
      fi
      ;;
    shell|sh)
      spwr_ensure
      echo -e "${DIM}Spwr dir: $SPWR_DIR${RESET}"
      cd "$SPWR_DIR" && exec bash
      ;;
    update|up)
      echo -e "${YELLOW}[*] Updating Superpowers...${RESET}"
      git -C "$SPWR_DIR" pull 2>/dev/null || spwr_ensure
      echo -e "${GREEN}[✓] Updated${RESET}"
      ;;
    *)
      echo -e "${RED}Unknown command: $skill${RESET}"
      echo -e "Run ${CYAN}roc-spwr${RESET} for usage"
      ;;
  esac
}

spwr_run "$@"
