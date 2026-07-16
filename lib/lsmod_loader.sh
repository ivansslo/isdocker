#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  lsmod Loader v2.0.0 — Native Module System (REFRESH)
#
#  v2.0.0 (2026-07-16):
#    - SEMUA integrasi kontainer dihapus (lsmod_propagate, container
#      data-dir, init.sh injection) — sejalan keputusan v1.5.0:
#      tidak ada lagi koneksi ke containers.
#    - Module registry formal: `lsmod registry`
#    - mesh() kini mengukur layanan NATIVE (bukan container)
#
#  Source file ini dari roc-* script:
#    source "$HOME/.roc-containers/lib/lsmod_loader.sh"
#
#  Menyediakan:
#    lsmod_agent <task>   lsmod_chat          lsmod_code <task>
#    lsmod_error <msg>    lsmod_load_keys     lsmod_route <task>
#    lsmod_broadcast <m>  lsmod_mesh          lsmod_status
#    lsmod_registry       lsmod_ensure
# ─────────────────────────────────────────────────────────────────

LSMOD_LOADER_VERSION="2.0.0"
LSMOD_DIR="$HOME/.roc-containers/apps/ai/modules/lsmod"
LSMOD_SH="$HOME/.roc-containers/apps/ai/lsmod.sh"
ROC_DIR="$HOME/.roc-containers"

# Solace connection (auto-load)
[ -f "$HOME/.config/hermes/solace.env" ] && source "$HOME/.config/hermes/solace.env" 2>/dev/null

# ──────────────────────────────────────────────────────────────
#  Colors (safe fallback)
# ──────────────────────────────────────────────────────────────
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

# ──────────────────────────────────────────────────────────────
#  Module Registry — sumber kebenaran modul lsmod (native)
#  Format: nama|deskripsi|handler
# ──────────────────────────────────────────────────────────────
LSMOD_REGISTRY=(
  "agent|🤖 Agent mode — delegasi tugas otonom|lsmod_agent"
  "chat|💬 Chat interaktif|lsmod_chat"
  "code|💻 Coding assistant|lsmod_code"
  "error|🐛 Error handler & fix|lsmod_error"
  "route|🧭 Routing task ke modul terbaik|lsmod_route"
  "broadcast|📢 Broadcast pesan ke semua modul|lsmod_broadcast"
  "orchestrate|🎼 Koordinasi multi-agent native|lsmod_orchestrate"
  "mesh|🕸️ Status layanan native|lsmod_mesh"
)

