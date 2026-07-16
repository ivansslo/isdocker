#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════
#  roc-containers · Setup & Command Installer
#  Repo: ivansslo/roc-containers
# ══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

VERSION="1.5.4"
BIN_DIR="${PREFIX:-$HOME/.local}/bin"
ROC_DIR="$HOME/.roc-containers"

# Detect environment
CODESPACE="${CODESPACES:-}"
CLOUD_SHELL="${GOOGLE_CLOUD_SHELL:-}"
TERMUX="${TERMUX_VERSION:-}"
ENV_MODE="termux"
[ -n "$CODESPACE" ] && ENV_MODE="codespace"
[ -n "$CLOUD_SHELL" ] && ENV_MODE="cloud-shell"

# Flags
SKIP_UDOCKER=false
SKIP_TERMUX_PKG=false
for arg in "$@"; do
  [ "$arg" = "--codespace" ] && ENV_MODE="codespace" && SKIP_UDOCKER=true && SKIP_TERMUX_PKG=true
  [ "$arg" = "--cloud-shell" ] && ENV_MODE="cloud-shell" && SKIP_UDOCKER=true && SKIP_TERMUX_PKG=true
  [ "$arg" = "--skip-udocker" ] && SKIP_UDOCKER=true
done

echo -e "${CYAN}${BOLD}"
echo " ╔══════════════════════════════════════════════════════╗"
echo " ║  ⚡ roc-containers · Setup v${VERSION}                ║"
echo " ║  Mode: ${ENV_MODE}                                       ║"
echo " ║  AI Agent CLI + App Manager (native)                ║"
echo " ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── 1. Clone repo jika belum ada ──────────────────────
if [ ! -d "$ROC_DIR" ]; then
    echo -e "${YELLOW}[1/5] Cloning roc-containers...${RESET}"
    if [ "$ENV_MODE" = "codespace" ] || [ "$ENV_MODE" = "cloud-shell" ]; then
        # In Codespace, workspace is already the repo
        if [ -d "/workspaces/roc-containers" ]; then
            ln -sf /workspaces/roc-containers "$ROC_DIR"
        else
            git clone --depth 1 https://github.com/ivansslo/roc-containers "$ROC_DIR"
        fi
    else
        pkg install git -y 2>/dev/null || true
        git clone --depth 1 https://github.com/ivansslo/roc-containers "$ROC_DIR"
    fi
else
    echo -e "${GREEN}[1/5] roc-containers sudah ada, updating...${RESET}"
    git -C "$ROC_DIR" pull --ff-only 2>/dev/null || true
fi

# ─── 2. Install dependencies ──────────────────────────
echo -e "\n${YELLOW}[2/5] Installing dependencies...${RESET}"
if [ "$SKIP_TERMUX_PKG" = true ]; then
    echo -e "  ${DIM}Skipping Termux packages (running in ${ENV_MODE})${RESET}"
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y -qq git curl jq postgresql-client 2>/dev/null || true
else
    pkg install -y git curl 2>/dev/null || true
fi

# Install udocker
if [ "$SKIP_UDOCKER" = false ]; then
    if ! command -v udocker &>/dev/null; then
        echo -e "  ${DIM}Installing udocker...${RESET}"
        bash "$ROC_DIR/install_udocker.sh"
    fi
else
    echo -e "  ${DIM}Skipping udocker (not needed in ${ENV_MODE})${RESET}"
fi

# ─── 3. Clone roc-agentsroute (CLI utama) ─────────────
echo -e "\n${YELLOW}[3/5] Setting up roc-agent CLI...${RESET}"
AGENT_DIR="$ROC_DIR/apps/roc-agent"
if [ -d "$AGENT_DIR/.git" ]; then
    git -C "$AGENT_DIR" pull --ff-only 2>/dev/null || true
elif [ -f "$AGENT_DIR/hermes" ]; then
    echo -e "  ${GREEN}✅ hermes CLI ter-bundle (versi lokal)${RESET}"
else
    # Dir kosong/hilang → coba clone; repo bisa privat → fallback bundle bawaan gagal total hanya bila file tak ada
    git clone --depth 1 https://github.com/ivansslo/roc-agentsroute "$AGENT_DIR" 2>/dev/null || \
        echo -e "  ${YELLOW}⚠ Clone roc-agentsroute gagal (repo privat/offline) — pakai bundle bawaan jika ada${RESET}"
fi

