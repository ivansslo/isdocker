#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  v1.5.3 — NATIVE ONLY + Oracle VM + label panel antigravity.ai.studio.
#  Sebelumnya: semua command berbasis container
#  (udocker) telah dihapus; wrapper usang otomatis dibersihkan setup.sh.
#  Menjalankan container kini manual via udocker:
#      udocker run <nama-container>
#  Integrasi Oracle VM (alias: webvirtcloud.ai.studio) via roc-vm.
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
  echo "  ║       roc-containers · AI Agent CLI (native)         ║"
  echo "  ║               v1.6.0 (c) 2026 | @ivansslo            ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}OS: $(uname -m)${RESET}"
}

print_section(){
  echo -e "\n${YELLOW}${BOLD}  ── $1 ──${RESET}"
}

print_item(){
  local num="$1" label="$2" note="$3" cat="$4"
  local color="${CYAN}"
  [ "$cat" = "ai" ]  && color="${MAGENTA}"
  [ "$cat" = "app" ] && color="${BLUE}"
  [ "$cat" = "sys" ] && color="${DIM}"
  printf "  ${color}${BOLD}[%2s]${RESET}  %-30s" "$num" "$label"
  [ -n "$note" ] && echo -e "${DIM}→ $note${RESET}" || echo ""
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
  print_item  03  "🚀 roc-ai Orchestrator"        "roc-ai orchestrator" "ai"

  # ── 🤖 AI & Agent ──
  print_section "🤖  AI & Agent"
  print_item  04  "AI Agent CLI"                  "roc-agent" "ai"
  print_item  05  "MAAGBA (Bedrock AgentCore)"    "roc-maagba" "ai"

  # ── 📦 Apps (native) ──
  print_section "📦  Apps"
  print_item  06  "Superpowers (agent skills)"    "roc-spwr"   "app"
  print_item  07  "Hermes UI (dashboard)"         "roc-hermui" "app"
  print_item  08  "Clawdex Mobile"                "roc-clawdex" "app"

  # ── ⚙️ System ──
  print_section "⚙️  System"
  print_item  09  "Container Status (udocker)"    "run manual: udocker run <nama>"  "sys"
  print_item  10  "Google Cloud (GCP)"            ""  "sys"
  print_item  11  "System Info (RAM/CPU)"         ""  "sys"
  print_item  12  "Update roc-containers"         ""  "sys"
  print_item  13  "Uninstall / Clean"             ""  "sys"
  print_item  14  "Install/Repair udocker"        ""  "sys"
  print_item 15  "Remote Dev Connect"            "codespaces/oracle/aiven" "sys"

  # ── 🖥️ Oracle VM (webvirtcloud.ai.studio) ──
  print_section "🖥️  Oracle VM  (alias: webvirtcloud.ai.studio)"
  print_item 16  "VM Status & Health"            "roc-vm status" "app"
  print_item 17  "Buka VM Console"               "vm.roadfx.biz.id/vm" "app"
  print_item 18  "Layanan di VM"                 "roc-vm services" "app"

  # ── 🧠 Antigravity IDE (antigravity.ai.studio) ──
  print_section "🧠  Antigravity IDE  (alias: antigravity.ai.studio)"
  print_item 19  "Antigravity Status"            "hermes antigravity status" "app"
  print_item 20  "Web UI (node HP)"              "localhost:5905" "app"
  print_item 21  "Node Oracle VM (noVNC :6905)"  "pending install di VM" "app"

  # ── 🌐 Cloudflare Tunnel (ag.roadfx.biz.id) ──
  print_section "🌐  Cloudflare Tunnel  (ag.roadfx.biz.id → node HP)"
  print_item 22  "Tunnel Setup & Status"         "roc-tunnel (install→login→create→up-bg)" "app"

  # ── 🔑 Akses VM: SSH/VNC/RDP (webvirtcloud.ai.studio) ──
  print_section "🔑  Akses VM  (SSH · VNC · RDP — webvirtcloud.ai.studio)"
  print_item 23  "Setup & Status Akses"          "roc-access setup / status" "app"
  print_item 24  "SSH masuk VM"                  "roc-access ssh" "app"
  print_item 25  "VNC / noVNC"                   "roc-access vnc" "app"
  print_item 26  "RDP (xrdp)"                    "roc-access rdp" "app"

  # ── 📚 Bantuan keseluruhan ──
  print_section "📚  Bantuan  (help keseluruhan ekosistem)"
  print_item 27  "roc-help"                      "help semua command + panduan OCI/Rofwin" "app"
  print_item 00  "Exit"                          ""  "sys"

  echo ""
  echo -en "  ${BOLD}Select option [00-27]: ${RESET}"
  read -r choice

  case "$choice" in
    # ── ⭐ AI Stack ──
    1|01) run_script "$SCRIPT_DIR/apps/ai/ai.sh" ;;
    2|02) run_script "$SCRIPT_DIR/apps/ai/ai.sh" mesh ;;
    3|03)
      if command -v roc-ai &>/dev/null; then roc-ai orchestrator
      else bash "$SCRIPT_DIR/apps/ai/ai.sh" orchestrator; fi
      ;;

    # ── 🤖 AI & Agent ──
    4|04)
      if command -v roc-agent &>/dev/null; then roc-agent "${@:-}"
      elif [ -n "${PREFIX:-}" ] && [ -f "$PREFIX/bin/roc-agent" ]; then bash "$PREFIX/bin/roc-agent" "${@:-}"
      elif [ -f "$SCRIPT_DIR/apps/roc-agent/hermes" ]; then bash "$SCRIPT_DIR/apps/roc-agent/hermes" "${@:-}"
      else echo -e "  ${RED}roc-agent belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      ;;
    5|05) run_script "$SCRIPT_DIR/apps/maagba/maagba.sh" ;;

    # ── 📦 Apps ──
    6|06) run_script "$SCRIPT_DIR/apps/spwr/spwr.sh" ;;
    7|07) run_script "$SCRIPT_DIR/apps/hermui/hermui.sh" ;;
    8|08) run_script "$SCRIPT_DIR/apps/clawdex/clawdex.sh" ;;

    # ── ⚙️ System ──
    9|09)  ensure_udocker; run_script "$SCRIPT_DIR/lib/manager.sh" ;;
    10)    run_script "$SCRIPT_DIR/lib/google_project.sh" ;;
    11)    run_script "$SCRIPT_DIR/lib/sysinfo.sh" ;;
    12)    run_script "$SCRIPT_DIR/lib/update.sh" ;;
    13)    run_script "$SCRIPT_DIR/lib/uninstall.sh" ;;
    14)    run_script "$SCRIPT_DIR/install_udocker.sh" ;;
    15)    run_script "$SCRIPT_DIR/lib/remote-connect.sh" ;;

    # ── 🖥️ Oracle VM (webvirtcloud.ai.studio) ──
    16|17|18)
      _vm_arg="status"; [ "$choice" = "17" ] && _vm_arg="console"; [ "$choice" = "18" ] && _vm_arg="services"
      if command -v roc-vm &>/dev/null; then bash "$(command -v roc-vm)" "$_vm_arg"
      elif [ -n "${PREFIX:-}" ] && [ -f "$PREFIX/bin/roc-vm" ]; then bash "$PREFIX/bin/roc-vm" "$_vm_arg"
      elif [ -f "$SCRIPT_DIR/apps/roc-agent/hermes" ]; then bash "$SCRIPT_DIR/apps/roc-agent/hermes" vm "$_vm_arg"
      else echo -e "  ${RED}roc-vm belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      ;;

    # ── 🧠 Antigravity IDE (antigravity.ai.studio) ──
    19)
      if command -v hermes &>/dev/null; then hermes antigravity status
      elif [ -f "$SCRIPT_DIR/apps/roc-agent/hermes" ]; then bash "$SCRIPT_DIR/apps/roc-agent/hermes" antigravity status
      else echo -e "  ${RED}hermes belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      ;;
    20)
      _ag_url="http://localhost:5905"
      echo -e "  ${CYAN:-}🧠 Antigravity Web (node HP): $_ag_url${RESET:-}"
      if command -v termux-open-url &>/dev/null; then termux-open-url "$_ag_url"
      elif command -v am &>/dev/null; then am start -a android.intent.action.VIEW -d "$_ag_url" 2>/dev/null || true
      else echo "  Buka manual di browser: $_ag_url"; fi
      sleep 2
      ;;
    21)
      echo -e "  ${CYAN:-}🧠 Antigravity node Oracle VM (alias: antigravity.ai.studio)${RESET:-}"
      echo "     noVNC : http://161.118.253.28:6905/vnc.html"
      echo -e "     ${YELLOW:-}Status: pending — install di VM belum dijalankan (menunggu akses SSH/OCI Run Command).${RESET:-}"
      sleep 3
      ;;

    # ── 🌐 Cloudflare Tunnel (ag.roadfx.biz.id) ──
    22)
      if command -v roc-tunnel &>/dev/null; then roc-tunnel status
      elif [ -f "$SCRIPT_DIR/lib/tunnel.sh" ]; then bash "$SCRIPT_DIR/lib/tunnel.sh" status
      else echo -e "  ${RED}roc-tunnel belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      echo ""
      echo -e "  ${DIM}Alur sekali: roc-tunnel install → login → create → up-bg${RESET}"
      echo -e "  ${DIM}Lalu buka https://ag.roadfx.biz.id${RESET}"
      sleep 4
      ;;

    # ── 🔑 Akses VM: SSH/VNC/RDP (webvirtcloud.ai.studio) ──
    23|24|25|26)
      _acc_arg="status"; [ "$choice" = "24" ] && _acc_arg="ssh"; [ "$choice" = "25" ] && _acc_arg="vnc url"; [ "$choice" = "26" ] && _acc_arg="rdp url"
      [ "$choice" = "23" ] && _acc_arg="status"
      if command -v roc-access &>/dev/null; then roc-access $_acc_arg
      elif [ -f "$SCRIPT_DIR/lib/vmaccess.sh" ]; then bash "$SCRIPT_DIR/lib/vmaccess.sh" $_acc_arg
      else echo -e "  ${RED}roc-access belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      [ "$choice" = "23" ] && { echo -e "  ${DIM}Wizard pertama kali: roc-access setup${RESET}"; sleep 2; }
      ;;

    # ── 📚 Bantuan keseluruhan ──
    27)
      if command -v roc-help &>/dev/null; then roc-help
      elif [ -f "$SCRIPT_DIR/lib/rochelp.sh" ]; then bash "$SCRIPT_DIR/lib/rochelp.sh"
      else echo -e "  ${RED}roc-help belum terinstall — jalankan: bash setup.sh${RESET}"; sleep 2; fi
      ;;

    0|00|q|Q|exit) echo -e "\n  Goodbye.\n" ; exit 0 ;;
    *) echo -e "\n  Invalid option." ; sleep 1 ;;
  esac

  echo -e "\n  ${DIM}Press Enter to return...${RESET}"
  read -r
done
