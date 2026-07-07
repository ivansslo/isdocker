#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  isdocker · CrewAI — Solace Hermes
#  Image : python:3.12-slim
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="crewai-hermes"
GROQ_KEY="$(cat ~/.hermes_keys 2>/dev/null | grep GROQ | cut -d= -f2)"
CREWAI_PAT="$(cat ~/.hermes_keys 2>/dev/null | grep CREWAI | cut -d= -f2)"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"

# Download latest crew.py from repo
if [ ! -f "$DATA_DIR/root/crew.py" ] || [ "$1" = "setup" ]; then
  curl -sL "https://raw.githubusercontent.com/ivansslo/solace-crewai-cli/main/crew.py" \
    -o "$DATA_DIR/root/crew.py" 2>/dev/null
fi

udocker_check 2>/dev/null
udocker_prune 2>/dev/null
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

case "$1" in
  setup)
    echo -e "\n  Installing CrewAI...\n"
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      "$CONTAINER_NAME" '
        pip install --upgrade pip -q
        pip install crewai 2>&1 | tail -5
        python3 -c "import crewai;print(\"✅ CrewAI\",crewai.__version__)"
      '
    ;;
  run)
    shift
    TOPIC="${*:-AI agents in 2026}"
    echo -e "\n  🤖 Running crew: $TOPIC\n"
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      -e GROQ_API_KEY="$GROQ_KEY" \
      -e CREWAI_TELEMETRY_OPT_OUT=true \
      "$CONTAINER_NAME" \
      "cd /root && python3 crew.py $TOPIC"
    ;;
  version)
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      "$CONTAINER_NAME" \
      'python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"'
    ;;
  shell)
    udocker_run --entrypoint "bash" \
      -v "$DATA_DIR/root:/root" \
      -e GROQ_API_KEY="$GROQ_KEY" \
      "$CONTAINER_NAME"
    ;;
  deploy)
    echo "Deploying to CrewAI Cloud..."
    udocker_run --entrypoint "bash -c" \
      -v "$DATA_DIR/root:/root" \
      -e CREWAI_API_KEY="$CREWAI_PAT" \
      "$CONTAINER_NAME" \
      'pip install crewai -q && crewai deploy 2>/dev/null || echo "Manual deploy needed"'
    ;;
  *)
    echo ""
    echo "  🤖 CrewAI — Solace Hermes"
    echo ""
    echo "  hermes setup          Install CrewAI"
    echo "  hermes run [topic]    Run AI crew"
    echo "  hermes version        Show version"
    echo "  hermes shell          Enter container"
    echo "  hermes deploy         Deploy to Cloud"
    echo ""
    ;;
esac
exit $?
