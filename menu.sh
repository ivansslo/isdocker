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
  echo "  ║           roc-containers · Termux Container Manager       ║"
  echo "  ║               (c) 2026 | @ivansslo                  ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  # Quick Status Info
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
  [ "$cat" = "sec" ] && color="${RED}"
  [ "$cat" = "sys" ] && color="${MAGENTA}"
  [ "$cat" = "net" ] && color="${BLUE}"
  printf "  ${color}${BOLD}[%2s]${RESET}  %-28s" "$num" "$label"
  [ -n "$port" ] && echo -e "${DIM}→ port $port${RESET}" || echo ""
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

  print_section "🐧  Operating Systems"
  print_item  01  "Ubuntu 22.04 LTS"               2223  "os"
  print_item  02  "Debian 12 Bookworm"             2224  "os"

  print_section "🛡️  Security & Pentest"
  print_item  03  "Kali NetHunter (Full)"          2222  "sec"
  print_item  04  "Kali Linux (Minimal)"           2222  "sec"

  print_section "☁️  Apps & Dev"
  print_item  05  "JupyterLab / Dev"               8888  "app"

  print_section "⌨️  CLI Command"
  print_item  06  "CLI Command (CrewAI/Tailscale/HTTP)" ""  "net"

  print_section "🟦  Google Project"
  print_item  07  "Google Project (GCP tools)"     ""    "net"

  print_section "🔧  System Utilities"
  print_item  08  "Container Manager (ID/Status)"  ""    "sys"
  print_item  09  "System Info (RAM/CPU)"          ""    "sys"
  print_item  10  "Uninstall / Clean"              ""    "sys"
  print_item  11  "Update roc-containers"                ""    "sys"
  print_item  12  "Reinstall udocker"              ""    "sys"
  print_item  00  "Exit"                           ""    "sys"

  echo ""
  echo -en "  ${BOLD}Select option [00-12]: ${RESET}"
  read -r choice

  case "$choice" in
    1|01) ensure_udocker; launch_with_port "$SCRIPT_DIR/os/ubuntu/ubuntu.sh" 2223 ;;
    2|02) ensure_udocker; launch_with_port "$SCRIPT_DIR/os/debian/debian.sh" 2224 ;;

    3|03)
      ensure_udocker
      echo -e "\n  ${RED}${BOLD}[!] Large download (kali-linux-headless)${RESET}"
      echo -en "  Continue? [y/N]: " ; read -r confirm
      [[ "${confirm,,}" == "y" ]] && launch_with_port "$SCRIPT_DIR/os/nethunter/nethunter.sh" 2222
      ;;
    4|04) ensure_udocker; launch_with_port "$SCRIPT_DIR/os/kali/kali.sh" 2222 ;;

    5|05) ensure_udocker; launch_with_port "$SCRIPT_DIR/apps/jupyter/jupyter.sh" 8888 ;;
    6|06) run_script "$SCRIPT_DIR/lib/cli_command.sh" ;;

    7|07) run_script "$SCRIPT_DIR/lib/google_project.sh" ;;

    8|08) ensure_udocker; run_script "$SCRIPT_DIR/lib/manager.sh" ;;
    9|09) run_script "$SCRIPT_DIR/lib/sysinfo.sh" ;;
    10) run_script "$SCRIPT_DIR/lib/uninstall.sh" ;;
    11) run_script "$SCRIPT_DIR/lib/update.sh" ;;
    12) run_script "$SCRIPT_DIR/install_udocker.sh" ;;

    0|00|q|Q|exit) echo -e "\n  Goodbye.\n" ; exit 0 ;;
    *) echo -e "\n  Invalid option." ; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
