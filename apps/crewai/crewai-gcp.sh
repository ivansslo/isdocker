#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · CrewAI (Hermes) — Gemini / GCP variant
#  Image : python:3.12-slim
#
#  Wrapper di sekitar solace-crewai-cli yang mengarahkan CrewAI ke
#  Google Gemini (via LiteLLM) memakai kredensial dari ~/.hermes_keys
#  (menu → Google Project → Provider GCP). File crewai.sh (Groq) tetap
#  utuh; ini varian terpisah.
#
#  Subcommands:
#     setup      pip install crewai
#     run [topic]  Jalankan crew memakai Gemini
#     version    Versi crewai
#     shell      Masuk container (env Gemini)
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="crewai-hermes"   # image sama dgn crewai.sh (Groq) — hemat

# ── Kredensial GCP/Gemini dari ~/.hermes_keys ───────────────────
GEMINI_KEY="$(grep -E '^GEMINI_API_KEY=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
[ -z "$GEMINI_KEY" ] && GEMINI_KEY="$(grep -E '^GOOGLE_API_KEY=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
# Model bisa dioverride via ~/.hermes_keys → GEMINI_MODEL=gemini-2.5-pro
GEMINI_MODEL="$(grep -E '^GEMINI_MODEL=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
[ -z "$GEMINI_MODEL" ] && GEMINI_MODEL="gemini-2.5-flash"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"
# crew.py sama seperti varian Groq
[ -f "$DATA_DIR/root/crew.py" ] || curl -sL "https://raw.githubusercontent.com/ivansslo/solace-crewai-cli/main/crew.py" -o "$DATA_DIR/root/crew.py"

udocker_check 2>/dev/null; udocker_prune 2>/dev/null
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

# Env yang mengarahkan CrewAI/LiteLLM ke Gemini (prefix gemini/ wajib).
# OPENAI_API_BASE sengaja TIDAK diset agar tidak ke-route ke OpenAI/Groq.
_GEM_ENV=(
  -e GEMINI_API_KEY="$GEMINI_KEY"
  -e GOOGLE_API_KEY="$GEMINI_KEY"
  -e OPENAI_MODEL_NAME="gemini/$GEMINI_MODEL"
  -e MODEL="gemini/$GEMINI_MODEL"
  -e CREWAI_TELEMETRY_OPT_OUT=true
)

case "$1" in
  setup)
    udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" "$CONTAINER_NAME" \
      'pip install --upgrade pip -q && pip install crewai 2>&1 | tail -5 && python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"'
    ;;
  run)
    shift; TOPIC="${*:-AI agents in 2026}"
    [ -z "$GEMINI_KEY" ] && echo "[!] GEMINI_API_KEY belum di-set — Google Project → Provider GCP"
    udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" \
      "${_GEM_ENV[@]}" "$CONTAINER_NAME" "python3 /root/crew.py $TOPIC"
    ;;
  version)
    udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" "$CONTAINER_NAME" \
      'python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"'
    ;;
  shell)
    udocker_run --entrypoint "bash" -v "$DATA_DIR/root:/root" \
      "${_GEM_ENV[@]}" "$CONTAINER_NAME"
    ;;
  *)
    echo ""
    echo "  🤖 CrewAI — Gemini / GCP"
    echo ""
    echo "  crewai-gcp setup       Install CrewAI"
    echo "  crewai-gcp run [topic]  Jalankan crew (Gemini: $GEMINI_MODEL)"
    echo "  crewai-gcp version      Versi CrewAI"
    echo "  crewai-gcp shell        Masuk container"
    echo ""
    echo "  Kredensial: Google Project → Provider GCP (~/.hermes_keys)"
    echo ""
    ;;
esac
exit $?
