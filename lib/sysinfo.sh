#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env"

clear
echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo "  ║               isdocker · System Information          ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

echo -e "  ${YELLOW}${BOLD}── Device Info ──${RESET}"
echo -e "  ${CYAN}Model    :${RESET} $(getprop ro.product.model)"
echo -e "  ${CYAN}Android  :${RESET} $(getprop ro.build.version.release)"
echo -e "  ${CYAN}Arch     :${RESET} $(uname -m)"

echo -e "\n  ${YELLOW}${BOLD}── Resource Usage ──${RESET}"
# Memory info
free_mem=$(free -m | awk '/Mem:/ {print $4}')
total_mem=$(free -m | awk '/Mem:/ {print $2}')
echo -e "  ${CYAN}RAM      :${RESET} ${free_mem}MB free / ${total_mem}MB total"

# CPU info
cpu_cores=$(nproc)
echo -e "  ${CYAN}CPU Cores:${RESET} ${cpu_cores}"

# Disk info
disk_free=$(df -h /data | awk 'NR==2 {print $4}')
echo -e "  ${CYAN}Storage  :${RESET} ${disk_free} available on /data"

echo -e "\n  ${YELLOW}${BOLD}── udocker Info ──${RESET}"
if udocker -V &>/dev/null; then
    echo -e "  ${CYAN}Status   :${RESET} ${GREEN}Installed${RESET}"
    echo -e "  ${CYAN}Version  :${RESET} $(udocker -V | head -n 1)"
    echo -e "  ${CYAN}Containers:${RESET} $(udocker ps | wc -l | awk '{print $1-1}')"
else
    echo -e "  ${CYAN}Status   :${RESET} ${RED}Not Installed${RESET}"
fi

echo -e "\n  ${DIM}Press Enter to return...${RESET}"
read -r
