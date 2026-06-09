#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  isdocker · Interactive Install Menu
#  Repo: https://github.com/ivansslo/isdocker
# ═══════════════════════════════════════════════════════════════════

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
  echo "  ║           isdocker · Termux Container Manager       ║"
  echo "  ║         github.com/ivansslo/isdocker                ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

print_section(){
  echo -e "\n${YELLOW}${BOLD}  ── $1 ──${RESET}"
}

print_item(){
  local num="$1" label="$2" port="$3" cat="$4"
  local color="${CYAN}"
  [ "$cat" = "os" ]  && color="${GREEN}"
  [ "$cat" = "sec" ] && color="${RED}"
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

# ── Install udocker ──────────────────────────────────────────────────
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

  print_section "🛡️  Security / Penetration Testing OS"
  print_item  1  "Kali NetHunter (full tools)"   2222  "sec"
  print_item  2  "Kali Linux (minimal shell)"     2222  "sec"

  print_section "🐧  Linux OS"
  print_item  3  "Ubuntu 22.04 LTS"               2223  "os"
  print_item  4  "Debian 12 Bookworm (slim)"       2224  "os"
  print_item  5  "Alpine Linux (latest)"           2225  "os"

  print_section "☁️  Self-Hosted Apps"
  print_item  6  "AdGuard Home"                   8123  "app"
  print_item  7  "Home Assistant"                 8123  "app"
  print_item  8  "Nextcloud"                      2080  "app"
  print_item  9  "ownCloud"                       2081  "app"
  print_item 10  "Puter (cloud OS)"               4100  "app"

  print_section "🎬  Media & Tools"
  print_item 11  "Jellyfin Media Server"          8096  "app"
  print_item 12  "Calibre-Web (eBooks)"           8083  "app"
  print_item 13  "Stirling PDF"                   8080  "app"
  print_item 14  "Apache HTTPD"                   2082  "app"
  print_item 15  "JupyterLab / Notebook"          8888  "app"

  print_section "⚙️  Dev / Infra"
  print_item 16  "Redis"                          6379  "app"
  print_item 17  "ROS 2 Jazzy"                    ""    "app"

  print_section "🖥️  VNC Desktop"
  print_item 19  "Ubuntu Desktop (VNC)"          5901  "app"
  print_item 20  "Debian Desktop (VNC)"          5902  "app"
  print_item 21  "Alpine Desktop (VNC)"          5903  "app"
  print_item 22  "Kali Desktop (VNC)"            5904  "app"

  print_section "🔧  System"
  print_item 18  "Install / Reinstall udocker"    ""    "sys"
  print_item  0  "Exit"                           ""    "sys"

  echo ""
  echo -en "  ${BOLD}Select option [0-22]: ${RESET}"
  read -r choice

  case "$choice" in

    # ── Security OS ────────────────────────────────────────────────
    1)
      ensure_udocker
      echo -e "\n  ${RED}${BOLD}[!] NetHunter will install kali-linux-headless (large download)${RESET}"
      echo -en "  Continue? [y/N]: "
      read -r confirm
      [[ "${confirm,,}" == "y" ]] && launch_with_port "$SCRIPT_DIR/os/nethunter/nethunter.sh" 2222
      ;;
    2)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/os/kali/kali.sh" 2222
      ;;

    # ── Linux OS ───────────────────────────────────────────────────
    3)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/os/ubuntu/ubuntu.sh" 2223
      ;;
    4)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/os/debian/debian.sh" 2224
      ;;
    5)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/os/alpine/alpine.sh" 2225
      ;;

    # ── Apps ───────────────────────────────────────────────────────
    6)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/adguard/adguard.sh" 8123
      ;;
    7)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/home-assistant/home-assistant.sh" 8123
      ;;
    8)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/nextcloud/nextcloud.sh" 2080
      ;;
    9)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/owncloud/owncloud.sh" 2081
      ;;
    10)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/puter/puter.sh" 4100
      ;;
    11)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/jellyfin/jellyfin.sh" 8096
      ;;
    12)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/calibre-web/calibre-web.sh" 8083
      ;;
    13)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/s-pdf/s-pdf.sh" 8080
      ;;
    14)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/httpd/httpd.sh" 2082
      ;;
    15)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/jupyter/jupyter.sh" 8888
      ;;
    16)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/redis/redis.sh" 6379
      ;;
    17)
      ensure_udocker
      echo -e "\n  ${GREEN}[*] Starting ROS 2 Jazzy...${RESET}\n"
      run_script "$SCRIPT_DIR/apps/ros/ros.sh"
      ;;

    # ── VNC Desktop ───────────────────────────────────────────────
    19)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/vnc-desktop/ubuntu-vnc.sh" 5901
      ;;
    20)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/vnc-desktop/debian-vnc.sh" 5902
      ;;
    21)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/vnc-desktop/alpine-vnc.sh" 5903
      ;;
    22)
      ensure_udocker
      launch_with_port "$SCRIPT_DIR/apps/vnc-desktop/kali-vnc.sh" 5904
      ;;

    # ── System ─────────────────────────────────────────────────────
    18)
      echo -e "\n  ${YELLOW}[*] Installing udocker...${RESET}\n"
      run_script "$SCRIPT_DIR/install_udocker.sh"
      echo -e "\n  ${GREEN}[✓] Done!${RESET}"
      sleep 2
      ;;

    0|q|Q|exit)
      echo -e "\n  ${DIM}Goodbye.${RESET}\n"
      exit 0
      ;;

    *)
      echo -e "\n  ${RED}  Invalid option. Press Enter to continue...${RESET}"
      read -r
      ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return to menu...${RESET}"
  read -r
done
