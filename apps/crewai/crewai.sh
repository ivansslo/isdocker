#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"
IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="crewai-hermes"
GROQ_KEY="$(cat ~/.hermes_keys 2>/dev/null | grep GROQ | cut -d= -f2)"
DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"
[ -f "$DATA_DIR/root/crew.py" ] || curl -sL "https://raw.githubusercontent.com/ivansslo/solace-crewai-cli/main/crew.py" -o "$DATA_DIR/root/crew.py"
udocker_check 2>/dev/null; udocker_prune 2>/dev/null; udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null
case "$1" in
  setup) udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" "$CONTAINER_NAME" 'pip install --upgrade pip -q && pip install crewai 2>&1 | tail -5 && python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"' ;;
  run) shift; TOPIC="${*:-AI agents in 2026}"; udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" -e GROQ_API_KEY="$GROQ_KEY" -e OPENAI_API_KEY="$GROQ_KEY" -e OPENAI_API_BASE="https://api.groq.com/openai/v1" -e OPENAI_MODEL_NAME="llama-3.3-70b-versatile" -e CREWAI_TELEMETRY_OPT_OUT=true "$CONTAINER_NAME" "python3 /root/crew.py $TOPIC" ;;
  version) udocker_run --entrypoint "bash -c" -v "$DATA_DIR/root:/root" "$CONTAINER_NAME" 'python3 -c "import crewai;print(\"CrewAI\",crewai.__version__)"' ;;
  shell) udocker_run --entrypoint "bash" -v "$DATA_DIR/root:/root" -e GROQ_API_KEY="$GROQ_KEY" -e OPENAI_API_KEY="$GROQ_KEY" -e OPENAI_API_BASE="https://api.groq.com/openai/v1" -e OPENAI_MODEL_NAME="llama-3.3-70b-versatile" "$CONTAINER_NAME" ;;
  *) echo ""; echo "  🤖 CrewAI — Solace Hermes"; echo ""; echo "  hermes setup       Install CrewAI"; echo "  hermes run [topic]  Run AI crew"; echo "  hermes version      Show version"; echo "  hermes shell        Enter container"; echo "" ;;
esac
exit $?
