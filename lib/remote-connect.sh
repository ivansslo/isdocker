#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════
#  roc-remote · Quick connect ke remote dev environments
#  Usage: roc-remote [codespace|cloudshell|oracle|aiven|solace]
# ══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

show_menu() {
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  🌐 roc-remote · Remote Dev Connect                ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${BOLD}1.${RESET} GitHub Codespaces  ${DIM}(120 jam/bln, browser+terminal)${RESET}"
    echo -e "  ${BOLD}2.${RESET} Google Cloud Shell ${DIM}(unlimited, web terminal)${RESET}"
    echo -e "  ${BOLD}3.${RESET} Oracle Cloud VM    ${DIM}(24GB ARM, free forever)${RESET}"
    echo -e "  ${BOLD}4.${RESET} Custom SSH Server  ${DIM}(server/VPS sendiri)${RESET}"
    echo -e "  ${BOLD}5.${RESET} Aiven PostgreSQL   ${DIM}(remote database)${RESET}"
    echo -e "  ${BOLD}6.${RESET} Solace PubSub+     ${DIM}(message broker)${RESET}"
    echo -e "  ${BOLD}7.${RESET} Cloudflare Workers ${DIM}(roc-site dashboard)${RESET}"
    echo -e "  ${BOLD}0.${RESET} Keluar"
    echo ""
    echo -ne "  ${BOLD}Pilih [0-7]: ${RESET}"
    read -r choice
    echo ""

    case "$choice" in
        1) connect_codespace ;;
        2) connect_cloudshell ;;
        3) connect_oracle ;;
        4) connect_ssh ;;
        5) connect_aiven ;;
        6) connect_solace ;;
        7) connect_cfworkers ;;
        0) exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid${RESET}"; show_menu ;;
    esac
}

# ─── GitHub Codespaces ─────────────────────────────────
connect_codespace() {
    echo -e "${CYAN}${BOLD}📦 GitHub Codespaces${RESET}\n"
    
    if ! command -v gh &>/dev/null; then
        echo -e "${YELLOW}Installing GitHub CLI...${RESET}"
        pkg install -y gh 2>/dev/null || true
    fi

    # Check login
    if ! gh auth status &>/dev/null 2>&1; then
        echo -e "${YELLOW}Login dulu ke GitHub:${RESET}"
        gh auth login
    fi

    # List codespaces
    echo -e "${CYAN}Codespaces kamu:${RESET}\n"
    CODESPACES=$(gh codespace list 2>/dev/null || echo "")
    
    if [ -z "$CODESPACES" ] || echo "$CODESPACES" | grep -q "no codespaces"; then
        echo -e "${YELLOW}Belum ada codespace. Buat baru? [y/n]${RESET}"
        read -r create
        if [ "$create" = "y" ]; then
            echo -e "${CYAN}Membuat codespace untuk ivansslo/roc-containers...${RESET}"
            gh codespace create -r ivansslo/roc-containers -b main
            echo -e "${GREEN}✅ Codespace dibuat!${RESET}"
        fi
    fi

    echo -e "\n${CYAN}Pilih aksi:${RESET}"
    echo "  1. SSH ke codespace"
    echo "  2. Port-forward"
    echo "  3. Buka di browser"
    echo -ne "  ${BOLD}Pilih: ${RESET}"
    read -r action

    case "$action" in
        1)
            CS_NAME=$(gh codespace list --json name -q '.[0].name' 2>/dev/null)
            if [ -n "$CS_NAME" ]; then
                echo -e "${GREEN}Connecting via SSH...${RESET}"
                gh codespace ssh -c "$CS_NAME"
            fi
            ;;
        2)
            CS_NAME=$(gh codespace list --json name -q '.[0].name' 2>/dev/null)
            echo -ne "  Port lokal: "
            read -r local_port
            echo -ne "  Port remote: "
            read -r remote_port
            gh codespace port-forward -c "$CS_NAME" "${local_port}:${remote_port}"
            ;;
        3)
            gh codespace open 2>/dev/null || echo "Buka https://github.com/codespaces di browser"
            ;;
    esac
}

