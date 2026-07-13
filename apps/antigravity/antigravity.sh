#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Antigravity (Google AI IDE) — Web Server mode
#  Image : python:3.12-slim   (same base family as crewai/hermes)
#  Arch  : linux-arm (aarch64)  ·  Antigravity 2.2.1
#
#  Antigravity is an Electron/VSCode-based IDE. Instead of a GUI/VNC,
#  we run it HEADLESS via `antigravity serve-web`, which exposes the
#  editor UI over HTTP so you open it in a browser (like code-server).
#
#  Subcommands (hermes-style):
#     setup      Download + extract Antigravity + runtime deps
#     run|serve  Start the web server (default)
#     version    Print binary path / version
#     shell      Enter the container shell
#
#  Provider credentials come from ~/.hermes_keys (menu → Provider GCP).
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"

# Colors (fallback if not inherited from menu.sh)
: "${YELLOW:=$'\033[1;33m'}"; : "${GREEN:=$'\033[0;32m'}"
: "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

IMAGE_NAME="python:3.12-slim"
CONTAINER_NAME="antigravity-hermes"

# Antigravity linux-arm tarball (aarch64 build), overridable via env
AG_URL="${AG_URL:-https://storage.googleapis.com/antigravity-public/antigravity-hub/2.2.1-5287492581195776/linux-arm/Antigravity.tar.gz}"

# ── Port (serve-web) ────────────────────────────────────────────
case $PORT in
  ''|*[!0-9]*) PORT=5905 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=5905 ;;
esac

