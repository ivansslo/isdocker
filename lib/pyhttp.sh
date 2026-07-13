#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Python HTTP Server (Termux host, port 3000)
#  Menyajikan sebuah folder lewat `python -m http.server`.
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/source.env" 2>/dev/null

# Colors (fallback if not inherited from menu.sh)
: "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${DIM:=$'\033[2m'}"
: "${RED:=$'\033[0;31m'}"; : "${BOLD:=$'\033[1m'}"; : "${RESET:=$'\033[0m'}"

PORT="${PORT:-3000}"
case $PORT in
  ''|*[!0-9]*) PORT=3000 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=3000 ;;
esac

# Pastikan python ada
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
  echo -e "${YELLOW}[*] Menginstall python...${RESET}"
  pkg install -y python
fi
PY="$(command -v python3 || command -v python)"

# Folder yang akan disajikan (default: ~/www)
DEFAULT_DIR="$HOME/www"
echo -en "\n  ${CYAN}Folder yang disajikan (Enter = $DEFAULT_DIR): ${RESET}"
read -r SERVE_DIR
[ -z "$SERVE_DIR" ] && SERVE_DIR="$DEFAULT_DIR"
mkdir -p "$SERVE_DIR"

# Buat index.html contoh jika folder kosong
if [ -z "$(ls -A "$SERVE_DIR" 2>/dev/null)" ]; then
  cat > "$SERVE_DIR/index.html" <<'HTML'
<!doctype html><meta charset="utf-8">
<title>roc-containers · Python HTTP</title>
<body style="font-family:sans-serif;background:#111;color:#eee;text-align:center;padding:3rem">
<h1>🐍 roc-containers Python HTTP Server</h1>
<p>Folder ini disajikan oleh <code>python -m http.server</code>.</p>
<p>Ganti isi folder untuk menyajikan file Anda sendiri.</p>
</body>
HTML
fi

LANIP="$(ip route get 1 2>/dev/null | awk '{print $7; exit}')"
[ -z "$LANIP" ] && LANIP="127.0.0.1"

echo ""
echo -e "  ${GREEN}[*] Python HTTP Server berjalan!${RESET}"
echo -e "  ${DIM}Folder : $SERVE_DIR${RESET}"
echo -e "  ${DIM}Lokal  : http://localhost:$PORT${RESET}"
echo -e "  ${DIM}LAN    : http://$LANIP:$PORT${RESET}"
echo -e "  ${DIM}(Tekan Ctrl-C untuk berhenti)${RESET}"
echo ""

cd "$SERVE_DIR" || exit 1
exec "$PY" -m http.server "$PORT" --bind 0.0.0.0
