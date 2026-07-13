#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════
#  roc-containers · Setup & Command Installer
#  Repo: ivansslo/roc-containers
# ══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

VERSION="1.0.0"
BIN_DIR="${PREFIX:-$HOME/.local}/bin"
ROC_DIR="$HOME/.roc-containers"

echo -e "${CYAN}${BOLD}"
echo " ╔══════════════════════════════════════════════════════╗"
echo " ║  ⚡ roc-containers · Setup v${VERSION}                ║"
echo " ║  Container Manager + AI Agent CLI                   ║"
echo " ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── 1. Clone repo jika belum ada ──────────────────────
if [ ! -d "$ROC_DIR" ]; then
    echo -e "${YELLOW}[1/5] Cloning roc-containers...${RESET}"
    pkg install git -y 2>/dev/null || true
    git clone --depth 1 https://github.com/ivansslo/roc-containers "$ROC_DIR"
else
    echo -e "${GREEN}[1/5] roc-containers sudah ada, updating...${RESET}"
    git -C "$ROC_DIR" pull --ff-only 2>/dev/null || true
fi

# ─── 2. Install dependencies ──────────────────────────
echo -e "\n${YELLOW}[2/5] Installing dependencies...${RESET}"
pkg install -y git curl 2>/dev/null || true

# Install udocker
if ! command -v udocker &>/dev/null; then
    echo -e "  ${DIM}Installing udocker...${RESET}"
    bash "$ROC_DIR/install_udocker.sh"
fi

# ─── 3. Clone roc-agentsroute (CLI utama) ─────────────
echo -e "\n${YELLOW}[3/5] Setting up roc-agent CLI...${RESET}"
AGENT_DIR="$ROC_DIR/apps/roc-agent"
if [ ! -d "$AGENT_DIR" ]; then
    git clone --depth 1 https://github.com/ivansslo/roc-agentsroute "$AGENT_DIR"
else
    git -C "$AGENT_DIR" pull --ff-only 2>/dev/null || true
fi

# ─── 4. Install Python venv untuk roc-agent ───────────
echo -e "\n${YELLOW}[4/5] Setting up Python venv...${RESET}"
if command -v python3 &>/dev/null; then
    mkdir -p "$HOME/.hermes"
    if [ ! -x "$HOME/.hermes/python3_venv/bin/python" ]; then
        pkg install -y python 2>/dev/null || true
        python3 -m venv "$HOME/.hermes/python3_venv" 2>/dev/null || true
        if [ -x "$HOME/.hermes/python3_venv/bin/python" ]; then
            "$HOME/.hermes/python3_venv/bin/python" -m pip install -U pip rich pygments prompt_toolkit requests >/dev/null 2>&1 || true
            echo -e "  ${GREEN}✅ Python venv ready${RESET}"
        fi
    else
        echo -e "  ${GREEN}✅ Python venv already exists${RESET}"
    fi
else
    pkg install -y python 2>/dev/null || true
    echo -e "  ${YELLOW}⚠ Python installed, run setup again for venv${RESET}"
fi

# ─── 5. Install semua command ke bin ──────────────────
echo -e "\n${YELLOW}[5/5] Installing commands...${RESET}"
mkdir -p "$BIN_DIR"

# Helper: buat wrapper command
make_cmd() {
    local cmd_name="$1"
    local script_path="$2"
    local description="$3"

    cat > "$BIN_DIR/$cmd_name" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# $cmd_name — $description
exec bash "$ROC_DIR/$script_path" "\$@"
EOF
    chmod +x "$BIN_DIR/$cmd_name"
    printf "  ${GREEN}✅${RESET} %-20s %s\n" "$cmd_name" "$description"
}

# ── ROC-AGENT: wrapper khusus (jalan langsung di Termux) ──
cat > "$BIN_DIR/roc-agent" << 'AGENT_WRAPPER'
#!/data/data/com.termux/files/usr/bin/bash
# roc-agent — AI Agent CLI (roc-agentsroute)
# Jalan langsung di Termux

ROC_DIR="$HOME/.roc-containers"
AGENT_DIR="$ROC_DIR/apps/roc-agent"
HERMES_BIN="$AGENT_DIR/hermes"

if [ ! -f "$HERMES_BIN" ]; then
    echo "❌ roc-agent CLI tidak ditemukan: $HERMES_BIN"
    echo "   Jalankan: bash $ROC_DIR/setup.sh"
    exit 1
