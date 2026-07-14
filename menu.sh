#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
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
  echo "  ║       roc-containers · Termux Container Manager      ║"
  echo "  ║               (c) 2026 | @ivansslo                   ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  local containers_count=$(udocker ps 2>/dev/null | tail -n +2 | wc -l | awk '{print $1}')
  echo -e "  ${DIM}OS: $(uname -m) | Containers: $containers_count${RESET}"
}

print_section(){
  echo -e "\n${YELLOW}${BOLD}  ── $1 ──${RESET}"
}

print_item(){
  local num="$1" label="$2" port="$3" cat="$4"
  local color="${CYAN}"
  [ "$cat" = "os" ]  && color="${GREEN}"
  [ "$cat" = "ai" ]  && color="${MAGENTA}"
  [ "$cat" = "app" ] && color="${BLUE}"
  [ "$cat" = "sys" ] && color="${DIM}"
  printf "  ${color}${BOLD}[%2s]${RESET}  %-30s" "$num" "$label"
  [ -n "$port" ] && echo -e "${DIM}→ $port${RESET}" || echo ""
}

ask_port(){
  local default="$1"
  echo -en "\n  ${YELLOW}Custom port? (Enter = $default): ${RESET}"
  read -r user_port
  if [[ "$user_port" =~ ^[0-9]+$ ]] && [ "$user_port" -gt 1023 ] && [ "$user_port" -lt 65536 ]; then
    echo "$user_port"
  else
    echo "$default"
  fi
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

launch_with_port(){
  local script="$1" default_port="$2"
  local port
  port="$(ask_port "$default_port")"
  echo -e "\n  ${GREEN}[*] Launching on port $port ...${RESET}\n"
  PORT="$port" run_script "$script"
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

  # ── 🤖 AI & Agent ──
  print_section "🤖  AI & Agent"
  print_item  03  "AI Agent CLI"                  "roc-agent" "ai"
  print_item  04  "CrewAI Multi-Agent"            "roc-crewai" "ai"
  print_item  05  "Hermes Agent (container)"      "roc-hms"   "ai"
  print_item  06  "Antigravity AI IDE"            "port 5905" "ai"
  print_item  07  "ADK Invoice Processing"        "port 8000" "ai"
  print_item  08  "MAAGBA (Bedrock AgentCore)"    "roc-maagba" "ai"

  # ── 🐧 OS Containers ──
  print_section "🐧  Operating Systems"
  print_item  09  "Ubuntu 22.04 LTS"              "port 2223" "os"
  print_item  10  "Debian 12 Bookworm"            "port 2224" "os"

  # ── 🌐 Network & Services ──
  print_section "🌐  Network & Services"
  print_item  11  "Tailscale VPN"                 "roc-tailscale" "app"
  print_item  12  "HTTP Server"                   "port 3000"  "app"
  print_item  13  "Superpowers (agent skills)"    "roc-spwr"   "app"
  print_item  14  "Hermes UI"                     "roc-hermui" "app"
  print_item  15  "Clawdex Mobile"                "roc-clawdex" "app"

  # ── ⚙️ System ──
  print_section "⚙️  System"
  print_item  16  "Container Manager (Status)"    ""  "sys"
  print_item  17  "Google Cloud (GCP)"            ""  "sys"
  print_item  18  "System Info (RAM/CPU)"         ""  "sys"
  print_item  19  "Update roc-containers"         ""  "sys"
  print_item  20  "Uninstall / Clean"             ""  "sys"
  print_item  21  "Reinstall udocker"             ""  "sys"
  print_item  00  "Exit"                          ""  "sys"

  echo ""
  echo -en "  ${BOLD}Select option [00-21]: ${RESET}"
  read -r choice

  case "$choice" in
    # ── ⭐ AI Stack ──
    1|01) run_script "$SCRIPT_DIR/apps/ai/ai.sh" ;;
    2|02) run_script "$SCRIPT_DIR/apps/ai/ai.sh" mesh ;;

    # ── 🤖 AI & Agent ──
    3|03) bash "$PREFIX/bin/roc-agent" "${@:-}" ;;
    4|04) ensure_udocker; run_script "$SCRIPT_DIR/apps/crewai/crewai.sh" ;;
    5|05) ensure_udocker; run_script "$SCRIPT_DIR/apps/hms/hms.sh" ;;
    6|06) ensure_udocker; launch_with_port "$SCRIPT_DIR/apps/antigravity/antigravity.sh" 5905 ;;
    7|07) ensure_udocker; launch_with_port "$SCRIPT_DIR/apps/adk-invoice/adk-invoice.sh" 8000 ;;
    8|08) run_script "$SCRIPT_DIR/apps/maagba/maagba.sh" ;;

    # ── 🐧 OS Containers ──
    9|09) ensure_udocker; launch_with_port "$SCRIPT_DIR/os/ubuntu/ubuntu.sh" 2223 ;;
    10)   ensure_udocker; launch_with_port "$SCRIPT_DIR/os/debian/debian.sh" 2224 ;;

    # ── 🌐 Network & Services ──
    11) ensure_udocker; run_script "$SCRIPT_DIR/apps/tailscale/tailscale.sh" ;;
    12) ensure_udocker; launch_with_port "$SCRIPT_DIR/apps/httpd/httpd.sh" 3000 ;;
    13) run_script "$SCRIPT_DIR/apps/spwr/spwr.sh" ;;
    14) run_script "$SCRIPT_DIR/apps/hermui/hermui.sh" ;;
    15) run_script "$SCRIPT_DIR/apps/clawdex/clawdex.sh" ;;

    # ── ⚙️ System ──
    16) ensure_udocker; run_script "$SCRIPT_DIR/lib/manager.sh" ;;
    17) run_script "$SCRIPT_DIR/lib/google_project.sh" ;;
    18) run_script "$SCRIPT_DIR/lib/sysinfo.sh" ;;
    19) run_script "$SCRIPT_DIR/lib/update.sh" ;;
    20) run_script "$SCRIPT_DIR/lib/uninstall.sh" ;;
    21) run_script "$SCRIPT_DIR/install_udocker.sh" ;;

    0|00|q|Q|exit) echo -e "\n  Goodbye.\n" ; exit 0 ;;
    *) echo -e "\n  Invalid option." ; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
