#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  lsmod v2.0.0 — Module System (NATIVE REFRESH)
#  ivansslo/lsmod
#
#  Semua integrasi containers DIHAPUS (v1.5.0):
#    ✗ lsmod_propagate → container data/rootfs
#    ✗ udocker inspect di mesh
#  Sekarang murni native: agent/chat/code/error/route/broadcast/
#  orchestrate/mesh — didelegasikan ke roc-agent (hermes CLI).
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/lsmod_loader.sh" 2>/dev/null || true
[ -f "$HOME/.config/hermes/solace.env" ] && source "$HOME/.config/hermes/solace.env" 2>/dev/null

LSMOD_DIR="$HOME/.roc-containers/apps/ai/modules/lsmod"
LSMOD_REPO="https://github.com/ivansslo/lsmod"
LSMOD_DATA_DIR="$HOME/.roc-containers/data-lsmod"

# ──────────────────────────────────────────────────────────────
#  lsmod Install — setup modul (TANPA propagasi ke containers)
# ──────────────────────────────────────────────────────────────
lsmod_install() {
  lsmod_ensure || true   # repo opsional; mode bawaan tetap jalan

  echo -e "${YELLOW}[*] Setting up lsmod module system (native)...${RESET}"

  # Termux deps (opsional)
  if [ -d /data/data/com.termux ]; then
    echo -e "${DIM}[*] Installing Termux deps (nodejs)...${RESET}"
    pkg install -y nodejs 2>/dev/null || true
  fi

  # Sanitize hardcoded keys (security) bila repo ada
  if [ -f "$LSMOD_DIR/config/keys.json" ]; then
    echo '{}' > "$LSMOD_DIR/config/keys.json"
    echo -e "${GREEN}[✓] Hardcoded keys removed${RESET}"
  fi

  mkdir -p "$LSMOD_DATA_DIR"
  echo -e "${GREEN}[✓] lsmod module system ready (native — no containers)${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Orchestrate — koordinasi multi-agent NATIVE
# ──────────────────────────────────────────────────────────────
lsmod_orchestrate() {
  lsmod_load_keys
  local task="$1"

  if [ -z "$task" ]; then
    echo -e "${YELLOW}[lsmod] Usage: roc-ai orchestrate <task>${RESET}"
    return 1
  fi

  echo -e "${MAGENTA}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  🎼 lsmod — Orchestration Mode (native)             ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${BOLD}Task:${RESET} $task\n"

  # Phase 1: Analyze
  echo -e "  ${CYAN}[1/3] Analyzing task...${RESET}"
  local analysis="general"
  if command -v roc-agent &>/dev/null; then
    analysis=$(roc-agent ask "Categorize this task and suggest which agent should handle it. Task: $task. Available: roc-agent (general AI), lsmod code (coding), lsmod error (debug), maagba (architecture). Reply one word." 2>/dev/null || echo "general")
  fi
  echo -e "  ${DIM}Analysis: $analysis${RESET}\n"

  # Phase 2: Route (native registry)
  echo -e "  ${CYAN}[2/3] Routing (native registry)...${RESET}"
  local routed=0
  entry_has() { for e in "${LSMOD_REGISTRY[@]}"; do [ "${e%%|*}" = "$1" ] && return 0; done; return 1; }
  case "$analysis" in
    *code*|*debug*|*script*)
      entry_has code && { echo -e "  ${GREEN}●${RESET} lsmod code → coding"; routed=$((routed + 1)); } ;;
    *error*|*fix*|*bug*)
      entry_has error && { echo -e "  ${GREEN}●${RESET} lsmod error → debug"; routed=$((routed + 1)); } ;;
    *architect*|*design*|*maagba*)
      [ -d "$ROC_DIR/apps/maagba" ] && { echo -e "  ${GREEN}●${RESET} maagba → architecture"; routed=$((routed + 1)); } ;;
  esac
  command -v roc-agent &>/dev/null && { echo -e "  ${GREEN}●${RESET} roc-agent → primary handler"; routed=$((routed + 1)); }
  echo -e "\n  ${DIM}Routed to $routed handler(s)${RESET}\n"

  # Phase 3: Execute
  echo -e "  ${CYAN}[3/3] Executing...${RESET}"
  lsmod_agent "$task"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Native — jalankan lasokamodule.js bila repo tersedia
