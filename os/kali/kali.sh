#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Kali Linux (minimal)
#  Image : kalilinux/kali-rolling
#  Port  : 2222 (SSH)
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="kalilinux/kali-rolling"
CONTAINER_NAME="kali-linux"

case $PORT in
  ''|*[!0-9]*) PORT=2222 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=2222 ;;
esac

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/root"

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "${PORT}:22" -e TZ="$(get_tz)" \
    -v "$DATA_DIR/root:/root" "$CONTAINER_NAME" "$cmd"
else
  # VNC desktop mode has been removed from this build — SSH server only.

  udocker_run --entrypoint "bash -c" -p "${PORT}:22" \
    -e _PORT="$PORT" -e TZ="$(get_tz)" \
    -v "$DATA_DIR/root:/root" \
    "$CONTAINER_NAME" '
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq
      apt-get install -y --no-install-recommends openssh-server sudo curl wget git 2>/dev/null || true
      mkdir -p /run/sshd
      ssh-keygen -A &>/dev/null
      sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/" \
              -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/" \
              -e "s/PasswordAuthentication no/PasswordAuthentication yes/" \
              /etc/ssh/sshd_config
      echo "root:kali" | chpasswd
      echo ""
      echo "[*] Kali Linux ready — ssh root@localhost -p '"'"'$_PORT'"'"'  (pass: kali)"
      echo ""
      exec /usr/sbin/sshd -D -p "$_PORT"
    '
fi

exit $?