# ─── Google Cloud Shell ────────────────────────────────
connect_cloudshell() {
    echo -e "${CYAN}${BOLD}☁️ Google Cloud Shell${RESET}\n"
    echo -e "${DIM}Cloud Shell hanya bisa diakses via browser.${RESET}"
    echo -e "${DIM}Tidak ada akses SSH/Termux langsung.${RESET}\n"
    echo -e "  ${CYAN}1.${RESET} Buka di browser:"
    echo -e "     ${BOLD}https://shell.cloud.google.com${RESET}"
    echo ""
    echo -e "  ${CYAN}2.${RESET} Quick setup (setelah login):"
    echo -e "     ${DIM}git clone https://github.com/ivansslo/roc-containers${RESET}"
    echo -e "     ${DIM}cd roc-containers && bash setup.sh --cloud-shell${RESET}"
    echo ""
    echo -e "  ${CYAN}3.${RESET} Atau one-liner:"
    echo -e "     ${BOLD}curl -fsSL https://raw.githubusercontent.com/ivansslo/roc-containers/main/lib/cloud-init.sh | bash${RESET}"
    echo ""
    
    # Open in browser if possible
    if command -v termux-open-url &>/dev/null; then
        echo -ne "  Buka browser sekarang? [y/n]: "
        read -r open
        [ "$open" = "y" ] && termux-open-url "https://shell.cloud.google.com"
    fi
}

# ─── Oracle Cloud VM ───────────────────────────────────
connect_oracle() {
    echo -e "${CYAN}${BOLD}🖥️ Oracle Cloud Free Tier${RESET}\n"
    
    # Check for saved SSH config
    OCI_CONFIG="$HOME/.config/hermes/oracle-cloud.env"
    if [ -f "$OCI_CONFIG" ]; then
        source "$OCI_CONFIG"
        echo -e "  ${GREEN}✅ Config ditemukan:${RESET}"
        echo -e "    IP: ${BOLD}${OCI_PUBLIC_IP:-?}${RESET}"
        echo -e "    User: ${BOLD}${OCI_USER:-ubuntu}${RESET}"
        echo -e "    Key: ${BOLD}${OCI_SSH_KEY:-?}${RESET}"
        echo ""
    else
        echo -e "  ${YELLOW}Belum ada konfigurasi Oracle Cloud.${RESET}\n"
        echo -e "  ${BOLD}Cara setup:${RESET}"
        echo "  1. Daftar di https://cloud.oracle.com/free"
        echo "  2. Create Compute Instance → VM.Standard.A1.Flex (ARM, Always Free)"
        echo "  3. Set 4 OCPU + 24GB RAM"
        echo "  4. Download SSH private key"
        echo "  5. Simpan konfigurasi di sini"
        echo ""
        echo -e "  ${YELLOW}Simpan konfigurasi? [y/n]${RESET}"
        read -r save
        if [ "$save" = "y" ]; then
            mkdir -p "$(dirname "$OCI_CONFIG")"
            echo -ne "  Public IP: "; read -r OCI_PUBLIC_IP
            echo -ne "  Username [ubuntu]: "; read -r OCI_USER; OCI_USER="${OCI_USER:-ubuntu}"
            echo -ne "  SSH Key path [~/.ssh/id_oracle]: "; read -r OCI_SSH_KEY; OCI_SSH_KEY="${OCI_SSH_KEY:-$HOME/.ssh/id_oracle}"
            cat > "$OCI_CONFIG" << ENV
OCI_PUBLIC_IP="$OCI_PUBLIC_IP"
OCI_USER="$OCI_USER"
OCI_SSH_KEY="$OCI_SSH_KEY"
ENV
            chmod 600 "$OCI_CONFIG"
            echo -e "${GREEN}✅ Config saved!${RESET}"
        fi
    fi

    if [ -f "$OCI_CONFIG" ]; then
        source "$OCI_CONFIG"
        echo -e "  ${BOLD}Pilih aksi:${RESET}"
        echo "  1. SSH connect"
        echo "  2. Install roc-containers (one-liner)"
        echo "  3. Install RDP desktop"
        echo "  4. Edit config"
        echo -ne "  ${BOLD}Pilih: ${RESET}"
        read -r action

        case "$action" in
            1) ssh -i "$OCI_SSH_KEY" "${OCI_USER}@${OCI_PUBLIC_IP}" ;;
            2) ssh -i "$OCI_SSH_KEY" "${OCI_USER}@${OCI_PUBLIC_IP}" "curl -fsSL https://raw.githubusercontent.com/ivansslo/roc-containers/main/lib/cloud-init.sh | bash" ;;
            3) ssh -i "$OCI_SSH_KEY" "${OCI_USER}@${OCI_PUBLIC_IP}" "curl -fsSL https://raw.githubusercontent.com/ivansslo/roc-containers/main/lib/cloud-init.sh | bash -s -- --with-rdp" ;;
            4) nano "$OCI_CONFIG" ;;
        esac
    fi
}

# ─── Custom SSH ────────────────────────────────────────
connect_ssh() {
    echo -e "${CYAN}${BOLD}🔌 Custom SSH Server${RESET}\n"
    echo -ne "  Host/IP: "; read -r host
    echo -ne "  Port [22]: "; read -r port; port="${port:-22}"
    echo -ne "  Username: "; read -r user
    echo -ne "  Key file [~/.ssh/id_rsa]: "; read -r key; key="${key:-$HOME/.ssh/id_rsa}"
    
    echo -e "\n${GREEN}Connecting...${RESET}"
    ssh -i "$key" -p "$port" "${user}@${host}"
}