# ──────────────────────────────────────────────────────────────
lsmod_native() {
  lsmod_ensure || return 1
  if [ -f "$LSMOD_DIR/termux/lasokamodule.js" ] && command -v node &>/dev/null; then
    cd "$LSMOD_DIR" && exec node termux/lasokamodule.js "$@"
  else
    echo -e "${RED}[✗] lsmod native membutuhkan repo lsmod + Node.js${RESET}"
    return 1
  fi
}

# ──────────────────────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────────────────────
lsmod_main() {
  local cmd="${1:-}"
  shift 2>/dev/null || true

  if [ -z "$cmd" ]; then
    echo -e "${MAGENTA}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  lsmod v2.0.0 — Module System (NATIVE)              ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}${MAGENTA}lsmod Modes:${RESET}"
    echo -e "  ${CYAN}agent <task>${RESET}      🤖 Agent Mode"
    echo -e "  ${CYAN}chat${RESET}              💬 Chat Mode (interactive)"
    echo -e "  ${CYAN}code <task>${RESET}       💻 Coding Mode"
    echo -e "  ${CYAN}error <msg>${RESET}       🐛 Error Handler / Fix"
    echo ""
    echo -e " ${BOLD}${CYAN}Routing:${RESET}"
    echo -e "  ${CYAN}route <task>${RESET}      🧭 Auto-route ke modul terbaik"
    echo -e "  ${CYAN}broadcast <msg>${RESET}   📢 Broadcast ke registry"
    echo -e "  ${CYAN}orchestrate <t>${RESET}   🎼 Koordinasi multi-agent native"
    echo -e "  ${CYAN}mesh${RESET}              🕸️  Native service mesh"
    echo ""
    echo -e " ${BOLD}Management:${RESET}"
    echo -e "  ${CYAN}registry${RESET}          Daftar modul (native)"
    echo -e "  ${CYAN}install${RESET}           Setup modul (tanpa containers)"
    echo -e "  ${CYAN}status${RESET}            Status modul & keys"
    echo -e "  ${CYAN}native${RESET}            lasokamodule.js (bila repo ada)"
    echo ""
    echo -e " ${DIM}v1.5.0: integrasi containers DIHAPUS — murni native.${RESET}"
    return 0
  fi

  case "$cmd" in
    agent|a)        lsmod_agent "$@" ;;
    chat|c)         lsmod_chat "$@" ;;
    code|coding|co) lsmod_code "$@" ;;
    error|err|e|fix) lsmod_error "$@" ;;
    route|r)        lsmod_route "$@" ;;
    broadcast|bcast|b) lsmod_broadcast "$@" ;;
    orchestrate|orch|o) lsmod_orchestrate "$@" ;;
    mesh)           lsmod_mesh ;;
    registry|reg)   lsmod_registry ;;
    install|setup|i) lsmod_install ;;
    status|st|ps)   lsmod_status ;;
    native|lsmod|l) lsmod_native "$@" ;;
    update|up|pull)
      if [ -d "$LSMOD_DIR/.git" ]; then
        git -C "$LSMOD_DIR" pull --ff-only 2>/dev/null || true
        [ -f "$LSMOD_DIR/config/keys.json" ] && echo '{}' > "$LSMOD_DIR/config/keys.json"
        echo -e "${GREEN}[✓] Updated${RESET}"
      else
        lsmod_ensure || true
      fi
      ;;
    *)
      echo -e "${RED}Unknown command: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-ai${RESET} for usage"
      ;;
  esac
}

lsmod_main "$@"