fi

# Load keys
[ -f "$HOME/.hermes_keys" ] && source "$HOME/.hermes_keys" 2>/dev/null
if [ -f "$HOME/.hermes/.keys" ]; then
    while IFS='=' read -r key val; do
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        val="${val%\"}" ; val="${val#\"}" ; val="${val%\'}" ; val="${val#\'}"
        [ -z "${!key:-}" ] && export "$key=$val"
    done < "$HOME/.hermes/.keys"
fi

exec bash "$HERMES_BIN" "$@"
AGENT_WRAPPER
chmod +x "$BIN_DIR/roc-agent"
printf "  ${GREEN}✅${RESET} %-20s %s\n" "roc-agent" "AI Agent CLI (Termux native)"

# ── OS Containers ──
make_cmd "roc-ubuntu"      "os/ubuntu/ubuntu.sh"        "Ubuntu 22.04 (port 2223)"
make_cmd "roc-debian"      "os/debian/debian.sh"        "Debian 12 (port 2224)"
make_cmd "roc-hermui"      "apps/hermui/hermui.sh"      "Hermes UI (ivansslo/hermes-ui)"

# ── ⭐ AI Stack (Primary) ──
make_cmd "roc-ai"          "apps/ai/ai.sh"              "⭐ RoadFX AI Stack (ivansslo/roadfx-ai-stack)"

# ── AI & Dev Apps ──
make_cmd "roc-crewai"      "apps/crewai/crewai.sh"                "CrewAI multi-agent"
make_cmd "roc-hms"       "apps/hms/hms.sh"              "Hermes Agent (container, root)"
make_cmd "roc-antigravity" "apps/antigravity/antigravity.sh"      "Antigravity AI IDE (port 5905)"
make_cmd "roc-adk"         "apps/adk-invoice/adk-invoice.sh"      "ADK Invoice (port 8000)"

# ── Network & Services ──
make_cmd "roc-tailscale"   "apps/tailscale/tailscale.sh"  "Tailscale VPN node"
make_cmd "roc-httpd"       "apps/httpd/httpd.sh"          "HTTP Server (port 3000)"
make_cmd "roc-spwr"  "apps/spwr/spwr.sh"  "Superpowers (coding agent skills)"
make_cmd "roc-clawdex"    "apps/clawdex/clawdex.sh"    "Clawdex Mobile (ivansslo/clawdex-mobile)"
make_cmd "roc-maagba"     "apps/maagba/maagba.sh"     "Multi-Agent Architectural Guidance (Bedrock AgentCore)"

# ── Google Cloud ──
make_cmd "roc-gcp"         "lib/google_project.sh"        "Google Project (GCP)"

# ── System ──
make_cmd "roc-menu"        "menu.sh"                      "roc-containers menu"
make_cmd "roc-status"      "lib/manager.sh"               "Container manager"
make_cmd "roc-sysinfo"     "lib/sysinfo.sh"               "System info"
make_cmd "roc-update"      "lib/update.sh"                "Update roc-containers"
make_cmd "roc-uninstall"   "lib/uninstall.sh"             "Uninstall / clean"
make_cmd "roc-udocker"     "install_udocker.sh"           "Reinstall udocker"

# ════════════════════════════════════════════════════════
#  Verifikasi
# ════════════════════════════════════════════════════════
echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD} ✅ roc-containers v${VERSION} ter-install!${RESET}\n"

echo -e " ${BOLD}Quick Start:${RESET}"
echo -e "  ${CYAN}roc-agent setup${RESET}         Setup API keys"
echo -e "  ${CYAN}roc-agent chat${RESET}          Chat dengan AI"
echo -e "  ${CYAN}roc-agent ask 'halo'${RESET}     Quick question"
echo -e "  ${CYAN}roc-hms setup         Setup Hermes Agent (container)"
echo -e "  ${CYAN}roc-tailscale${RESET}           Setup Tailscale VPN"
echo -e "  ${CYAN}roc-menu${RESET}                Menu utama"
echo -e "  ${CYAN}roc-status${RESET}              Cek container status"
echo ""
echo -e " ${DIM}Semua command ada di $BIN_DIR/${RESET}"
echo -e " ${DIM}Data ada di $ROC_DIR/${RESET}"
