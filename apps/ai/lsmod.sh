#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  lsmod — Module System for roc-ai ⭐ PEWARIS
#  ivansslo/lsmod
#
#  lsmod menyebar ke semua AI & Agent containers via:
#    - lib/lsmod_loader.sh (shared loader, di-source oleh semua roc-*)
#    - lsmod_propagate() (inject ke container data dirs)
#    - lsmod_route() (routing ke agent yang tepat)
#    - lsmod_broadcast() (pesan ke semua agents)
#
#  roc-ai adalah PEWARIS lsmod — fitur istimewa:
#    - Orchestration semua AI agents
#    - Container-aware routing
#    - Cross-agent communication
#    - Service mesh untuk AI & Agent containers
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/lsmod_loader.sh" 2>/dev/null || true

LSMOD_DIR="$HOME/.roc-containers/apps/ai/modules/lsmod"
LSMOD_REPO="https://github.com/ivansslo/lsmod"
LSMOD_DATA_DIR="$HOME/.roc-containers/data-lsmod"

# ──────────────────────────────────────────────────────────────
#  lsmod Install — setup + propagate ke semua containers
# ──────────────────────────────────────────────────────────────
lsmod_install() {
  lsmod_ensure

  echo -e "${YELLOW}[*] Setting up lsmod module system...${RESET}"

  # Termux deps
  if [ -d /data/data/com.termux ]; then
    echo -e "${DIM}[*] Installing Termux dependencies...${RESET}"
    pkg install -y nodejs p7zip 2>/dev/null || true
  fi

  # Make scripts executable
  [ -f "$LSMOD_DIR/termux/lasokamodule.js" ] && chmod +x "$LSMOD_DIR/termux/lasokamodule.js"
  [ -f "$LSMOD_DIR/termux/setup.sh" ] && chmod +x "$LSMOD_DIR/termux/setup.sh"
  [ -f "$LSMOD_DIR/termux/install.sh" ] && chmod +x "$LSMOD_DIR/termux/install.sh"

  # Sanitize hardcoded keys (security)
  if [ -f "$LSMOD_DIR/config/keys.json" ]; then
    echo -e "${YELLOW}[*] Sanitizing hardcoded keys...${RESET}"
    echo '{}' > "$LSMOD_DIR/config/keys.json"
    echo -e "${GREEN}[✓] Hardcoded keys removed${RESET}"
  fi

  # Install lasokamodule command
  if [ -f "$LSMOD_DIR/termux/lasokamodule.js" ] && command -v node &>/dev/null; then
    local bin_dir="${PREFIX:-$HOME/.local}/bin"
    cp "$LSMOD_DIR/termux/lasokamodule.js" "$bin_dir/lasokamodule" 2>/dev/null || true
    chmod +x "$bin_dir/lasokamodule" 2>/dev/null || true
    echo -e "${GREEN}[✓] lasokamodule command installed${RESET}"
  fi

  # ── Propagate lsmod ke semua AI/Agent containers ──
  echo -e "${YELLOW}[*] Propagating lsmod to AI & Agent containers...${RESET}"

  local ROC_DIR="$HOME/.roc-containers"
  local propagated=0

  # CrewAI
  if [ -d "$ROC_DIR/data-crewai-hermes" ]; then
    lsmod_propagate "crewai" "crewai-hermes" "$ROC_DIR/data-crewai-hermes"
    propagated=$((propagated + 1))
  else
    echo -e "  ${DIM}○ crewai — no data dir yet${RESET}"
  fi

  # Hermes Agent (hms)
  if [ -d "$ROC_DIR/apps/hms/data-root" ]; then
    lsmod_propagate "hermes-agent" "hermes-agent" "$ROC_DIR/apps/hms/data-root"
    propagated=$((propagated + 1))
  else
    echo -e "  ${DIM}○ hermes-agent — no data dir yet${RESET}"
  fi

  # ADK Invoice
  if [ -d "$ROC_DIR/data-adk-invoice" ]; then
    lsmod_propagate "adk-invoice" "adk-invoice" "$ROC_DIR/data-adk-invoice"
    propagated=$((propagated + 1))
  else
    echo -e "  ${DIM}○ adk-invoice — no data dir yet${RESET}"
  fi

  # Antigravity
  if [ -d "$ROC_DIR/data-antigravity-hermes" ]; then
    lsmod_propagate "antigravity" "antigravity-hermes" "$ROC_DIR/data-antigravity-hermes"
    propagated=$((propagated + 1))
  else
    echo -e "  ${DIM}○ antigravity — no data dir yet${RESET}"
  fi

  echo -e "\n  ${GREEN}[✓] Propagated to $propagated container(s)${RESET}"
  echo -e "${GREEN}[✓] lsmod module system ready${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Orchestrate — ⭐ fitur istimewa roc-ai
#  Koordinasi semua AI agents untuk task kompleks
# ──────────────────────────────────────────────────────────────
lsmod_orchestrate() {
  lsmod_load_keys
  local task="$1"

  if [ -z "$task" ]; then
    echo -e "${YELLOW}[lsmod] Usage: roc-ai orchestrate <task>${RESET}"
    echo -e "  ${DIM}Orkestrasi semua AI agents untuk task kompleks${RESET}"
    return 1
  fi

  echo -e "${MAGENTA}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  🎼 lsmod — Orchestration Mode                      ║"
  echo " ║  Semua AI Agents terhubung via roc-containers        ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  echo -e "  ${BOLD}Task:${RESET} $task\n"

  # Phase 1: Analyze task
  echo -e "  ${CYAN}[1/3] Analyzing task...${RESET}"
  local analysis
  if command -v roc-agent &>/dev/null; then
    analysis=$(roc-agent ask "Categorize this task and suggest which AI agents should handle it. Task: $task. Available agents: roc-agent (general AI), crewai (multi-agent), hermes-agent (autonomous), adk-invoice (document processing). Reply in one line." 2>/dev/null || echo "general")
  else
    analysis="general"
  fi
  echo -e "  ${DIM}Analysis: $analysis${RESET}\n"

  # Phase 2: Route ke agents
  echo -e "  ${CYAN}[2/3] Routing to agents...${RESET}"
  local routed=0

  # Primary: roc-agent
  if command -v roc-agent &>/dev/null; then
    echo -e "  ${GREEN}●${RESET} roc-agent → primary handler"
    routed=$((routed + 1))
  fi

  # Check if task needs crewai
  case "$analysis" in
    *crew*|*multi*|*team*|*collaborat*)
      if [ -f "$ROC_DIR/apps/crewai/crewai.sh" ]; then
        echo -e "  ${GREEN}●${RESET} crewai → multi-agent coordination"
        routed=$((routed + 1))
      fi
      ;;
  esac

  # Check if task needs hermes
  case "$analysis" in
    *autonom*|*tool*|*action*|*execut*)
      if [ -f "$ROC_DIR/apps/hms/hms.sh" ]; then
        echo -e "  ${GREEN}●${RESET} hermes-agent → autonomous execution"
        routed=$((routed + 1))
      fi
      ;;
  esac

  # Check if task needs ADK
  case "$analysis" in
    *invoice*|*document*|*pdf*|*process*)
      if [ -f "$ROC_DIR/apps/adk-invoice/adk-invoice.sh" ]; then
        echo -e "  ${GREEN}●${RESET} adk-invoice → document processing"
        routed=$((routed + 1))
      fi
      ;;
  esac

  echo -e "\n  ${DIM}Routed to $routed agent(s)${RESET}\n"

  # Phase 3: Execute
  echo -e "  ${CYAN}[3/3] Executing...${RESET}"
  lsmod_agent "$task"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Mesh — cek koneksi semua AI agents