# ── Provider credentials from ~/.hermes_keys ────────────────────
GEMINI_KEY="$(grep -E '^GEMINI_API_KEY=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GOOGLE_KEY="$(grep -E '^GOOGLE_API_KEY=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_PROJECT="$(grep -E '^GCP_PROJECT=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
GCP_LOCATION="$(grep -E '^GCP_LOCATION=' ~/.hermes_keys 2>/dev/null | cut -d= -f2-)"
[ -z "$GEMINI_KEY" ] && GEMINI_KEY="$GOOGLE_KEY"
[ -z "$GCP_LOCATION" ] && GCP_LOCATION="us-central1"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root" "$DATA_DIR/projects"

udocker_check 2>/dev/null
udocker_prune 2>/dev/null
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

# Common env passed into every run (provider config + Electron/crypto fixes)
_AG_ENV=(
  -e AG_URL="$AG_URL"
  -e _PORT="$PORT"
  -e TZ="$(get_tz 2>/dev/null)"
  -e GEMINI_API_KEY="$GEMINI_KEY"
  -e GOOGLE_API_KEY="$GEMINI_KEY"
  -e GOOGLE_CLOUD_PROJECT="$GCP_PROJECT"
  -e GOOGLE_CLOUD_LOCATION="$GCP_LOCATION"
  # RDRAND/BoringCrypto workaround (safe on emulated/proot CPUs)
  -e OPENSSL_ia32cap="~0x4000000000000000"
  -e ELECTRON_DISABLE_SANDBOX="1"
)

# Shell snippet: install runtime deps + fetch Antigravity if missing.
read -r -d '' _AG_INSTALL <<'INSTALL'
set -e
export DEBIAN_FRONTEND=noninteractive
AG_HOME=/opt/antigravity
AG_BIN="$AG_HOME/antigravity"

# Runtime deps are (re)checked every run so xvfb/xauth/dbus exist even on
# containers created by an older version of this script. A marker file
# skips the slow apt path once everything is present.
if [ ! -f /opt/.ag_deps_ok ] || [ ! -x /usr/bin/xvfb-run ]; then
  echo "[*] Installing runtime dependencies (X virtual display, GTK, etc.)..."
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    curl wget ca-certificates tar xz-utils \
    libnss3 libgtk-3-0 libgbm1 libasound2 libx11-xcb1 \
    libxcomposite1 libxdamage1 libxrandr2 libxkbfile1 \
    libsecret-1-0 libnotify4 fonts-liberation \
    libatk-bridge2.0-0 libatspi2.0-0 libcups2 \
    libdrm2 libxshmfence1 xvfb xauth dbus-x11 >/dev/null 2>&1 || true
  [ -x /usr/bin/xvfb-run ] && touch /opt/.ag_deps_ok
fi

if [ ! -x "$AG_BIN" ]; then
  echo "[*] Downloading Antigravity (linux-arm ~160MB)..."
  mkdir -p /root/ag-tmp "$AG_HOME"
  cd /root/ag-tmp
  wget -q -O Antigravity.tar.gz "$AG_URL" || curl -L -o Antigravity.tar.gz "$AG_URL"

  echo "[*] Extracting..."
  tar -xzf Antigravity.tar.gz
  SRCDIR="$(find /root/ag-tmp -maxdepth 1 -type d -iname 'Antigravity*' | head -n1)"
  [ -z "$SRCDIR" ] && SRCDIR="/root/ag-tmp"
  cp -a "$SRCDIR"/. "$AG_HOME"/ 2>/dev/null || true
  rm -rf /root/ag-tmp

  # Chromium sandbox helper must be setuid-root OR we run --no-sandbox.
  chmod 4755 "$AG_HOME/chrome-sandbox" 2>/dev/null || true
  chmod +x "$AG_BIN" 2>/dev/null || true
  ln -sf "$AG_BIN" /usr/local/bin/antigravity 2>/dev/null || true
  echo "[*] Installed at $AG_BIN"
fi
INSTALL

case "$1" in
  setup)
    udocker_run --entrypoint "bash -c" \
      "${_AG_ENV[@]}" \
      -v "$DATA_DIR/root:/root" \
      -u root "$CONTAINER_NAME" "$_AG_INSTALL"
    ;;

  version)
    udocker_run --entrypoint "bash -c" \
      "${_AG_ENV[@]}" -v "$DATA_DIR/root:/root" -u root \
      "$CONTAINER_NAME" '
        AG=/opt/antigravity/antigravity
        [ -x "$AG" ] && "$AG" --version --no-sandbox 2>/dev/null || echo "[!] Not installed yet. Run: antigravity setup"
      '
    ;;

  shell)
    udocker_run --entrypoint "bash" \
      "${_AG_ENV[@]}" -v "$DATA_DIR/root:/root" \
      -v "$DATA_DIR/projects:/projects" -u root "$CONTAINER_NAME"
    ;;

  run|serve|"")
    echo -e "\n${YELLOW}[*] Starting Antigravity Web Server...${RESET}"
    [ -z "$GEMINI_KEY" ] && echo -e "${DIM}    (No GCP/Gemini key set — configure via menu → Provider GCP)${RESET}"
    udocker_run --entrypoint "bash -c" -p "${PORT}:${PORT}" \
      "${_AG_ENV[@]}" \
      -v "$DATA_DIR/root:/root" \
      -v "$DATA_DIR/projects:/projects" \
      -u root "$CONTAINER_NAME" "
        $_AG_INSTALL
        AG=/opt/antigravity/antigravity

        # Try to raise inotify limits (harmless if read-only in proot)
        echo 524288 > /proc/sys/fs/inotify/max_user_watches 2>/dev/null || true

        # Start a private D-Bus session (silences dbus errors)
        if command -v dbus-launch >/dev/null 2>&1; then
          eval \"\$(dbus-launch --sh-syntax 2>/dev/null)\" || true
        fi

        echo ''
        echo '[*] Antigravity Web ready!'
        echo \"[*] Open:  http://localhost:\$_PORT\"
        echo '[*] If a login/OAuth URL is printed below, open it on your phone browser.'
        echo ''

        # Antigravity/Electron still needs an X display even for serve-web,
        # so we run it under a virtual framebuffer (Xvfb) via xvfb-run.
        export DISPLAY=:99
        exec xvfb-run -a -s '-screen 0 1360x768x24 -nolisten tcp' \
          \"\$AG\" serve-web \
            --host 0.0.0.0 --port \"\$_PORT\" \
            --without-connection-token \
            --accept-server-license-terms \
            --no-sandbox --disable-gpu /projects
      "
    ;;

  *)
    echo ""
    echo "  🚀 Antigravity — Google AI IDE (Web mode)"
    echo ""
    echo "  antigravity setup        Install / download Antigravity"
    echo "  antigravity run          Start web server (default)"
    echo "  antigravity version      Show version"
    echo "  antigravity shell        Enter container"
    echo ""
    echo "  Provider config: menu → 'Provider GCP' (saves to ~/.hermes_keys)"
    echo ""
    ;;
esac

exit $?
