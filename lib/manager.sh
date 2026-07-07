#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env"

get_container_ip() {
    tailscale ip -4 2>/dev/null || echo "127.0.0.1"
}

list_containers_detailed() {
    clear
    echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           isdocker · Container Manager (2026)        ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Get list of containers
    containers=$(udocker ps | tail -n +2)
    local ip_addr=$(get_container_ip)

    if [ -z "$containers" ]; then
        echo -e "  ${RED}[!] No containers found.${RESET}"
    else
        printf "  ${YELLOW}%-10s %-18s %-12s %-12s${RESET}\n" "ID" "NAME" "STATUS" "IMAGE"
        echo "  ------------------------------------------------------------"
        
        while read -r line; do
            id=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | awk '{print $NF}')
            image=$(udocker inspect "$name" 2>/dev/null | grep '"Image":' | head -n 1 | cut -d '"' -f4)
            
            # Color status
            display_status="${RED}Stopped${RESET}"
            [ "$status" == "R" ] && display_status="${GREEN}Running${RESET}"
            [ "$status" == "I" ] && display_status="${DIM}Inactive${RESET}"

            printf "  %-10s %-18s %-20s %-12s\n" "$id" "$name" "$display_status" "${image:0:12}"
            
            # Connection Info
            case "$name" in
                *ubuntu*)     echo -e "    ${DIM}→ SSH: ssh root@$ip_addr -p 2223 (pass: ubuntu)${RESET}" ;;
                *debian*)     echo -e "    ${DIM}→ SSH: ssh root@$ip_addr -p 2224 (pass: debian)${RESET}" ;;
                *alpine*)     echo -e "    ${DIM}→ SSH: ssh root@$ip_addr -p 2225 (pass: alpine)${RESET}" ;;
                *kali-linux*) echo -e "    ${DIM}→ SSH: ssh root@$ip_addr -p 2222 (pass: kali)${RESET}" ;;
                *nethunter*)  echo -e "    ${DIM}→ SSH: ssh root@$ip_addr -p 2222 (pass: nethunter)${RESET}" ;;
                *windows-11*) echo -e "    ${DIM}→ VNC: $ip_addr:5900 | Web: http://$ip_addr:8006${RESET}" ;;
                *windows-7*)  echo -e "    ${DIM}→ VNC: $ip_addr:5901 | Web: http://$ip_addr:8007${RESET}" ;;
            esac
        done <<< "$containers"
    fi

    echo -e "\n  ${YELLOW}${BOLD}── Options ──${RESET}"
    echo -e "  ${CYAN}[1] Refresh List"
    echo -e "  [2] Start Container"
    echo -e "  [3] Stop Container"
    echo -e "  [4] Remove Container"
    echo -e "  [0] Back${RESET}"
    echo ""
    echo -en "  Select: "
    read -r choice

    case "$choice" in
        1) list_containers_detailed ;;
        2)
            echo -en "  Enter Name: " ; read -r t
            udocker run "$t" ;;
        3)
            echo -e "  (udocker containers stop when the main process ends)" ;;
        4)
            echo -en "  Enter Name to Remove: " ; read -r t
            udocker rm -f "$t" && echo "Removed." ;;
        0) return ;;
        *) list_containers_detailed ;;
    esac
    sleep 1
    list_containers_detailed
}

list_containers_detailed