lsmod_registry() {
  echo -e "${MAGENTA}${BOLD}lsmod Module Registry v${LSMOD_LOADER_VERSION} (native)${RESET}\n"
  local entry name desc
  for entry in "${LSMOD_REGISTRY[@]}"; do
    name="${entry%%|*}"; desc="${entry#*|}"; desc="${desc%%|*}"
    printf "  ${CYAN}%-12s${RESET} %s\n" "$name" "$desc"
  done
  echo ""
  echo -e "  ${DIM}${#LSMOD_REGISTRY[@]} modules registered (native-only, no containers)${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Ensure — modul opsional (repo bila tersedia)
# ──────────────────────────────────────────────────────────────
lsmod_ensure() {
  if [ ! -d "$LSMOD_DIR/.git" ]; then
    echo -e "${YELLOW}[lsmod] Cloning module system...${RESET}"
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://github.com/ivansslo/lsmod "$LSMOD_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}[lsmod] Repo ivansslo/lsmod tidak bisa di-clone (privat/belum rilis/offline).${RESET}"
      echo -e "${DIM}[lsmod] Mode bawaan tetap jalan: agent/chat/code/error/route/broadcast/orchestrate/mesh.${RESET}"
      return 1
    fi
    # Sanitize hardcoded keys
    [ -f "$LSMOD_DIR/config/keys.json" ] && echo '{}' > "$LSMOD_DIR/config/keys.json"
    echo -e "${GREEN}[lsmod] Module system ready${RESET}"
  fi
}

# ──────────────────────────────────────────────────────────────
#  Load API Keys — dari ~/.hermes_keys + ~/.hermes/.keys
# ──────────────────────────────────────────────────────────────
lsmod_load_keys() {
  [ -f "$HOME/.hermes_keys" ] && source "$HOME/.hermes_keys" 2>/dev/null
  if [ -f "$HOME/.hermes/.keys" ]; then
    while IFS='=' read -r key val; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && continue
      val="${val%\"}" ; val="${val#\"}" ; val="${val%\'}" ; val="${val#\'}"
      [ -z "${!key:-}" ] && export "$key=$val"
    done < "$HOME/.hermes/.keys"
  fi
}

# ──────────────────────────────────────────────────────────────
#  Delegasi dasar ke roc-agent
# ──────────────────────────────────────────────────────────────
_lsmod_need_agent() {
  if command -v roc-agent &>/dev/null; then return 0
  elif [ -f "$ROC_DIR/apps/roc-agent/hermes" ]; then return 1   # fallback bundle
  else return 2; fi
}

_lsmod_agent_run() {  # <subcmd> <args...>
  local st; _lsmod_need_agent; st=$?
  if [ $st -eq 0 ]; then exec roc-agent "$@"
  elif [ $st -eq 1 ]; then exec bash "$ROC_DIR/apps/roc-agent/hermes" "$@"
  else
    echo -e "${RED}[lsmod] roc-agent tidak tersedia. Jalankan: bash setup.sh${RESET}"
    return 1
  fi
}

lsmod_agent() {
  lsmod_load_keys
  local task="${*:-}"
  [ -z "$task" ] && { echo -e "${YELLOW}[lsmod] Usage: lsmod_agent <task>${RESET}"; return 1; }
  _lsmod_agent_run agent "$task"
}

lsmod_chat() {
  lsmod_load_keys
  _lsmod_agent_run chat "${@:-}"
}

lsmod_code() {
  lsmod_load_keys
  local task="${*:-}"
  [ -z "$task" ] && { echo -e "${YELLOW}[lsmod] Usage: lsmod_code <task>${RESET}"; return 1; }
  _lsmod_agent_run code "$task"
}

lsmod_error() {
  lsmod_load_keys
  local msg="${*:-}"
  [ -z "$msg" ] && { echo -e "${YELLOW}[lsmod] Usage: lsmod_error <error_message>${RESET}"; return 1; }
  _lsmod_agent_run ask "Fix this error: $msg"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Route — routing task ke modul yg tepat (pattern match)
# ──────────────────────────────────────────────────────────────
lsmod_route() {
  local task="$1"
  if [ -z "$task" ]; then
    echo -e "${YELLOW}[lsmod] Usage: lsmod_route <task>${RESET}"
    return 1
  fi
  local target="chat"
  case "$task" in
    *error*|*Error*|*bug*|*BUG*|*gagal*|*Traceback*|*traceback*) target="error" ;;
    *code*|*function*|*script*|*refactor*|*debug*|*koding*|*coding*) target="code" ;;
    *deploy*|*build*|*create*|*buat*|*implement*|*install*|*setup*|*tulis*) target="agent" ;;
  esac
  echo -e "  ${CYAN}[lsmod:route]${RESET} task → modul ${BOLD}${target}${RESET}"
  case "$target" in
    error) lsmod_error "$task" ;;
    code)  lsmod_code "$task" ;;
    agent) lsmod_agent "$task" ;;
    *)     lsmod_chat "$task" ;;
  esac
}