# ──────────────────────────────────────────────────────────────
lsmod_mesh() {
  echo -e "${CYAN}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  🕸️ lsmod — AI Agent Mesh                           ║"
  echo " ║  Status koneksi semua AI containers                 ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  local ROC_DIR="$HOME/.roc-containers"
  local total=0; local online=0

  # roc-agent (Termux native)
  total=$((total + 1))
  if command -v roc-agent &>/dev/null; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-agent       ${DIM}Termux native${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${RED}○ OFFLINE${RESET} roc-agent       ${DIM}not found${RESET}"
  fi

  # CrewAI
  total=$((total + 1))
  if udocker inspect crewai-hermes &>/dev/null 2>&1; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-crewai      ${DIM}container ready${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-crewai      ${DIM}container not created${RESET}"
  fi

  # Hermes Agent
  total=$((total + 1))
  if udocker inspect hermes-agent &>/dev/null 2>&1; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-hms         ${DIM}container ready${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-hms         ${DIM}container not created${RESET}"
  fi

  # ADK Invoice
  total=$((total + 1))
  if udocker inspect adk-invoice &>/dev/null 2>&1; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-adk         ${DIM}container ready${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-adk         ${DIM}container not created${RESET}"
  fi

  # Antigravity
  total=$((total + 1))
  if udocker inspect antigravity-hermes &>/dev/null 2>&1; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-antigravity ${DIM}container ready${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-antigravity ${DIM}container not created${RESET}"
  fi

  # MAAGBA (clone-based, no container)
  total=$((total + 1))
  if [ -d "$ROC_DIR/apps/maagba/maagba-repo/.git" ]; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-maagba      ${DIM}repo cloned${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-maagba      ${DIM}not cloned${RESET}"
  fi

  # Hermes UI
  total=$((total + 1))
  if [ -d "$ROC_DIR/apps/hermui/hermes-ui/.git" ]; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-hermui      ${DIM}repo cloned${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-hermui      ${DIM}not cloned${RESET}"
  fi

  # Clawdex
  total=$((total + 1))
  if [ -d "$ROC_DIR/apps/clawdex/clawdex-mobile/.git" ]; then
    echo -e "  ${GREEN}● ONLINE${RESET}  roc-clawdex     ${DIM}repo cloned${RESET}"
    online=$((online + 1))
  else
    echo -e "  ${DIM}○ STANDBY${RESET} roc-clawdex     ${DIM}not cloned${RESET}"
  fi

  echo -e "\n  ${BOLD}Mesh Status:${RESET} ${online}/${total} agents available"
  echo -e "  ${BOLD}lsmod Propagation:${RESET} ${GREEN}active${RESET}  ${DIM}(lib/lsmod_loader.sh)${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Native — run lasokamodule native CLI
# ──────────────────────────────────────────────────────────────
lsmod_native() {
  lsmod_ensure
  if [ -f "$LSMOD_DIR/termux/lasokamodule.js" ] && command -v node &>/dev/null; then
    cd "$LSMOD_DIR" && exec node termux/lasokamodule.js "$@"
  else
    echo -e "${RED}[✗] lsmod native membutuhkan Node.js${RESET}"
    echo -e "  ${CYAN}pkg install nodejs${RESET}"
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
    echo " ║  lsmod — Module System ⭐ Pewaris roc-ai            ║"
    echo " ║  ivansslo/lsmod                                     ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}${MAGENTA}lsmod Modes:${RESET}"
    echo -e "  ${CYAN}agent <task>${RESET}      🤖 Agent Mode"
    echo -e "  ${CYAN}chat${RESET}              💬 Chat Mode (interactive)"
    echo -e "  ${CYAN}code <task>${RESET}       💻 Coding Mode"
    echo -e "  ${CYAN}error <msg>${RESET}       🐛 Error Handler / Fix"
    echo ""
    echo -e " ${BOLD}${CYAN}⭐ roc-ai Special (Pewaris):${RESET}"
    echo -e "  ${CYAN}orchestrate <task>${RESET} 🎼 Orchestrate all AI agents"
    echo -e "  ${CYAN}route <task> [ctx]${RESET} 🧭 Route to best agent"
    echo -e "  ${CYAN}broadcast <msg>${RESET}   📢 Broadcast to all agents"
    echo -e "  ${CYAN}mesh${RESET}              🕸️  AI Agent Mesh status"
    echo ""
    echo -e " ${BOLD}Management:${RESET}"
    echo -e "  ${CYAN}install${RESET}           Install + propagate to containers"
    echo -e "  ${CYAN}status${RESET}            Check module & service status"
    echo -e "  ${CYAN}native${RESET}            Run lasokamodule native CLI"
    echo -e "  ${CYAN}update${RESET}            Update lsmod to latest"
    echo ""
    echo -e " ${DIM}Spreads via: lib/lsmod_loader.sh → all roc-*${RESET}"
    echo -e " ${DIM}Repo: ivansslo/lsmod${RESET}"
    return 0
  fi

  case "$cmd" in
    # ── Modes ──
    agent|a)
      lsmod_agent "$@"
      ;;
    chat|c)
      lsmod_chat "$@"
      ;;
    code|coding|co)
      lsmod_code "$@"
      ;;
    error|err|e|fix)
      lsmod_error "$@"
      ;;

    # ── ⭐ roc-ai Special ──
    orchestrate|orch|o)
      lsmod_orchestrate "$@"
      ;;
    route|r)
      lsmod_route "$@"
      ;;
    broadcast|bcast|b)
      lsmod_broadcast "$@"
      ;;
    mesh)
      lsmod_mesh
      ;;

    # ── Management ──
    install|setup|i)
      lsmod_install
      ;;
    status|st|ps)
      lsmod_status
      ;;
    native|lsmod|l)
      lsmod_native "$@"
      ;;
    update|up|pull)
      if [ -d "$LSMOD_DIR/.git" ]; then
        echo -e "${YELLOW}[*] Updating lsmod...${RESET}"
        git -C "$LSMOD_DIR" pull --ff-only 2>/dev/null || true
        # Re-sanitize keys
        [ -f "$LSMOD_DIR/config/keys.json" ] && echo '{}' > "$LSMOD_DIR/config/keys.json"
        echo -e "${GREEN}[✓] Updated${RESET}"
      else
        lsmod_ensure
      fi
      ;;
    *)
      echo -e "${RED}Unknown command: $cmd${RESET}"
      echo -e "Run ${CYAN}roc-ai${RESET} for usage"
      ;;
  esac
}

lsmod_main "$@"
