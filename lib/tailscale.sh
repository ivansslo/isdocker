#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/isdocker
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/source.env"

INSTALL_DIR="$HOME/.tailscale"

install_tailscale_cli() {
    echo -e "${YELLOW}[*] Installing Tailscale CLI...${RESET}"
    pkg update -y
    pkg install tailscale -y
    echo -e "${GREEN}[✓] Tailscale CLI installed.${RESET}"
}

start_daemon() {
    if ! pgrep tailscaled >/dev/null; then
        echo -e "${YELLOW}[*] Starting tailscaled daemon (userspace-networking)...${RESET}"
        # Create state directory
        mkdir -p "$HOME/.tailscale_state"
        # Start daemon in background
        tailscaled --tun=userspace-networking --statedir="$HOME/.tailscale_state" &>/dev/null &
        sleep 3
    fi
}

setup_tailscale() {
    clear
    echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
    echo "  ║             isdocker · Tailscale Manager             ║"
    echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if ! command -v tailscale &>/dev/null; then
        install_tailscale_cli
    fi

    start_daemon

    echo -e "  ${CYAN}[1] Login with Auth Token (Key)"
    echo -e "  [2] Login via Web Browser"
    echo -e "  [3] Connection Status"
    echo -e "  [4] Get My Tailscale IP"
    echo -e "  [5] Logout / Disconnect"
    echo -e "  [6] Stop Daemon"
    echo -e "  [0] Back to Menu${RESET}"
    echo ""
    echo -en "  Select: "
    read -r ts_choice

    case "$ts_choice" in
        1)
            echo -en "\n  Enter Tailscale Auth Key (tskey-auth-...): "
            read -r ts_token
            if [ -n "$ts_token" ]; then
                echo -e "  ${YELLOW}[*] Connecting with token...${RESET}"
                tailscale up --authkey="$ts_token" --hostname="isdocker-termux"
            else
                echo -e "  ${RED}[!] Token cannot be empty.${RESET}"
            fi
            ;;
        2)
            echo -e "  ${YELLOW}[*] Please visit the link below to authenticate:${RESET}"
            tailscale up --hostname="isdocker-termux"
            ;;
        3)
            echo -e "\n  ${GREEN}── Tailscale Status ──${RESET}"
            tailscale status
            ;;
        4)
            ts_ip=$(tailscale ip -4)
            if [ -n "$ts_ip" ]; then
                echo -e "\n  ${GREEN}[✓] Your IP: ${BOLD}$ts_ip${RESET}"
            else
                echo -e "\n  ${RED}[!] Not connected to Tailscale network.${RESET}"
            fi
            ;;
        5)
            tailscale logout
            echo -e "\n  ${YELLOW}[*] Logged out.${RESET}"
            ;;
        6)
            pkill tailscaled
            echo -e "\n  ${RED}[*] Daemon stopped.${RESET}"
            ;;
        0) return ;;
        *) echo "Invalid option." ;;
    esac
    echo -e "\n  ${DIM}Press Enter to continue...${RESET}"
    read -r
    setup_tailscale
}

setup_tailscale