# ─── 4. Install Python venv untuk roc-agent ───────────
echo -e "\n${YELLOW}[4/5] Setting up Python venv...${RESET}"
if command -v python3 &>/dev/null; then
    mkdir -p "$HOME/.hermes"
    if [ ! -x "$HOME/.hermes/python3_venv/bin/python" ]; then
        if [ "$SKIP_TERMUX_PKG" = false ]; then
            pkg install -y python 2>/dev/null || true
        else
            sudo apt-get install -y -qq python3 python3-venv python3-pip 2>/dev/null || true
        fi
        python3 -m venv "$HOME/.hermes/python3_venv" 2>/dev/null || true
        if [ -x "$HOME/.hermes/python3_venv/bin/python" ]; then
            "$HOME/.hermes/python3_venv/bin/python" -m pip install -U pip rich pygments prompt_toolkit requests >/dev/null 2>&1 || true
            echo -e "  ${GREEN}✅ Python venv ready${RESET}"
        fi
    else
        echo -e "  ${GREEN}✅ Python venv already exists${RESET}"
    fi
else
    if [ "$SKIP_TERMUX_PKG" = false ]; then
        pkg install -y python 2>/dev/null || true
    else
        sudo apt-get install -y -qq python3 python3-venv 2>/dev/null || true
    fi
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

    # Use different shebang based on environment
    local shebang="#!/data/data/com.termux/files/usr/bin/bash"
    [ "$ENV_MODE" != "termux" ] && shebang="#!/usr/bin/env bash"

    cat > "$BIN_DIR/$cmd_name" << EOF
$shebang
# $cmd_name — $description
exec bash "$ROC_DIR/$script_path" "\$@"
EOF
    chmod +x "$BIN_DIR/$cmd_name"
    printf "  ${GREEN}✅${RESET} %-20s %s\n" "$cmd_name" "$description"
}

# ── ROC-AGENT: wrapper khusus (cross-platform) ──
AGENT_SHEBANG="#!/data/data/com.termux/files/usr/bin/bash"
[ "$ENV_MODE" != "termux" ] && AGENT_SHEBANG="#!/usr/bin/env bash"

cat > "$BIN_DIR/roc-agent" << AGENT_WRAPPER
$AGENT_SHEBANG
# roc-agent — AI Agent CLI (roc-agentsroute)
# Environment: ${ENV_MODE}

ROC_DIR="\$HOME/.roc-containers"
AGENT_DIR="\$ROC_DIR/apps/roc-agent"
HERMES_BIN="\$AGENT_DIR/hermes"

if [ ! -f "\$HERMES_BIN" ]; then
    echo "❌ roc-agent CLI tidak ditemukan: \$HERMES_BIN"
    echo "   Jalankan: bash \$ROC_DIR/setup.sh"
    exit 1
fi

