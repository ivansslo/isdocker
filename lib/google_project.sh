#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Google Project — submenu for GCP-based tools
#     • Provider GCP (credentials)
#     • Antigravity (Google AI IDE, web mode)
#     • ADK Invoice-Processing (google/adk-samples)
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env" 2>/dev/null

# Colors (fallback if not inherited from menu.sh)
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

GP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$GP_DIR/.." && pwd)"

# ── helpers (mirror menu.sh so this submenu works standalone) ────
gp_run(){
  local script="$1"; shift
  if [ ! -f "$script" ]; then
    echo -e "${RED}  [!] Script not found: $script${RESET}"; sleep 2; return
  fi
  chmod +x "$script"
  bash "$script" "$@"
}

gp_ask_port(){
  local default="$1" p
  echo -en "\n  ${YELLOW}Custom port? (Enter = $default): ${RESET}"
  read -r p
  if [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -gt 1023 ] && [ "$p" -lt 65536 ]; then
    echo "$p"
  else
    echo "$default"
  fi
}

gp_launch(){
  local script="$1" default_port="$2" port
  port="$(gp_ask_port "$default_port")"
  echo -e "\n  ${GREEN}[*] Launching on port $port ...${RESET}\n"
  PORT="$port" gp_run "$script"
}

gp_ensure_udocker(){
  udocker -V &>/dev/null 2>&1 || gp_run "$ROOT_DIR/install_udocker.sh"
}

# ── menu ─────────────────────────────────────────────────────────
while true; do
  clear
  echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo    "  ║             roc-containers · Google Project                ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${DIM}Tools berbasis Google Cloud / Gemini${RESET}\n"

  local_gemset="$(grep -qE '^GEMINI_API_KEY=.+' ~/.hermes_keys 2>/dev/null && echo yes || echo no)"
  local_proj="$(grep -E '^GCP_PROJECT=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
  echo -e "  ${DIM}Provider: key=${local_gemset}  project=${local_proj:-'(unset)'}${RESET}\n"

  echo -e "  ${BLUE}${BOLD}[1]${RESET}  Provider GCP (Gemini/Vertex creds)"
  echo -e "  ${CYAN}${BOLD}[2]${RESET}  Antigravity (Google AI IDE)   ${DIM}→ port 5905${RESET}"
  echo -e "  ${CYAN}${BOLD}[3]${RESET}  ADK Invoice-Processing        ${DIM}→ port 8000${RESET}"
  echo -e "  ${CYAN}${BOLD}[4]${RESET}  CrewAI (Gemini)               ${DIM}CLI${RESET}"
  echo -e "  ${MAGENTA}${BOLD}[0]${RESET}  Back to Main Menu"
  echo ""
  echo -en "  ${BOLD}Select [0-4]: ${RESET}"
  read -r c

  case "$c" in
    1) gp_run "$GP_DIR/gcp_provider.sh" ;;
    2) gp_ensure_udocker; gp_launch "$ROOT_DIR/apps/antigravity/antigravity.sh" 5905 ;;
    3) gp_ensure_udocker; gp_launch "$ROOT_DIR/apps/adk-invoice/adk-invoice.sh" 8000 ;;
    4) gp_ensure_udocker; gp_run "$ROOT_DIR/apps/crewai/crewai-gcp.sh" ;;
    0|q|Q) exit 0 ;;
    *) echo -e "\n  ${RED}Invalid.${RESET}"; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