# ──────────────────────────────────────────────────────────────
#  lsmod Broadcast — pesan ke semua modul native
# ──────────────────────────────────────────────────────────────
lsmod_broadcast() {
  local msg="${*:-}"
  if [ -z "$msg" ]; then
    echo -e "${YELLOW}[lsmod] Usage: lsmod_broadcast <message>${RESET}"
    return 1
  fi
  echo -e "${MAGENTA}${BOLD}📢 lsmod Broadcast${RESET}"
  echo -e "  ${DIM}Message: $msg${RESET}\n"
  local entry name handler sent=0
  mkdir -p "$HOME/.hermes"
  echo "$(date -Iseconds) $msg" >> "$HOME/.hermes/lsmod_broadcast.log"
  for entry in "${LSMOD_REGISTRY[@]}"; do
    name="${entry%%|*}"; handler="${entry##*|}"
    if declare -F "$handler" >/dev/null 2>&1; then
      echo -e "  ${GREEN}●${RESET} $name ${DIM}($handler)${RESET} — registered ✓"
      sent=$((sent + 1))
    fi
  done
  echo -e "\n  ${DIM}Logged → ~/.hermes/lsmod_broadcast.log · $sent/${#LSMOD_REGISTRY[@]} modules${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Mesh — status layanan NATIVE (bukan container lagi)
# ──────────────────────────────────────────────────────────────
lsmod_mesh() {
  echo -e "${CYAN}${BOLD}"
  echo " ╔══════════════════════════════════════════════════════╗"
  echo " ║  🕸️ lsmod — Native Service Mesh (v2)                ║"
  echo " ║  Status layanan native (tanpa containers)           ║"
  echo " ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  local total=0 online=0
  _chk() {  # _chk <label> <ok?> <detail>
    total=$((total + 1))
    if [ "$2" = "1" ]; then
      echo -e "  ${GREEN}● ONLINE${RESET}  $1  ${DIM}$3${RESET}"; online=$((online + 1))
    else
      echo -e "  ${DIM}○ STANDBY${RESET} $1  ${DIM}$3${RESET}"
    fi
  }

  command -v roc-agent &>/dev/null && _chk "roc-agent      " 1 "Termux native CLI" \
    || { [ -f "$ROC_DIR/apps/roc-agent/hermes" ] && _chk "roc-agent      " 1 "bundled hermes" || _chk "roc-agent      " 0 "not found"; }
  [ -d "$ROC_DIR/apps/ai/roadfx-ai-stack/.git" ] && _chk "roadfx-ai      " 1 "repo cloned" || _chk "roadfx-ai      " 0 "not cloned"
  [ -d "$LSMOD_DIR/.git" ] && _chk "lsmod repo     " 1 "module cloned" || _chk "lsmod repo     " 0 "optional — built-in OK"
  [ -d "$ROC_DIR/apps/maagba/maagba-repo/.git" ] && _chk "roc-maagba     " 1 "repo cloned" || _chk "roc-maagba     " 0 "not cloned"
  [ -d "$ROC_DIR/apps/clawdex/clawdex-mobile/.git" ] && _chk "roc-clawdex    " 1 "repo cloned" || _chk "roc-clawdex    " 0 "not cloned"
  [ -f "$HOME/.config/hermes/solace.env" ] && _chk "solace env     " 1 "credentials file" || _chk "solace env     " 0 "not configured"
  [ -f "$HOME/.hermes_keys" ] || [ -f "$HOME/.hermes/.keys" ] && _chk "api keys       " 1 "hermes keys loaded" || _chk "api keys       " 0 "run: roc-agent setup"
  if curl -sS -m 4 -o /dev/null "https://ai.roadfx.biz.id" 2>/dev/null; then _chk "gateway        " 1 "ai.roadfx.biz.id reachable"; else _chk "gateway        " 0 "unreachable"; fi

  echo -e "\n  ${BOLD}Mesh Status:${RESET} ${online}/${total} layanan native tersedia"
  echo -e "  ${BOLD}lsmod v${LSMOD_LOADER_VERSION}${RESET} ${GREEN}native-only${RESET} ${DIM}(no containers — v1.5.0)${RESET}"
}

# ──────────────────────────────────────────────────────────────
#  lsmod Status — modul + registry + keys
# ──────────────────────────────────────────────────────────────
lsmod_status() {
  echo -e "${MAGENTA}${BOLD}lsmod Module System v${LSMOD_LOADER_VERSION} (native)${RESET}\n"

  if [ -d "$LSMOD_DIR/.git" ]; then
    local ver=$(git -C "$LSMOD_DIR" describe --tags --always 2>/dev/null || git -C "$LSMOD_DIR" rev-parse --short HEAD 2>/dev/null)
    echo -e "  ${BOLD}Module repo:${RESET} ${GREEN}✓${RESET} lsmod ${DIM}($ver)${RESET}"
  else
    echo -e "  ${BOLD}Module repo:${RESET} ${YELLOW}−${RESET} tidak ter-clone ${DIM}(opsional — built-in aktif)${RESET}"
  fi

  [ -f "$ROC_DIR/lib/lsmod_loader.sh" ] \
    && echo -e "  ${BOLD}Loader:${RESET}      ${GREEN}✓${RESET} lsmod_loader.sh v${LSMOD_LOADER_VERSION}"

  if command -v roc-agent &>/dev/null || [ -f "$ROC_DIR/apps/roc-agent/hermes" ]; then
    echo -e "  ${BOLD}Agent:${RESET}       ${GREEN}✓${RESET} roc-agent (agent/chat/code/error via CLI)"
  else
    echo -e "  ${BOLD}Agent:${RESET}       ${YELLOW}⚠${RESET} roc-agent not found"
  fi

  echo ""
  lsmod_registry

  lsmod_load_keys
  local keys_ok=0
  for k in GROQ_KEY OPENAI_KEY OR_KEY GEMINI_API_KEY TOKEN; do
    [ -n "${!k:-}" ] && keys_ok=$((keys_ok + 1))
  done
  echo -e "  ${BOLD}API Keys:${RESET} ${keys_ok} configured ${DIM}($keys_ok/5)${RESET}"
}
