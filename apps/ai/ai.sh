#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · RoadFX AI Stack (roc-ai) ⭐ PRIMARY
#  Clone: ivansslo/roadfx-ai-stack
#  Module: ivansslo/lsmod (Agent/Chat/Coding/Error)
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true
[ -f "$HOME/.config/hermes/solace.env" ] && source "$HOME/.config/hermes/solace.env" 2>/dev/null

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

AI_DIR="$HOME/.roc-containers/apps/ai/roadfx-ai-stack"
AI_REPO="https://github.com/ivansslo/roadfx-ai-stack"
AI_DATA_DIR="$HOME/.roc-containers/data-roadfx-ai"
LSMOD_SH="$(dirname "${BASH_SOURCE[0]}")/lsmod.sh"

# Core Functions (abbreviated for brevity, but keep full logic)
ai_ensure() {
  if [ ! -d "$AI_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning RoadFX AI Stack...${RESET}"
    git clone --depth 1 "$AI_REPO" "$AI_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${RED}[✗] Gagal clone repo.${RESET}"
      exit 1
    fi
    echo -e "${GREEN}[✓] RoadFX AI Stack berhasil di-clone${RESET}"
  else
    echo -e "${DIM}[*] Checking for updates...${RESET}"
    git -C "$AI_DIR" pull --ff-only 2>/dev/null || true
  fi
  mkdir -p "$AI_DATA_DIR"
}

ai_install() {
  ai_ensure
  echo -e "${YELLOW}[*] Setting up RoadFX AI Stack...${RESET}"
  if [ -f "$LSMOD_SH" ]; then
    bash "$LSMOD_SH" install
  fi
  echo -e "${GREEN}[✓] RoadFX AI Stack setup selesai${RESET}"
}

ai_status() {
  echo -e "${CYAN}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  ⭐ RoadFX AI Stack — Full Status                   ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  if [ -d "$AI_DIR/.git" ]; then
    echo -e "  ${BOLD}roadfx-ai-stack:${RESET}  ${GREEN}✓ installed${RESET}"
  else
    echo -e "  ${BOLD}roadfx-ai-stack:${RESET}  ${RED}✗ not cloned${RESET}"
  fi
  echo -e "\n  ${BOLD}${MAGENTA}── lsmod Modules ──${RESET}"
  if [ -f "$LSMOD_SH" ]; then bash "$LSMOD_SH" status 2>/dev/null; fi
}

ai_main() {
  local cmd="${1:-}"

  if [ -z "$cmd" ]; then
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  ⭐ RoadFX AI Stack — roc-ai                       ║"
    echo " ║  ivansslo/roadfx-ai-stack                           ║"
    echo " ║  Module: ivansslo/lsmod                             ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${BOLD}⭐ Primary AI service — always updated${RESET}\n"

    echo -e " ${BOLD}${MAGENTA}lsmod v2 Modes (native):${RESET}"
    echo -e "  ${CYAN}roc-ai agent <task>${RESET}  🤖 Agent Mode"
    echo -e "  ${CYAN}roc-ai chat${RESET}          💬 Chat Mode"
    echo -e "  ${CYAN}roc-ai code <task>${RESET}   💻 Coding Mode"
    echo -e "  ${CYAN}roc-ai error <msg>${RESET}   🐛 Error Handler"
    echo ""
    echo -e " ${BOLD}${CYAN}⭐ Routing & Koordinasi:${RESET}"
    echo -e "  ${CYAN}roc-ai route <task>${RESET}    🧭 Auto-route modul"
    echo -e "  ${CYAN}roc-ai broadcast <m>${RESET}  📢 Broadcast registry"
    echo -e "  ${CYAN}roc-ai orchestrate <t>${RESET} 🎼 Orchestrate"
    echo -e "  ${CYAN}roc-ai mesh${RESET}            🕸️  Native Service Mesh"
    echo ""
    echo -e " ${BOLD}${BLUE}Management:${RESET}"
    echo -e "  ${CYAN}roc-ai install${RESET}      Install stack + lsmod (tanpa containers)"
    echo -e "  ${CYAN}roc-ai status${RESET}       Check services"
    echo ""
    echo -e " ${BOLD}${MAGENTA}🧠 Autonomous Orchestrator (NEW):${RESET}"
    echo -e "  ${CYAN}roc-ai orchestrator <task>${RESET}   Planner→... + Grounding"
    echo -e "  ${DIM}AIS_DEV (gemini-2.5-flash) + Gateway first-class • Auto import${RESET}"
    echo -e "  ${CYAN}roc-ai import${RESET}              Export for AI Studio"
    echo ""
    return 0
  fi

  case "$cmd" in
    agent|a)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" agent "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    chat|c)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" chat "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    code|coding|co)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" code "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    error|err|e|fix)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" error "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    orchestrate)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" orchestrate "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    route|r)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" route "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    broadcast|bcast|b)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" broadcast "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;
    registry|reg)
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" registry || echo -e "${RED}lsmod not found${RESET}"
      ;;
    mesh)
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" mesh || echo -e "${RED}lsmod not found${RESET}"
      ;;
    native|lsmod|l)
      shift
      [ -f "$LSMOD_SH" ] && bash "$LSMOD_SH" native "$@" || echo -e "${RED}lsmod not found${RESET}"
      ;;

    # FIRST-CLASS: roc-ai orchestrator (alias: orch/o)
    orchestrator|orch|o)
      shift
      echo -e "${MAGENTA}${BOLD}🧠 roc-ai orchestrator — Autonomous Orchestrator${RESET}"
      echo -e "${DIM}Planner→Researcher→Coder→Reviewer→Tester + Grounding | AIS_DEV + Gateway${RESET}"
      if command -v roc-agent &>/dev/null; then
        exec roc-agent orchestrator "$@"
      elif [ -f "$HOME/.roc-containers/apps/roc-agent/hermes" ]; then
        bash "$HOME/.roc-containers/apps/roc-agent/hermes" orchestrator "$@"
      elif command -v hermes &>/dev/null; then
        hermes orchestrator "$@"
      else
        echo -e "${YELLOW}roc-agent/hermes not found. Run roc-containers setup${RESET}"
      fi
      ;;

    import|ais-import)
      shift
      echo -e "${CYAN}Delegating to hermes import...${RESET}"
      if command -v roc-agent &>/dev/null; then
        exec roc-agent import "$@"
      elif [ -f "$HOME/.roc-containers/apps/roc-agent/hermes" ]; then
        bash "$HOME/.roc-containers/apps/roc-agent/hermes" import "$@"
      else
        echo "Use: roc-agent import"
      fi
      ;;

    install|setup|i) ai_install ;;
    status|st|ps) ai_status ;;
    docs|readme|help|h) echo "See full docs in README.md" ;;
    update|up|pull) echo "Use roc-containers update" ;;
    *)
      echo -e "${RED}Unknown: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-ai${RESET} for usage"
      ;;
  esac
}

ai_main "$@"
