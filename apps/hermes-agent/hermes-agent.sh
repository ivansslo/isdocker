#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Hermes Agent — autonomous complex-task AI agent
#
#  Menjalankan Hermes Agent (tool-using ReAct loop) DI DALAM container
#  udocker (python:3.12-slim), sebagai ROOT, memakai Python VENV yang
#  dipersist di data dir agar dependency & login bertahan antar-run.
#
#  Subcommand:
#     setup            Buat venv + install dependency (sekali saja)
#     run [task]       Jalankan agent (interaktif bila tanpa task)
#     agent [task]     Alias dari run
#     version          Tampilkan versi engine + Python
#     shell            Masuk shell container (root)
#     tailscale        Cek kecocokan / status Tailscale CLI di container
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"

# Colors (fallback bila tidak diwarisi dari menu.sh)
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${MAGENTA:=$'\033[0;35m'}"
: "${BOLD:=$'\033[1m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="hermes-agent"

# ── Paths (persist di host, di-mount ke /root dalam container) ───────
APP_DIR="$(pwd)"
DATA_DIR="$APP_DIR/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"

# venv & engine hidup DI DALAM /root (yang di-mount), jadi persist.
VENV_IN="/root/venv"                       # path venv di dalam container
PY_IN="$VENV_IN/bin/python"                # interpreter venv
AGENT_HOME_IN="/root/agent"                # package engine di dalam container

