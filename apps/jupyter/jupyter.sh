#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · JupyterLab / Notebook
#  Image : quay.io/jupyter/base-notebook:latest
#  Port  : 8888
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="quay.io/jupyter/base-notebook"
CONTAINER_NAME="jupyter-server"

case $PORT in
  ''|*[!0-9]*) PORT=8888 ;;
  *) [ "$PORT" -gt 1023 ] && [ "$PORT" -lt 65536 ] || PORT=8888 ;;
esac

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/notebooks"

_LIBNETSTUB_VOL="-v $(proot_write_tmp "$(cat "$(pwd)/../../lib/libnetstub.sh")")":/.libnetstub/libnetstub.sh

if [ -n "$1" ]; then
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "${PORT}:8888" \
    -e JUPYTER_PORT="$PORT" \
    $_LIBNETSTUB_VOL \
    -v "$DATA_DIR/notebooks:/home/certve" \
    "$CONTAINER_NAME" ". /.libnetstub/libnetstub.sh; $cmd"
else
  # First pass: compile libnetstub
  udocker_run --entrypoint "bash -c" -p "${PORT}:8888" \
    -e JUPYTER_PORT="$PORT" \
    $_LIBNETSTUB_VOL \
    -v "$DATA_DIR/notebooks:/home/certve" \
    -u root "$CONTAINER_NAME" '
      if [[ ! -f /.libnetstub/libnetstub.so && -f /.libnetstub/libnetstub.sh ]]; then
          export DEBIAN_FRONTEND=noninteractive
          apt update && apt install -y dialog apt-utils
          apt install -y --no-install-recommends gcc libc6-dev
          mkdir -p /.libnetstub
          echo ". /.libnetstub/libnetstub.sh" | tee -a ~/.bashrc ~/.zshrc >/dev/null
          . /.libnetstub/libnetstub.sh
          apt remove -y gcc libc6-dev && apt clean -y && apt autoclean -y
      fi
    '
  # Second pass: start Jupyter
  udocker_run --entrypoint "bash -c" -p "${PORT}:8888" \
    -e JUPYTER_PORT="$PORT" \
    $_LIBNETSTUB_VOL \
    -v "$DATA_DIR/notebooks:/home/certve" \
    "$CONTAINER_NAME" '
      . /.libnetstub/libnetstub.sh
      exec tini -s -g -- start.sh start-notebook.py
    '
fi

exit $?
