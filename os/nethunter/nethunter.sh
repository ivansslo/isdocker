#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Kali NetHunter
#  Image : kalilinux/kali-rolling (official Kali Linux)
#  Port  : 2222 (SSH)  |  5900 (VNC/noVNC optional)
#  Usage : bash ~/.roc-containers/os/nethunter/nethunter.sh
#          PORT=2223 bash ~/.roc-containers/os/nethunter/nethunter.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="kalilinux/kali-rolling"
CONTAINER_NAME="kali-nethunter"

case $PORT in
  ''|*[!0-9]*) PORT=2222 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=2222 ;;
esac

VNC_PORT="${VNC_PORT:-5900}"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR"/{root,home,tools}

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  cmd="$*"
  udocker_run \
    --entrypoint "bash -c" \
    -p "${PORT}:22" \
    -e TZ="$(get_tz)" \
    -v "$DATA_DIR/root:/root" \
    -v "$DATA_DIR/home:/home" \
    -v "$DATA_DIR/tools:/opt/nethunter-tools" \
    -v "$(proot_write_tmp "$(cat "$(pwd)/../../lib/libnetstub.sh")")":/.libnetstub/libnetstub.sh \
    "$CONTAINER_NAME" \
    ". /.libnetstub/libnetstub.sh; $cmd"
else
  # VNC desktop mode has been removed from this build — SSH server only.

  udocker_run \
    --entrypoint "bash -c" \
    -p "${PORT}:22" \
    -p "${VNC_PORT}:5900" \
    -e _PORT="$PORT" \
    -e _VNC_PORT="$VNC_PORT" \
    -e TZ="$(get_tz)" \
    -v "$DATA_DIR/root:/root" \
    -v "$DATA_DIR/home:/home" \
    -v "$DATA_DIR/tools:/opt/nethunter-tools" \
    -v "$(proot_write_tmp "$(cat "$(pwd)/../../lib/libnetstub.sh")")":/.libnetstub/libnetstub.sh \
    -v "$(mktemp):/proc/sys/net/ipv4/ip_forward" \
    "$CONTAINER_NAME" '
      # /etc/hosts
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters" >/etc/hosts

      # libnetstub
      if [[ ! -f /.libnetstub/libnetstub.so && -f /.libnetstub/libnetstub.sh ]]; then
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y --no-install-recommends gcc libc6-dev
          mkdir -p /.libnetstub
          echo ". /.libnetstub/libnetstub.sh" | tee -a ~/.bashrc ~/.zshrc >/dev/null
          . /.libnetstub/libnetstub.sh
          apt-get remove -y gcc libc6-dev && apt-get autoremove -y && apt-get clean -y
      fi
      . /.libnetstub/libnetstub.sh

      export DEBIAN_FRONTEND=noninteractive
      echo "[*] Updating package lists..."
      apt-get update -qq

      # ── Install core NetHunter tools ─────────────────────────
      echo "[*] Installing NetHunter base packages..."
      apt-get install -y --no-install-recommends \
          kali-linux-headless \
          openssh-server \
          sudo \
          curl wget git \
          net-tools iproute2 iputils-ping dnsutils \
          nmap masscan \
          metasploit-framework \
          aircrack-ng \
          hydra \
          john \
          sqlmap \
          nikto \
          wifite \
          hashcat \
          wordlists \
          python3 python3-pip \
          ruby \
          2>/dev/null || true

      # ── SSH setup ─────────────────────────────────────────────
      mkdir -p /run/sshd /var/run/sshd
      ssh-keygen -A &>/dev/null

      # Allow root login & password auth
      sed -i \
          -e "s/#PermitRootLogin.*/PermitRootLogin yes/" \
          -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/" \
          -e "s/PasswordAuthentication no/PasswordAuthentication yes/" \
          -e "s/#Port 22/Port $_PORT/" \
          /etc/ssh/sshd_config

      # Default root password (change after first login!)
      echo "root:nethunter" | chpasswd

      echo ""
      echo "╔══════════════════════════════════════════════════════╗"
      echo "║          Kali NetHunter · roc-containers                  ║"
      echo "╠══════════════════════════════════════════════════════╣"
      echo "║  SSH  → ssh root@localhost -p '"'"'$_PORT'"'"'              ║"
      echo "║  Pass → nethunter  (change with: passwd root)        ║"
      echo "║  Tools directory: /opt/nethunter-tools               ║"
      echo "╚══════════════════════════════════════════════════════╝"
      echo ""

      exec /usr/sbin/sshd -D -p "$_PORT"
    '
fi

exit $?