# Load keys
[ -f "\$HOME/.hermes_keys" ] && source "\$HOME/.hermes_keys" 2>/dev/null
if [ -f "\$HOME/.hermes/.keys" ]; then
    while IFS='=' read -r key val; do
        [[ "\$key" =~ ^#.*\$ || -z "\$key" ]] && continue
        # Skip invalid variable names (e.g. ₣IREBASE_API_KEY with Unicode chars)
        [[ ! "\$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\$ ]] && continue
        val="\${val%\\"}" ; val="\${val#\\"}" ; val="\${val%\\'}" ; val="\${val#\\'}"
        [ -z "\${!key:-}" ] && export "\$key=\$val"
    done < "\$HOME/.hermes/.keys"
fi

exec bash "\$HERMES_BIN" "\$@"
AGENT_WRAPPER
chmod +x "$BIN_DIR/roc-agent"
printf "  ${GREEN}✅${RESET} %-20s %s\n" "roc-agent" "AI Agent CLI (Termux native)"

# ── ROC-VM: Oracle VM / WebVirtCloud (alias: webvirtcloud.ai.studio) ──
cat > "$BIN_DIR/roc-vm" << VM_WRAPPER
$AGENT_SHEBANG
# roc-vm — 🖥️ Oracle VM · WebVirtCloud (alias: webvirtcloud.ai.studio)
# Delegate ke hermes v5.12.0+ "Oracle":  roc-vm <status|console|wvc|kuma|monitor|novnc|ssh|tailscale|services|studio>

ROC_DIR="\$HOME/.roc-containers"
HERMES_BIN="\$ROC_DIR/apps/roc-agent/hermes"

if [ ! -f "\$HERMES_BIN" ]; then
    echo "❌ hermes CLI tidak ditemukan: \$HERMES_BIN"
    echo "   Jalankan: bash \$ROC_DIR/setup.sh"
    exit 1
fi

# Load keys (opsional — VM_IP/TAILSCALE bisa dioverride via env)
[ -f "\$HOME/.hermes_keys" ] && source "\$HOME/.hermes_keys" 2>/dev/null

exec bash "\$HERMES_BIN" vm "\$@"
VM_WRAPPER
chmod +x "$BIN_DIR/roc-vm"
printf "  ${GREEN}✅${RESET} %-20s %s\n" "roc-vm" "🖥️ Oracle VM · WebVirtCloud (webvirtcloud.ai.studio)"

# ── ⭐ AI Stack (Primary) ──
make_cmd "roc-ai"          "apps/ai/ai.sh"              "⭐ RoadFX AI Stack (ivansslo/roadfx-ai-stack)"

# ── Native Apps (v1.5.0+: semua command container DIHAPUS) ──
make_cmd "roc-hermui"      "apps/hermui/hermui.sh"      "Hermes UI (dashboard bundel)"
make_cmd "roc-spwr"        "apps/spwr/spwr.sh"          "Superpowers (coding agent skills)"
make_cmd "roc-clawdex"     "apps/clawdex/clawdex.sh"    "Clawdex Mobile (ivansslo/clawdex-mobile)"
make_cmd "roc-maagba"      "apps/maagba/maagba.sh"      "Multi-Agent Architectural Guidance (Bedrock AgentCore)"

# ── Google Cloud ──
make_cmd "roc-gcp"         "lib/google_project.sh"        "Google Project (GCP)"

# ── System ──
make_cmd "roc-menu"        "menu.sh"                      "roc-containers menu"
make_cmd "roc-status"      "lib/manager.sh"               "Container status (udocker minimal)"
make_cmd "roc-sysinfo"     "lib/sysinfo.sh"               "System info"
make_cmd "roc-update"      "lib/update.sh"                "Update roc-containers"
make_cmd "roc-uninstall"   "lib/uninstall.sh"             "Uninstall / clean"
make_cmd "roc-udocker"     "install_udocker.sh"           "Reinstall udocker"
make_cmd "roc-remote"      "lib/remote-connect.sh"        "🌐 Remote dev connect (Codespaces/CloudShell/Oracle/Aiven)"

# ── Auto-cleanup wrapper USANG (v1.5.0 menghapus semua command container) ──
# Wrapper lama v1.4.x ke bawah masih tertinggal di $BIN_DIR setelah update.
# Daftar ini = make_cmd yang DIHAPUS antara v1.4.0 → v1.5.0.
echo -e "  ${DIM}Membersihkan wrapper usang...${RESET}"
STALE_CMDS=(roc-ubuntu roc-debian roc-httpd roc-tailscale roc-hms roc-crewai roc-adk roc-antigravity)
_removed=0
for _sc in "${STALE_CMDS[@]}"; do
    if [ -f "$BIN_DIR/$_sc" ]; then
        rm -f "$BIN_DIR/$_sc"
        printf "  ${YELLOW}🧹${RESET} %-20s %s\n" "$_sc" "wrapper usang dihapus"
        _removed=$((_removed+1))
    fi
done
[ "$_removed" -eq 0 ] && echo -e "  ${DIM}🧹 Tidak ada wrapper usang — bersih${RESET}"

# ════════════════════════════════════════════════════════
#  Verifikasi
# ════════════════════════════════════════════════════════
echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD} ✅ roc-containers v${VERSION} ter-install!${RESET}"
echo -e "${DIM}   Mode: ${ENV_MODE} | Bin: ${BIN_DIR}${RESET}\n"

echo -e " ${BOLD}Quick Start:${RESET}"
echo -e "  ${CYAN}roc-agent setup${RESET}         Setup API keys"
echo -e "  ${CYAN}roc-agent chat${RESET}          Chat dengan AI"
echo -e "  ${CYAN}roc-agent ask 'halo'${RESET}     Quick question"
echo -e "  ${CYAN}roc-agent import${RESET}        Export agent for AI Studio / AIS-DEV"
echo -e "  ${CYAN}roc-ai orchestrator <t>${RESET} 🧠 Autonomous Orchestrator (Planner→… + Grounding)"
echo -e "  ${CYAN}roc-vm status${RESET}           🖥️ Oracle VM status (alias: webvirtcloud.ai.studio)"
echo -e "  ${CYAN}roc-remote${RESET}              🌐 Connect ke remote dev"
echo -e "  ${CYAN}roc-menu${RESET}                Menu utama"
echo -e "  ${CYAN}roc-status${RESET}              Cek container status"
echo ""
echo -e " ${DIM}Semua command ada di $BIN_DIR/${RESET}"
echo -e " ${DIM}Data ada di $ROC_DIR/${RESET}"
