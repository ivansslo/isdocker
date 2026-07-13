#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · Redis
#  Image : redis:latest
#  Port  : 6379
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="redis"
CONTAINER_NAME="redis-server"

case $PORT in
  ''|*[!0-9]*) PORT=6379 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=6379 ;;
esac

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/data"

if [ -n "$1" ]; then
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "${PORT}:6379" \
    -v "$DATA_DIR/data:/data" \
    "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c" -p "${PORT}:6379" \
    -e _PORT="$PORT" \
    -v "$DATA_DIR/data:/data" \
    "$CONTAINER_NAME" '
      exec redis-server --port "$_PORT" --save 60 1 --loglevel notice
    '
fi

exit $?
