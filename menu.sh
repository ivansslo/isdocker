#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  v1.5.0 — NATIVE ONLY. Semua command berbasis container (udocker)
#  telah dihapus: roc-ubuntu/debian/httpd/tailscale/hms/crewai/adk/
#  antigravity. Menjalankan container kini manual via udocker:
#      udocker run <nama-container>
# ─────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────
print_header(){
  clear
  echo -e "${CYAN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║       roc-containers · AI Agent CLI (native)         ║"
  echo "  ║               v1.5.0 (c) 2026 | @ivansslo            ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}OS: $(uname -m)${RESET}"
}

print_section(){
  echo -e "\n${YELLOW}${BOLD}  ── $1 ──${RESET}"
}

print_item(){
  local num="$1" label="$2" note="$3" cat="$4"
  local color="${CYAN}"
  [ "$cat" = "ai" ]  && color="${MAGENTA}"
  [ "$cat" = "app" ] && color="${BLUE}"
  [ "$cat" = "sys" ] && color="${DIM}"
  printf "  ${color}${BOLD}[%2s]${RESET}  %-30s" "$num" "$label"
  [ -n "$note" ] && echo -e "${DIM}→ $note${RESET}" || echo ""
}

run_script(){
  local script="$1"
  shift
  if [ ! -f "$script" ]; then
    echo -e "${RED}  [!] Script not found: $script${RESET}"
    sleep 2; return
  fi
  chmod +x "$script"
  bash "$script" "$@"
}

ensure_udocker(){
  if ! udocker -V &>/dev/null 2>&1; then
    echo -e "\n${YELLOW}  [*] udocker not found — installing...${RESET}"
    run_script "$SCRIPT_DIR/install_udocker.sh"
  fi
}

# ════════════════════════════════════════════════════════════════════
#  MAIN LOOP
# ════════════════════════════════════════════════════════════════════
while true; do
  print_header

  # ── ⭐ AI Stack ──
  print_section "⭐  AI Stack (Primary)"
  print_item  01  "RoadFX AI Stack"               "roc-ai"   "ai"
  print_item  02  "AI Agent Mesh"                 "roc-ai mesh" "ai"
  print_item  03  "🚀 roc-ai Orchestrator"        "roc-ai orchestrator" "ai"

  # ── 🤖 AI & Agent ──
  print_section "🤖  AI & Agent"
  print_item  04  "AI Agent CLI"                  "roc-agent" "ai"
  print_item  05  "MAAGBA (Bedrock AgentCore)"    "roc-maagba" "ai"

  # ── 📦 Apps (native) ──
  print_section "📦  Apps"
  print_item  06  "Superpowers (agent skills)"    "roc-spwr"   "app"
  print_item  07  "Hermes UI (dashboard)"         "roc-hermui" "app"
  print_item  08  "Clawdex Mobile"                "roc-clawdex" "app"

  # ── ⚙️ System ──
  print_section "⚙️  System"
  print_item  09  "Container Status (udocker)"    "run manual: udocker run <nama>"  "sys"
  print_item  10  "Google Cloud (GCP)"            ""  "sys"
  print_item  11  "System Info (RAM/CPU)"         ""  "sys"
  print_item  12  "Update roc-containers"         ""  "sys"
  print_item  13  "Uninstall / Clean"             ""  "sys"
  print_item  14  "Install/Repair udocker"        ""  "sys"
  print_item  15  "Remote Dev Connect"            "codespaces/oracle/aiven" "sys"
  print_item  00  "Exit"                          ""  "sys"

  echo ""
  echo -en "  ${BOLD}Select option [00-15]: ${RESET}"
  read -r choice

  case "$choice" in
    # ── ⭐ AI Stack ──
    1|01) run_script "$SCRIPT_DIR/apps/ai/ai.sh" ;;
    2|02) run_script "$SCRIPT_DIR/apps/ai/ai.sh" mesh ;;
    3|03)
      if command -v roc-ai &>/dev/null; then roc-ai orchestrator
      else bash "$SCRIPT_DIR/apps/ai/ai.sh" orchestrator; fi
      ;;

    # ── 🤖 AI & Agent ──
    4|04)
      if command -v roc-agent &>/dev/null; then roc-agent "${@:-}"
      elif [ -n "${PREFIX:-}" ] && [ -f "$PREFIX/bin/roc-agent" ]; then bash "$PREFIX/bin/roc-agent" "${@:-}"
      elif [ -f "$SCRIPT_DIR/apps/roc-agent/hermes" ]; then bash "$SCRIPT_DIR/apps/roc-agent/hermes" "${@:-}"
      else echo -e "  ${RED}roc-agent belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      ;;
    5|05) run_script "$SCRIPT_DIR/apps/maagba/maagba.sh" ;;

    # ── 📦 Apps ──
    6|06) run_script "$SCRIPT_DIR/apps/spwr/spwr.sh" ;;
    7|07) run_script "$SCRIPT_DIR/apps/hermui/hermui.sh" ;;
    8|08) run_script "$SCRIPT_DIR/apps/clawdex/clawdex.sh" ;;

    # ── ⚙️ System ──
    9|09)  ensure_udocker; run_script "$SCRIPT_DIR/lib/manager.sh" ;;
    10)    run_script "$SCRIPT_DIR/lib/google_project.sh" ;;
    11)    run_script "$SCRIPT_DIR/lib/sysinfo.sh" ;;
    12)    run_script "$SCRIPT_DIR/lib/update.sh" ;;
    13)    run_script "$SCRIPT_DIR/lib/uninstall.sh" ;;
    14)    run_script "$SCRIPT_DIR/install_udocker.sh" ;;
    15)    run_script "$SCRIPT_DIR/lib/remote-connect.sh" ;;

    0|00|q|Q|exit) echo -e "\n  Goodbye.\n" ; exit 0 ;;
    *) echo -e "\n  Invalid option." ; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
