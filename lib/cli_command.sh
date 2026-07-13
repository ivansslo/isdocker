#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · CLI Command — kumpulan tool berbasis CLI
#     • Hermes Agent (autonomous, venv, root)
#     • CrewAI (Hermes / Groq)
#     • Tailscale CLI
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

# ── Hermes Agent submenu (autonomous complex-task agent) ────────────
hermes_agent_submenu(){
  local HA="$ROOT_DIR/apps/hermes-agent/hermes-agent.sh"
  while true; do
    clear
    echo -e "${YELLOW}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    echo    "  ║          roc-containers · Hermes Agent (autonomous)       ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo -e "  ${DIM}Tool-using AI agent · container udocker · root · venv${RESET}\n"
    echo -e "  ${CYAN}[1]${RESET}  Setup (buat venv + dependency)"
    echo -e "  ${CYAN}[2]${RESET}  Run — mode interaktif (REPL)"
    echo -e "  ${CYAN}[3]${RESET}  Run — task sekali jalan (ketik task)"
    echo -e "  ${CYAN}[4]${RESET}  Version"
    echo -e "  ${CYAN}[5]${RESET}  Shell container (root)"
    echo -e "  ${BLUE}[6]${RESET}  Cek kecocokan Tailscale CLI"
    echo -e "  ${MAGENTA}[0]${RESET}  Kembali"
    echo ""
    echo -en "  ${BOLD}Select [0-6]: ${RESET}"
    read -r h
    case "$h" in
      1) cli_run "$HA" setup ;;
      2) cli_run "$HA" run ;;
      3) echo -en "\n  Task: "; read -r _task; [ -n "$_task" ] && cli_run "$HA" run "$_task" ;;
      4) cli_run "$HA" version ;;
      5) cli_run "$HA" shell ;;
      6) cli_run "$HA" tailscale ;;
      0|q|Q) return 0 ;;
      *) echo -e "\n  ${RED}Invalid.${RESET}"; sleep 1 ;;
    esac
    echo -e "\n  ${DIM}Press Enter to return...${RESET}"; read -r
  done
}

while true; do
  clear
  echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo    "  ║               roc-containers · CLI Command                 ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${DIM}Tool berbasis command-line${RESET}\n"

  echo -e "  ${YELLOW}${BOLD}[1]${RESET}  Hermes Agent (autonomous)     ${DIM}venv · root${RESET}"
  echo -e "  ${CYAN}${BOLD}[2]${RESET}  CrewAI (Hermes / Groq)        ${DIM}CLI${RESET}"
  echo -e "  ${BLUE}${BOLD}[3]${RESET}  Tailscale (container node)     ${DIM}udocker${RESET}"
  echo -e "  ${GREEN}${BOLD}[4]${RESET}  roc-agent CLI (Termux)       ${DIM}AI chat/ask/code${RESET}"
  echo -e "  ${DIM}[5]${RESET}  Python HTTP Server            ${DIM}→ port 3000${RESET}"            ${DIM}→ port 3000${RESET}"
  echo -e "  ${MAGENTA}${BOLD}[0]${RESET}  Back to Main Menu"
  echo ""
  echo -en "  ${BOLD}Select [0-5]: ${RESET}"
  read -r c

  case "$c" in
    1) cli_ensure_udocker; hermes_agent_submenu ;;
    2) cli_ensure_udocker; cli_run "$ROOT_DIR/apps/crewai/crewai.sh" ;;
    3) cli_ensure_udocker; cli_run "$ROOT_DIR/apps/tailscale/tailscale.sh" ;;
    4) bash "$PREFIX/bin/roc-agent" "${@:-}" ;;
    5) PORT=3000 cli_run "$CLI_DIR/pyhttp.sh" ;;
    0|q|Q) exit 0 ;;
    *) echo -e "\n  ${RED}Invalid.${RESET}"; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
