#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · CLI Command — kumpulan tool berbasis CLI
#     • CrewAI (Hermes / Groq)
#     • Tailscale CLI
#     • roc-agent CLI (Termux)
#     • Python HTTP Server (port 3000)
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/source.env" 2>/dev/null

# Colors (fallback if not inherited from menu.sh)
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$CLI_DIR/.." && pwd)"

cli_run(){
  local script="$1"; shift
  if [ ! -f "$script" ]; then
    echo -e "${RED}  [!] Script not found: $script${RESET}"; sleep 2; return
  fi
  chmod +x "$script"
  bash "$script" "$@"
}

cli_ensure_udocker(){
  udocker -V &>/dev/null 2>&1 || cli_run "$ROOT_DIR/install_udocker.sh"
}

while true; do
  clear
  echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo    "  ║               roc-containers · CLI Command                 ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${DIM}Tool berbasis command-line${RESET}\n"

  echo -e "  ${CYAN}${BOLD}[1]${RESET}  CrewAI (Hermes / Groq)        ${DIM}CLI${RESET}"
  echo -e "  ${BLUE}${BOLD}[2]${RESET}  Tailscale (container node)     ${DIM}udocker${RESET}"
  echo -e "  ${GREEN}${BOLD}[3]${RESET}  roc-agent CLI (Termux)         ${DIM}AI chat/ask/code${RESET}"
  echo -e "  ${DIM}[4]${RESET}  Python HTTP Server             ${DIM}→ port 3000${RESET}"
  echo -e "  ${MAGENTA}${BOLD}[0]${RESET}  Back to Main Menu"
  echo ""
  echo -en "  ${BOLD}Select [0-4]: ${RESET}"
  read -r c

  case "$c" in
    1) cli_ensure_udocker; cli_run "$ROOT_DIR/apps/crewai/crewai.sh" ;;
    2) cli_ensure_udocker; cli_run "$ROOT_DIR/apps/tailscale/tailscale.sh" ;;
    3) bash "$PREFIX/bin/roc-agent" "${@:-}" ;;
    4) PORT=3000 cli_run "$CLI_DIR/pyhttp.sh" ;;
    0|q|Q) exit 0 ;;
    *) echo -e "\n  ${RED}Invalid.${RESET}"; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
