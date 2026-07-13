#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · ADK Invoice-Processing (Google Agent Development Kit)
#  Image  : python:3.12-slim   (hermes-style)
#  Source : github.com/google/adk-samples
#           python/agents/invoice-processing
#  Model  : gemini-2.5-flash via Vertex AI
#
#  Subcommands:
#     setup      Clone sample + pip install (google-adk, vertexai, ...)
#     run|web    Start `adk web` UI on the chosen port (browser)
#     cli        Run `adk run` in the terminal
#     version    Show google-adk version
#     shell      Enter container shell
#
#  GCP credentials come from ~/.hermes_keys (menu → Google Project → Provider GCP)
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"

# Colors (fallback if not inherited from menu.sh)
: "${YELLOW:=$'\033[1;33m'}"; : "${GREEN:=$'\033[0;32m'}"
: "${DIM:=$'\033[2m'}"; : "${RED:=$'\033[0;31m'}"; : "${RESET:=$'\033[0m'}"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="adk-invoice-hermes"

ADK_REPO="https://github.com/google/adk-samples"
ADK_SUBDIR="python/agents/invoice-processing"

# ── Port (adk web) ──────────────────────────────────────────────
case $PORT in
  ''|*[!0-9]*) PORT=8000 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=8000 ;;
esac

