#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Uninstaller Utility

source "$(dirname "${BASH_SOURCE[0]}")/../lib/source.env"

show_uninstall_menu() {
    clear
    echo -e "${RED}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    echo -e "  ║               roc-containers · Uninstaller Menu            ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${YELLOW}1) Delete Specific Container"
    echo -e "  2) Delete Specific Image"
    echo -e "  3) Clean All Containers & Data"
    echo -e "  4) Clean Everything (Containers + Images + Data)"
    echo -e "  0) Back to Main Menu${RESET}"
    echo ""
    echo -en "  ${BOLD}Select option: ${RESET}"
    read -r sub_choice

    case "$sub_choice" in
        1)
            echo -e "\n  ${CYAN}[*] Active Containers:${RESET}"
            udocker ps
            echo -en "\n  Enter Container Name/ID to delete: "
            read -r target
            [ -n "$target" ] && udocker rm -f "$target" && echo -e "  ${GREEN}[✓] Container $target removed.${RESET}"
            ;;
        2)
            echo -e "\n  ${CYAN}[*] Downloaded Images:${RESET}"
            udocker images
            echo -en "\n  Enter Image Name/ID to delete: "
            read -r target
            [ -n "$target" ] && udocker rmi "$target" && echo -e "  ${GREEN}[✓] Image $target removed.${RESET}"
            ;;
        3)
            echo -en "\n  ${RED}Delete all containers and data folders? [y/N]: ${RESET}"
            read -r confirm
            if [[ "${confirm,,}" == "y" ]]; then
                udocker ps | cut -d\  -f1 | tail -n +2 | xargs -I {} udocker rm -f {} &>/dev/null
                rm -rf "$(dirname "${BASH_SOURCE[0]}")"/../data-*
                echo -e "  ${GREEN}[✓] All containers and data cleared.${RESET}"
            fi
            ;;
        4)
            echo -en "\n  ${RED}${BOLD}FULL PURGE: Delete EVERYTHING? [y/N]: ${RESET}"
            read -r confirm
            if [[ "${confirm,,}" == "y" ]]; then
                udocker ps | cut -d\  -f1 | tail -n +2 | xargs -I {} udocker rm -f {} &>/dev/null
                udocker images | cut -d\  -f1 | tail -n +2 | xargs -I {} udocker rmi {} &>/dev/null
                rm -rf "$(dirname "${BASH_SOURCE[0]}")"/../data-*
                echo -e "  ${GREEN}[✓] Everything purged.${RESET}"
            fi
            ;;
        0) return ;;
        *) echo "Invalid option." ;;
    esac
    sleep 2
}

show_uninstall_menu