# ── Kredensial: berbagi ~/.hermes_keys seperti app lain di roc-containers ─
KEYS_FILE="$HOME/.hermes_keys"
_key(){ grep -E "^$1=" "$KEYS_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'"'"'\r'; }
GROQ_KEY="${GROQ_KEY:-$(_key GROQ_KEY)}"; [ -z "$GROQ_KEY" ] && GROQ_KEY="$(_key GROQ_API_KEY)"
OR_KEY="${OR_KEY:-$(_key OR_KEY)}";       [ -z "$OR_KEY" ] && OR_KEY="$(_key OPENROUTER_KEY)"
GEMINI_KEY="${GEMINI_KEY:-$(_key GEMINI_API_KEY)}"
OPENAI_API_KEY="${OPENAI_API_KEY:-$(_key OPENAI_API_KEY)}"
TOKEN="${TOKEN:-$(_key TOKEN)}"
PROVIDER="${PROVIDER:-groq}"
MODEL="${MODEL:-}"

# ── Sinkronkan engine (apps/hermes-agent/engine → data-.../root/agent)
sync_engine(){
  mkdir -p "$DATA_DIR/root/agent"
  cp -f "$APP_DIR/engine/"*.py "$DATA_DIR/root/agent/" 2>/dev/null || true
  cp -f "$APP_DIR/engine/requirements.txt" "$DATA_DIR/root/agent/" 2>/dev/null || true
}

# ── Siapkan container (pull + create) ───────────────────────────────
prepare(){
  udocker_check 2>/dev/null
  udocker_prune 2>/dev/null
  udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null
  sync_engine
}

# ── Jalankan bash -c di dalam container SEBAGAI ROOT dengan env keys ─
in_container(){
  udocker_run --entrypoint "bash -c" \
    -u root \
    -v "$DATA_DIR/root:/root" \
    -e HOME="/root" \
    -e PROVIDER="$PROVIDER" \
    -e MODEL="$MODEL" \
    -e GROQ_KEY="$GROQ_KEY" \
    -e OR_KEY="$OR_KEY" \
    -e GEMINI_KEY="$GEMINI_KEY" \
    -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    -e TOKEN="$TOKEN" \
    -e HERMES_WORKSPACE="/root/workspace" \
    -e PYTHONPATH="/root" \
    -e PIP_DISABLE_PIP_VERSION_CHECK=1 \
    "$CONTAINER_NAME" "$1"
}

# Interaktif (mewarisi TTY) — dipakai untuk REPL & shell
in_container_tty(){
  udocker_run --entrypoint "bash -c" \
    -u root -i -t \
    -v "$DATA_DIR/root:/root" \
    -e HOME="/root" \
    -e PROVIDER="$PROVIDER" -e MODEL="$MODEL" \
    -e GROQ_KEY="$GROQ_KEY" -e OR_KEY="$OR_KEY" \
    -e GEMINI_KEY="$GEMINI_KEY" -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    -e TOKEN="$TOKEN" \
    -e HERMES_WORKSPACE="/root/workspace" -e PYTHONPATH="/root" \
    "$CONTAINER_NAME" "$1"
}

# ── Skrip setup venv (dijalankan DI DALAM container, sebagai root) ──
read -r -d '' _VENV_SETUP <<VSETUP
set -e
export DEBIAN_FRONTEND=noninteractive
mkdir -p /root/workspace
# Pastikan modul venv tersedia (python:3.12-slim biasanya sudah punya)
if ! python3 -c 'import venv' 2>/dev/null; then
  echo '[*] Menginstall python3-venv...'
  apt-get update -qq && apt-get install -y --no-install-recommends python3-venv >/dev/null 2>&1 || true
fi
if [ ! -x "$PY_IN" ]; then
  echo '[*] Membuat virtual environment di $VENV_IN ...'
  python3 -m venv "$VENV_IN"
fi
echo '[*] Upgrade pip + install dependency (rich/requests/python-dotenv)...'
"$PY_IN" -m pip install --quiet --upgrade pip 2>/dev/null || true
if [ -f "$AGENT_HOME_IN/requirements.txt" ]; then
  "$PY_IN" -m pip install --quiet -r "$AGENT_HOME_IN/requirements.txt" 2>/dev/null \
    && echo '[✓] Dependency terpasang.' \
    || echo '[!] Sebagian dependency gagal — core agent tetap jalan (stdlib).'
fi
echo '[✓] Venv Hermes Agent siap (root).'
"$PY_IN" --version
VSETUP

banner(){
  clear
  echo -e "${CYAN}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo    "  ║        roc-containers · Hermes Agent (autonomous)         ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${DIM}Agent tool-using di container udocker · root · venv${RESET}\n"
}

case "${1:-menu}" in
  setup)
    banner
    prepare
    echo -e "  ${YELLOW}[*] Menyiapkan venv & dependency di dalam container...${RESET}\n"
    in_container "$_VENV_SETUP"
    echo ""
    echo -e "  ${GREEN}[✓] Selesai.${RESET} Jalankan: ${BOLD}hermes-agent run${RESET}"
    ;;

  run|agent)
    shift
    prepare
    # Auto-setup bila venv belum ada
    in_container "[ -x '$PY_IN' ]" >/dev/null 2>&1 || in_container "$_VENV_SETUP"
    TASK="$*"
    if [ -n "$TASK" ]; then
      # Sekali jalan (aman utk task berisi kutip → base64)
      T_B64="$(printf '%s' "$TASK" | base64 | tr -d '\n')"
      in_container_tty "cd /root && TASK=\$(echo '$T_B64' | base64 -d) && exec '$PY_IN' -m agent \"\$TASK\""
    else
      # Mode REPL interaktif
      in_container_tty "cd /root && exec '$PY_IN' -m agent"
    fi
    ;;

  version)
    prepare
    in_container "'$PY_IN' -c \"import agent, sys; print('Hermes Agent engine', agent.__version__); print('Python', sys.version.split()[0])\" 2>/dev/null || echo '[!] Belum di-setup. Jalankan: hermes-agent setup'"
    ;;

  shell)
    prepare
    echo -e "  ${DIM}[*] Shell container Hermes Agent (root). 'exit' untuk keluar.${RESET}\n"
    in_container_tty "cd /root; [ -x '$PY_IN' ] && source '$VENV_IN/bin/activate'; exec bash"
    ;;

  tailscale|ts)
    # ── Cek kcompatibilitas CLI Tailscale di container ini ─────────
    prepare
    bash "$APP_DIR/tailscale_check.sh" "$CONTAINER_NAME" "$DATA_DIR"
    ;;

  *)
    banner
    echo -e "  ${BOLD}Penggunaan:${RESET} hermes-agent <perintah>\n"
    echo -e "  ${CYAN}setup${RESET}            Buat venv + install dependency (root)"
    echo -e "  ${CYAN}run${RESET} [task]       Jalankan agent (REPL bila tanpa task)"
    echo -e "  ${CYAN}agent${RESET} [task]     Alias dari run"
    echo -e "  ${CYAN}version${RESET}          Versi engine + Python"
    echo -e "  ${CYAN}shell${RESET}            Masuk shell container (root)"
    echo -e "  ${CYAN}tailscale${RESET}        Cek kecocokan Tailscale CLI di container"
    echo ""
    echo -e "  ${DIM}Contoh:${RESET}"
    echo -e "    ${DIM}hermes-agent setup${RESET}"
    echo -e "    ${DIM}hermes-agent run \"buat FastAPI todo + pytest, buat test-nya hijau\"${RESET}"
    echo -e "    ${DIM}PROVIDER=openrouter MODEL=deepseek/deepseek-chat hermes-agent run \"refactor app.py\"${RESET}"
    echo ""
    echo -e "  ${DIM}Kunci API dibaca dari ~/.hermes_keys (GROQ_KEY / OR_KEY / GEMINI_API_KEY / TOKEN).${RESET}"
    ;;
esac

exit $?
