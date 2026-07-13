#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Tailscale (dalam container udocker)
#  Image : ubuntu:22.04
#
#  Tailscale sering gagal di Termux HOST (butuh TUN/permission Android).
#  Di sini dijalankan sebagai NODE mandiri di dalam container udocker
#  dengan userspace-networking (tanpa /dev/net/tun), jadi lebih stabil.
#
#  Submenu:
#     1) Login Auth Key (tskey-...)
#     2) Login via Browser (URL)
#     3) Status
#     4) IP saya
#     5) Logout
#     6) Shell container
# ─────────────────────────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env" 2>/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")"

# Colors (fallback if not inherited from menu.sh)
: "${RED:=$'\033[0;31m'}"; : "${GREEN:=$'\033[0;32m'}"; : "${YELLOW:=$'\033[1;33m'}"
: "${CYAN:=$'\033[0;36m'}"; : "${BLUE:=$'\033[0;34m'}"; : "${BOLD:=$'\033[1m'}"
: "${MAGENTA:=$'\033[0;35m'}"; : "${DIM:=$'\033[2m'}"; : "${RESET:=$'\033[0m'}"

IMAGE_NAME="ubuntu:22.04"
CONTAINER_NAME="tailscale-node"
HOSTNAME_TS="roc-containers-node"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/state"

udocker_check 2>/dev/null
udocker_prune 2>/dev/null
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME" 2>/dev/null

# Install Tailscale (repo resmi) — hanya jika belum ada. Dijalankan lewat
# state dir yang dipersist agar login bertahan antar-run.
read -r -d '' _TS_INSTALL <<'INSTALL'
export DEBIAN_FRONTEND=noninteractive
if ! command -v tailscale >/dev/null 2>&1; then
  echo "[*] Menginstall Tailscale (repo resmi)..."
  apt-get update -qq
  apt-get install -y --no-install-recommends curl ca-certificates gnupg >/dev/null 2>&1 || true
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list \
    | tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  apt-get update -qq
  apt-get install -y tailscale >/dev/null 2>&1 || apt-get install -y tailscale
fi
# tailscaled userspace (tanpa TUN) — cocok untuk udocker/proot
mkdir -p /var/lib/tailscale
if ! pgrep -x tailscaled >/dev/null 2>&1; then
  tailscaled --tun=userspace-networking \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock &>/var/log/tailscaled.log &
  sleep 3
fi
INSTALL

# Helper untuk menjalankan perintah di dalam container dengan state persist
ts_exec(){
  udocker_run --entrypoint "bash -c" \
    -v "$DATA_DIR/state:/var/lib/tailscale" \
    -e HOSTNAME_TS="$HOSTNAME_TS" -e TS_ARG="$1" \
    -u root "$CONTAINER_NAME" "
      $_TS_INSTALL
      $2
    "
}

while true; do
  clear
  echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════════════════╗"
  echo    "  ║        roc-containers · Tailscale (container node)         ║"
  echo -e "  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${DIM}Node mandiri di container udocker (userspace-networking)${RESET}\n"

  echo -e "  ${CYAN}[1] Login Auth Key (tskey-auth-...)"
  echo -e "  [2] Login via Browser (URL)"
  echo -e "  [3] Status"
  echo -e "  [4] IP saya (Tailscale)"
  echo -e "  [5] Logout / Disconnect"
  echo -e "  [6] Shell container"
  echo -e "  ${MAGENTA}── Advanced ──${RESET}${CYAN}"
  echo -e "  [7] Jadikan Exit Node"
  echo -e "  [8] Advertise Routes (subnet router)"
  echo -e "  [9] Reset advertise (hapus exit/route)"
  echo -e "  [0] Kembali${RESET}"
  echo ""
  echo -en "  ${BOLD}Select [0-9]: ${RESET}"
  read -r c

  case "$c" in
    1)
      echo -en "\n  Auth Key (tskey-auth-...): "; read -r key
      if [ -n "$key" ]; then
        ts_exec "" "tailscale up --authkey='$key' --hostname=\"\$HOSTNAME_TS\" --accept-routes && echo '[✓] Terhubung.' && tailscale ip -4"
      fi
      ;;
    2)
      echo -e "\n  ${YELLOW}[*] Buka URL yang muncul di browser untuk otorisasi...${RESET}\n"
      ts_exec "" "tailscale up --hostname=\"\$HOSTNAME_TS\" --accept-routes"
      ;;
    3) ts_exec "" "tailscale status || echo '[!] Belum terhubung.'" ;;
    4) ts_exec "" "tailscale ip -4 || echo '[!] Belum terhubung.'" ;;
    5) ts_exec "" "tailscale logout && echo '[✓] Logout.'" ;;
    6)
      udocker_run --entrypoint "bash -c" \
        -v "$DATA_DIR/state:/var/lib/tailscale" -u root "$CONTAINER_NAME" \
        "$_TS_INSTALL; echo; echo '[*] Shell container Tailscale. Ketik exit untuk keluar.'; exec bash"
      ;;
    7)
      echo -e "\n  ${YELLOW}[*] Mengaktifkan Exit Node...${RESET}"
      echo -e "  ${DIM}    Aktifkan IP forwarding + advertise sebagai exit node.${RESET}"
      echo -e "  ${DIM}    Setelah ini, setujui exit node di admin console Tailscale:${RESET}"
      echo -e "  ${DIM}    https://login.tailscale.com/admin/machines${RESET}\n"
      ts_exec "" "
        # IP forwarding (best-effort; userspace tetap bisa jadi exit node)
        sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
        sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1 || true
        tailscale set --advertise-exit-node 2>/dev/null \
          || tailscale up --hostname=\"\$HOSTNAME_TS\" --accept-routes --advertise-exit-node
        echo '[✓] Exit node di-advertise. Setujui di admin console.'
        tailscale status
      "
      ;;
    8)
      echo -en "\n  Subnet CIDR (mis. 192.168.1.0/24, pisah koma utk banyak): "; read -r routes
      if [ -n "$routes" ]; then
        echo -e "  ${DIM}    Setujui subnet di admin console setelah ini.${RESET}\n"
        ts_exec "" "
          sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
          sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1 || true
          tailscale set --advertise-routes='$routes' 2>/dev/null \
            || tailscale up --hostname=\"\$HOSTNAME_TS\" --accept-routes --advertise-routes='$routes'
          echo '[✓] Routes di-advertise: $routes'
          tailscale status
        "
      fi
      ;;
    9)
      echo -e "\n  ${YELLOW}[*] Menghapus advertise exit-node & routes...${RESET}"
      ts_exec "" "
        tailscale set --advertise-exit-node=false --advertise-routes= 2>/dev/null \
          || tailscale up --hostname=\"\$HOSTNAME_TS\" --accept-routes --reset
        echo '[✓] Advertise direset.'
        tailscale status
      "
      ;;
    0|q|Q) exit 0 ;;
    *) echo -e "\n  ${RED}Invalid.${RESET}"; sleep 1 ;;
  esac
  echo -en "\n  ${DIM}Press Enter...${RESET}"; read -r
done
