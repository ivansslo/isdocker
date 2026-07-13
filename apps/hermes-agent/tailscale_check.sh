#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Hermes Agent ⇄ Tailscale — cek kecocokan CLI
#
#  Menjawab: "apakah CLI tailscale bisa cocok" dengan container agent.
#  Skrip ini:
#    1. Mengecek apakah `tailscale` bisa diinstall & jalan di container
#       python:3.12-slim (arsitektur, userspace-networking, dependency).
#    2. Menjalankan `tailscale version` + `tailscale --help` sebagai bukti.
#    3. Mengecek apakah node Tailscale yang sudah ada (dari menu CLI [2])
#       bisa dijangkau oleh agent (berbagi state).
#
#  Dipanggil oleh: hermes-agent.sh tailscale
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null

: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${BOLD:=$'\033[1m'}"
: "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

CONTAINER_NAME="${1:-hermes-agent}"
DATA_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/data-hermes-agent}"
TS_STATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/data-tailscale-node/state"

clear
echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
echo    "  ║     Hermes Agent ⇄ Tailscale · Cek Kecocokan CLI    ║"
echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
echo -e "  ${DIM}Menguji apakah CLI Tailscale cocok dengan container agent${RESET}\n"

ARCH="$(uname -m)"
echo -e "  ${CYAN}[1] Arsitektur host:${RESET} $ARCH"
case "$ARCH" in
  aarch64|arm64) echo -e "      ${GREEN}✓ Tailscale menyediakan build arm64 — cocok.${RESET}" ;;
  x86_64|amd64)  echo -e "      ${GREEN}✓ Tailscale menyediakan build amd64 — cocok.${RESET}" ;;
  *)             echo -e "      ${YELLOW}! Arsitektur '$ARCH' — cek https://pkgs.tailscale.com${RESET}" ;;
esac
echo ""

# Skrip instalasi+uji tailscale DI DALAM container python:3.12-slim (Debian based)
read -r -d '' _TS_TEST <<'TST'
set +e
export DEBIAN_FRONTEND=noninteractive
echo "  [2] Menyiapkan Tailscale CLI di container (Debian/slim)..."
if ! command -v tailscale >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y --no-install-recommends curl ca-certificates gnupg >/dev/null 2>&1
  # python:3.12-slim = Debian 12 (bookworm)
  curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg 2>/dev/null
  curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list \
    -o /etc/apt/sources.list.d/tailscale.list 2>/dev/null
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y tailscale >/dev/null 2>&1
fi

if command -v tailscale >/dev/null 2>&1; then
  echo "      ✓ Tailscale CLI terpasang & DAPAT DIJALANKAN di container agent."
  echo -n "      version: "; tailscale version 2>/dev/null | head -1
  echo "  [3] Cek subcommand penting (up/status/ip)..."
  tailscale --help 2>&1 | grep -Eq '(^|\s)up(\s|$)'     && echo "      ✓ 'tailscale up' tersedia"
  tailscale --help 2>&1 | grep -Eq '(^|\s)status(\s|$)' && echo "      ✓ 'tailscale status' tersedia"
  tailscale --help 2>&1 | grep -Eq '(^|\s)ip(\s|$)'     && echo "      ✓ 'tailscale ip' tersedia"

  echo "  [4] Mode jaringan: userspace-networking (tanpa /dev/net/tun)"
  if [ -e /dev/net/tun ]; then
    echo "      ✓ /dev/net/tun ADA — mode kernel tersedia (jarang di udocker)."
  else
    echo "      ! /dev/net/tun TIDAK ADA (normal di udocker/Termux)."
    echo "        → gunakan: tailscaled --tun=userspace-networking (didukung penuh)."
  fi

  # Cek apakah state node dari menu CLI [2] ada (login bisa dibagikan)
  if [ -f /var/lib/tailscale/tailscaled.state ]; then
    echo "  [5] State node Tailscale ditemukan (login bisa dibagikan)."
    tailscaled --tun=userspace-networking \
      --state=/var/lib/tailscale/tailscaled.state \
      --socket=/var/run/tailscale/tailscaled.sock >/tmp/tsd.log 2>&1 &
    sleep 3
    echo -n "      status: "; tailscale status 2>/dev/null | head -3 || echo "(belum login)"
  else
    echo "  [5] Belum ada state login (jalankan menu CLI → [2] Tailscale, atau login di sini)."
  fi
  echo ""
  echo "  ==> HASIL: CLI Tailscale COCOK dengan container Hermes Agent."
  echo "      Agent dapat memanggil 'tailscale' via tool run_shell."
else
  echo "      ✗ Gagal memasang Tailscale CLI (cek koneksi / arsitektur)."
  echo "  ==> HASIL: Tidak cocok pada kondisi saat ini."
fi
TST

# Mount state node Tailscale yang sudah ada (bila tersedia) agar login dibagi.
TS_STATE_MOUNT=()
if [ -d "$TS_STATE" ]; then
  TS_STATE_MOUNT=(-v "$TS_STATE:/var/lib/tailscale")
  echo -e "  ${DIM}(Berbagi state login dari data-tailscale-node)${RESET}\n"
else
  mkdir -p "$DATA_DIR/tailscale-state"
  TS_STATE_MOUNT=(-v "$DATA_DIR/tailscale-state:/var/lib/tailscale")
fi

udocker_run --entrypoint "bash -c" \
  -u root \
  -v "$DATA_DIR/root:/root" \
  "${TS_STATE_MOUNT[@]}" \
  -e HOME="/root" \
  "$CONTAINER_NAME" "$_TS_TEST"

echo ""
echo -e "  ${DIM}Ringkasan: python:3.12-slim = Debian bookworm → repo resmi${RESET}"
echo -e "  ${DIM}Tailscale mendukung apt install + userspace-networking, sama${RESET}"
echo -e "  ${DIM}seperti app Tailscale roc-containers (menu CLI [2]). Jadi CLI cocok.${RESET}"