# ── GCP credentials from ~/.hermes_keys ─────────────────────────
GEMINI_KEY="$(grep -E '^GEMINI_API_KEY=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_PROJECT="$(grep -E '^GCP_PROJECT=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_LOCATION="$(grep -E '^GCP_LOCATION=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_USE_VERTEX="$(grep -E '^GCP_USE_VERTEX=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_SA="$(grep -E '^GOOGLE_APPLICATION_CREDENTIALS=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
[ -z "$GCP_LOCATION" ] && GCP_LOCATION="us-central1"
# ADK invoice sample defaults to Vertex AI
[ -z "$GCP_USE_VERTEX" ] && GCP_USE_VERTEX="true"
VERTEX_FLAG="FALSE"; [ "$GCP_USE_VERTEX" = "true" ] && VERTEX_FLAG="TRUE"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"

# Mount service-account JSON into the container if configured
SA_MOUNT=(); SA_ENV=()
if [ -n "$GCP_SA" ] && [ -f "$GCP_SA" ]; then
  SA_MOUNT=(-v "$GCP_SA:/root/gcp-sa.json:ro")
  SA_ENV=(-e GOOGLE_APPLICATION_CREDENTIALS="/root/gcp-sa.json")
fi

udocker_check 2>/dev/null
udocker_prune 2>/dev/null
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

_ADK_ENV=(
  -e _PORT="$PORT"
  -e TZ="$(get_tz 2>/dev/null)"
  -e GOOGLE_GENAI_USE_VERTEXAI="$VERTEX_FLAG"
  -e GOOGLE_API_KEY="$GEMINI_KEY"
  -e GOOGLE_CLOUD_PROJECT="$GCP_PROJECT"
  -e PROJECT_ID="$GCP_PROJECT"
  -e GOOGLE_CLOUD_LOCATION="$GCP_LOCATION"
  -e LOCATION="$GCP_LOCATION"
  "${SA_ENV[@]}"
)

# Install snippet: clone sample (sparse) + pip install deps
read -r -d '' _ADK_INSTALL <<'INSTALL'
set -e
export DEBIAN_FRONTEND=noninteractive
AGENT_DIR=/root/invoice-processing

if [ ! -d "$AGENT_DIR/invoice_processing" ]; then
  echo "[*] Installing git + build deps..."
  apt-get update -qq
  apt-get install -y --no-install-recommends git curl ca-certificates build-essential >/dev/null 2>&1 || true

  echo "[*] Cloning google/adk-samples (sparse: invoice-processing)..."
  rm -rf /root/adk-samples
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/google/adk-samples /root/adk-samples
  git -C /root/adk-samples sparse-checkout set python/agents/invoice-processing
  cp -a /root/adk-samples/python/agents/invoice-processing "$AGENT_DIR"
  rm -rf /root/adk-samples
fi

# Write .env from container env if missing
if [ ! -f "$AGENT_DIR/.env" ]; then
  cat > "$AGENT_DIR/.env" <<EOF
GOOGLE_GENAI_USE_VERTEXAI=${GOOGLE_GENAI_USE_VERTEXAI}
GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
PROJECT_ID=${PROJECT_ID}
LOCATION=${LOCATION}
GOOGLE_API_KEY=${GOOGLE_API_KEY}
EOF
fi

if ! python3 -c "import google.adk" >/dev/null 2>&1; then
  echo "[*] Installing Python deps (google-adk, vertexai, pdfplumber...)"
  pip install --upgrade pip -q
  pip install -q \
    "google-adk>=1.0.0" "google-cloud-aiplatform>=1.38.0" \
    "vertexai>=1.38.0" "pydantic>=2.8.0" "pdfplumber>=0.10.0" \
    "python-dotenv>=1.0.0" "pyyaml>=6.0" 2>&1 | tail -3 || true
fi
echo "[*] ADK invoice-processing ready at $AGENT_DIR"
INSTALL

case "$1" in
  setup)
    udocker_run --entrypoint "bash -c" \
      "${_ADK_ENV[@]}" "${SA_MOUNT[@]}" \
      -v "$DATA_DIR/root:/root" -u root "$CONTAINER_NAME" "$_ADK_INSTALL"
    ;;

  version)
    udocker_run --entrypoint "bash -c" \
      "${_ADK_ENV[@]}" -v "$DATA_DIR/root:/root" -u root "$CONTAINER_NAME" \
      'python3 -c "import google.adk as a; print(\"google-adk\", getattr(a,\"__version__\",\"installed\"))" 2>/dev/null || echo "[!] Not installed. Run: setup"'
    ;;

  shell)
    udocker_run --entrypoint "bash" \
      "${_ADK_ENV[@]}" "${SA_MOUNT[@]}" \
      -v "$DATA_DIR/root:/root" -u root "$CONTAINER_NAME"
    ;;

  cli)
    udocker_run --entrypoint "bash -c" \
      "${_ADK_ENV[@]}" "${SA_MOUNT[@]}" \
      -v "$DATA_DIR/root:/root" -u root "$CONTAINER_NAME" "
        $_ADK_INSTALL
        cd /root/invoice-processing
        exec adk run invoice_processing
      "
    ;;

  run|web|"")
    echo -e "\n${YELLOW}[*] Starting ADK Invoice-Processing (adk web)...${RESET}"
    [ -z "$GCP_PROJECT" ] && echo -e "${DIM}    (No GCP project set — configure via Google Project → Provider GCP)${RESET}"
    udocker_run --entrypoint "bash -c" -p "${PORT}:${PORT}" \
      "${_ADK_ENV[@]}" "${SA_MOUNT[@]}" \
      -v "$DATA_DIR/root:/root" -u root "$CONTAINER_NAME" "
        $_ADK_INSTALL
        cd /root/invoice-processing
        echo ''
        echo '[*] ADK Web ready!'
        echo \"[*] Open:  http://localhost:\$_PORT\"
        echo '[*] Pilih agent: invoice_processing'
        echo ''
        exec adk web --host 0.0.0.0 --port \"\$_PORT\"
      "
    ;;

  *)
    echo ""
    echo "  📄 ADK Invoice-Processing — Google ADK"
    echo ""
    echo "  adk-invoice setup      Clone sample + install deps"
    echo "  adk-invoice run        Start adk web UI (default)"
    echo "  adk-invoice cli        Run in terminal (adk run)"
    echo "  adk-invoice version    Show google-adk version"
    echo "  adk-invoice shell      Enter container"
    echo ""
    echo "  GCP config: Google Project → Provider GCP (~/.hermes_keys)"
    echo ""
    ;;
esac

exit $?
