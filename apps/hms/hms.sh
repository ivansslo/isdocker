#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Hermes Agent (hms)
#  Autonomous tool-using AI agent — clones ivansslo/hermes-agent
# ─────────────────────────────────────────────────────────────────

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null || true

# Colors
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${BOLD:=$'\033[1m'}"
: "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

HMS_DIR="$HOME/.roc-containers/apps/hms"
HMS_REPO="https://github.com/ivansslo/hermes-agent"
CONTAINER_NAME="hermes-agent"
IMAGE_NAME="python:3.12-slim"

# ── Ensure repo cloned ──────────────────────────────────
hms_ensure() {
  if [ ! -d "$HMS_DIR/.git" ]; then
    echo -e "${YELLOW}[*] Cloning hermes-agent...${RESET}"
    git clone --depth 1 "$HMS_REPO" "$HMS_DIR" 2>/dev/null
  else
    git -C "$HMS_DIR" pull --ff-only 2>/dev/null || true
  fi
}

# ── Keys dari ~/.hermes_keys ────────────────────────────
KEYS_FILE="$HOME/.hermes_keys"
_key(){ grep -E "^$1=" "$KEYS_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d "\"'"; }
GROQ_KEY="${GROQ_KEY:-$(_key GROQ_KEY)}"; [ -z "$GROQ_KEY" ] && GROQ_KEY="$(_key GROQ_API_KEY)"
OR_KEY="${OR_KEY:-$(_key OR_KEY)}"; [ -z "$OR_KEY" ] && OR_KEY="$(_key OPENROUTER_KEY)"
GEMINI_KEY="${GEMINI_KEY:-$(_key GEMINI_API_KEY)}"
OPENAI_KEY="${OPENAI_KEY:-$(_key OPENAI_API_KEY)}"
TOKEN="${TOKEN:-$(_key TOKEN)}"
PROVIDER="${PROVIDER:-groq}"
MODEL="${MODEL:-}"

# ── Setup venv di dalam container ───────────────────────
hms_setup() {
  hms_ensure
  udocker_check 2>/dev/null || bash "$HOME/.roc-containers/install_udocker.sh"
  udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

  local DATA_DIR="$HMS_DIR/data-root"
  mkdir -p "$DATA_DIR/root"

  # Copy engine ke data dir
  cp -rf "$HMS_DIR/engine" "$DATA_DIR/root/agent" 2>/dev/null || true

  echo -e "${YELLOW}[*] Setting up venv in container (root)...${RESET}"
  udocker run --entrypoint "bash -c" \
    -u root \
    -v "$DATA_DIR/root:/root" \
    -e HOME="/root" \
    "$CONTAINER_NAME" '
      python3 -m venv /root/venv 2>/dev/null || { apt-get update -qq && apt-get install -y python3-venv >/dev/null 2>&1 && python3 -m venv /root/venv; }
      /root/venv/bin/python -m pip install -q -U pip
      if [ -f /root/agent/requirements.txt ]; then
        /root/venv/bin/python -m pip install -q -r /root/agent/requirements.txt 2>/dev/null && echo "[✓] Dependencies installed" || echo "[!] Some deps failed — core still works"
      fi
      echo "[✓] Hermes Agent venv ready (root)"
    '
  echo -e "${GREEN}[✓] Setup complete. Run: roc-hms run${RESET}"
}