# ─── Aiven PostgreSQL ──────────────────────────────────
connect_aiven() {
    echo -e "${CYAN}${BOLD}🐘 Aiven PostgreSQL${RESET}\n"
    source ~/.config/hermes/solace.env 2>/dev/null || true
    
    echo -e "  ${BOLD}Server tersedia:${RESET}"
    echo "  1. pg-roadfx (PRIMARY) — Jakarta"
    echo "  2. pg-224e6d29 (SECONDARY) — Africa"
    echo -ne "\n  ${BOLD}Pilih [1/2]: ${RESET}"
    read -r db_choice

    case "$db_choice" in
        1)
            if [ -n "$AIVEN_PG_URI" ]; then
                echo -e "${GREEN}Connecting to pg-roadfx...${RESET}"
                psql "$AIVEN_PG_URI"
            else
                echo -e "${YELLOW}AIVEN_PG_URI not set. Run setup first.${RESET}"
            fi
            ;;
        2)
            if [ -n "$AIVEN_PG2_URI" ]; then
                echo -e "${GREEN}Connecting to pg-224e6d29...${RESET}"
                psql "$AIVEN_PG2_URI"
            else
                echo -e "${YELLOW}AIVEN_PG2_URI not set. Run setup first.${RESET}"
            fi
            ;;
    esac
}

# ─── Solace PubSub+ ───────────────────────────────────
connect_solace() {
    echo -e "${CYAN}${BOLD}📡 Solace PubSub+${RESET}\n"
    source ~/.config/hermes/solace.env 2>/dev/null || true
    
    echo -e "  ${BOLD}Queues:${RESET}"
    echo "  1. hermes/agent/ai-chat"
    echo "  2. hermes/agent/memory"
    echo "  3. hermes/agent/orchestrator"
    echo "  4. hermes/agent/tools"
    echo "  5. hermes/events"
    echo ""
    echo -ne "  ${BOLD}Pilih aksi [status/publish/quit]: ${RESET}"
    read -r action

    case "$action" in
        status)
            echo -e "${CYAN}Checking Solace status...${RESET}"
            curl -s -u "$SOLACE_USER:$SOLACE_PASS" \
                "https://$SOLACE_HOST/SEMP/v2/monitor/msgVpns/$SOLACE_VPN/queues" \
                2>/dev/null | jq '.data[] | {name: .queueName, msgCount: .msgSpoolUsage}' 2>/dev/null \
                || echo "SEMP API restricted on developer tier"
            ;;
        publish)
            echo -ne "  Queue [hermes/events]: "; read -r queue; queue="${queue:-hermes/events}"
            echo -ne "  Message: "; read -r msg
            curl -s -X POST \
                -u "$SOLACE_USER:$SOLACE_PASS" \
                "https://$SOLACE_HOST/TOPIC/$queue" \
                -d "$msg" \
                -H "Content-Type: text/plain"
            echo -e "\n${GREEN}✅ Message sent!${RESET}"
            ;;
    esac
}

# ─── Cloudflare Workers ────────────────────────────────
connect_cfworkers() {
    echo -e "${CYAN}${BOLD}⚡ Cloudflare Workers${RESET}\n"
    echo -e "  ${BOLD}Dashboard:${RESET}"
    echo "    https://roadfx.biz.id"
    echo ""
    echo -e "  ${BOLD}AI Gateway:${RESET}"
    echo "    https://ai.roadfx.biz.id"
    echo ""
    echo -e "  ${BOLD}Manage Workers:${RESET}"
    echo "    https://dash.cloudflare.com → Workers & Pages"
    echo ""
    
    if command -v termux-open-url &>/dev/null; then
        echo -ne "  Buka dashboard di browser? [y/n]: "
        read -r open
        [ "$open" = "y" ] && termux-open-url "https://roadfx.biz.id"
    fi
}

# ─── Main ──────────────────────────────────────────────
if [ -n "$1" ]; then
    case "$1" in
        codespace|cs)   connect_codespace ;;
        cloudshell|gcs) connect_cloudshell ;;
        oracle|oci)     connect_oracle ;;
        ssh)            connect_ssh ;;
        aiven|pg)       connect_aiven ;;
        solace)         connect_solace ;;
        cf|workers)     connect_cfworkers ;;
        *)              echo "Usage: roc-remote [codespace|cloudshell|oracle|ssh|aiven|solace|cf]" ;;
    esac
else
    show_menu
fi