# ── Run agent ───────────────────────────────────────────
hms_run() {
  hms_ensure
  local task="$*"
  local DATA_DIR="$HMS_DIR/data-root"
  mkdir -p "$DATA_DIR/root"

  # Auto-setup jika venv belum ada
  if ! udocker inspect "$CONTAINER_NAME" &>/dev/null; then
    hms_setup
  fi

  if [ -n "$task" ]; then
    local T_B64="$(printf '%s' "$task" | base64 | tr -d '\n')"
    udocker run --entrypoint "bash -c" \
      -u root -i -t \
      -v "$DATA_DIR/root:/root" \
      -e HOME="/root" \
      -e PROVIDER="$PROVIDER" -e MODEL="$MODEL" \
      -e GROQ_KEY="$GROQ_KEY" -e OR_KEY="$OR_KEY" \
      -e GEMINI_KEY="$GEMINI_KEY" -e OPENAI_API_KEY="$OPENAI_KEY" \
      -e TOKEN="$TOKEN" \
      -e HERMES_WORKSPACE="/root/workspace" -e PYTHONPATH="/root" \
      "$CONTAINER_NAME" "cd /root && source /root/venv/bin/activate 2>/dev/null; TASK=\$(echo '$T_B64' | base64 -d) && exec /root/venv/bin/python -m agent \"\$TASK\""
  else
    # REPL interaktif
    udocker run --entrypoint "bash -c" \
      -u root -i -t \
      -v "$DATA_DIR/root:/root" \
      -e HOME="/root" \
      -e PROVIDER="$PROVIDER" -e MODEL="$MODEL" \
      -e GROQ_KEY="$GROQ_KEY" -e OR_KEY="$OR_KEY" \
      -e GEMINI_KEY="$GEMINI_KEY" -e OPENAI_API_KEY="$OPENAI_KEY" \
      -e TOKEN="$TOKEN" \
      -e HERMES_WORKSPACE="/root/workspace" -e PYTHONPATH="/root" \
      "$CONTAINER_NAME" "cd /root && source /root/venv/bin/activate 2>/dev/null; exec /root/venv/bin/python -m agent"
  fi
}

# ── Shell container ────────────────────────────────────
hms_shell() {
  hms_ensure
  local DATA_DIR="$HMS_DIR/data-root"
  mkdir -p "$DATA_DIR/root"
  echo -e "${DIM}[*] Shell container hermes-agent (root). 'exit' to quit.${RESET}"
  udocker run --entrypoint "bash -c" \
    -u root -i -t \
    -v "$DATA_DIR/root:/root" \
    -e HOME="/root" \
    "$CONTAINER_NAME" "cd /root; [ -x /root/venv/bin/python ] && source /root/venv/bin/activate; exec bash"
}

# ── Version ────────────────────────────────────────────
hms_version() {
  hms_ensure
  local DATA_DIR="$HMS_DIR/data-root"
  udocker run --entrypoint "bash -c" \
    -u root \
    -v "$DATA_DIR/root:/root" \
    -e HOME="/root" \
    "$CONTAINER_NAME" "/root/venv/bin/python -c \"import agent, sys; print('Hermes Agent engine', agent.__version__); print('Python', sys.version.split()[0])\" 2>/dev/null || echo '[!] Not yet setup. Run: roc-hms setup'"
}

# ── Tailscale check ────────────────────────────────────
hms_tailscale() {
  hms_ensure
  bash "$HMS_DIR/../hermes-agent/tailscale_check.sh" "$CONTAINER_NAME" "$HMS_DIR/data-root" 2>/dev/null || \
    echo -e "${YELLOW}[!] tailscale_check.sh not found in hermes-agent repo${RESET}"
}

# ── Main ───────────────────────────────────────────────
case "${1:-menu}" in
  setup|init|i)
    hms_setup
    ;;
  run|agent|r|a)
    shift; hms_run "$@"
    ;;
  shell|sh)
    hms_shell
    ;;
  version|v|ver)
    hms_version
    ;;
  tailscale|ts)
    hms_tailscale
    ;;
  update|up)
    echo -e "${YELLOW}[*] Updating hermes-agent...${RESET}"
    git -C "$HMS_DIR" pull 2>/dev/null || hms_ensure
    echo -e "${GREEN}[✓] Updated${RESET}"
    ;;
  *)
    echo -e "${CYAN}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════╗"
    echo " ║  Hermes Agent (hms) — Autonomous AI Agent            ║"
    echo " ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e " ${BOLD}Usage:${RESET}"
    echo -e "  ${CYAN}roc-hms setup${RESET}        Setup venv + dependencies (root)"
    echo -e "  ${CYAN}roc-hms run${RESET}          Run agent (interactive REPL)"
    echo -e "  ${CYAN}roc-hms run <task>${RESET}   Run agent (single task)"
    echo -e "  ${CYAN}roc-hms shell${RESET}       Shell container (root)"
    echo -e "  ${CYAN}roc-hms version${RESET}     Engine + Python version"
    echo -e "  ${CYAN}roc-hms tailscale${RESET}   Check Tailscale compatibility"
    echo -e "  ${CYAN}roc-hms update${RESET}      Update hermes-agent repo"
    echo ""
    echo -e " ${DIM}Provider: $PROVIDER | Model: ${MODEL:-auto}${RESET}"
    echo -e " ${DIM}Keys from ~/.hermes_keys${RESET}"
    ;;
esac
