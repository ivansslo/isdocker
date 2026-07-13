#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Created by: ivansslo (2026)
#  License: MIT
#  Repo: https://github.com/ivansslo/roc-containers
# ─────────────────────────────────────────────────────────────────
#  roc-containers · ROS 2 Jazzy (Robot Operating System)
#  Image : ghcr.io/sloretz/ros:jazzy-ros-base
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="ghcr.io/sloretz/ros:jazzy-ros-base"
CONTAINER_NAME="ros-base"

DATA_DIR="$(pwd)/../../data-$CONTAINER_NAME"
mkdir -p "$DATA_DIR/workspace"

udocker_check
udocker_prune
udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

_LIBNETSTUB_VOL="-v $(proot_write_tmp "$(cat "$(pwd)/../../lib/libnetstub.sh")")":/.libnetstub/libnetstub.sh

if [ -n "$1" ]; then
  cmd="$*"
  udocker_run $_LIBNETSTUB_VOL \
    -v "$DATA_DIR/workspace:/ros_ws" \
    "$CONTAINER_NAME" bash -c ". /.libnetstub/libnetstub.sh; $cmd"
else
  udocker_run --entrypoint "bash -c" \
    $_LIBNETSTUB_VOL \
    -v "$DATA_DIR/workspace:/ros_ws" \
    "$CONTAINER_NAME" '
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts
      if [[ ! -f /.libnetstub/libnetstub.so && -f /.libnetstub/libnetstub.sh ]]; then
          mkdir -p /.libnetstub
          echo ". /.libnetstub/libnetstub.sh" | tee -a ~/.bashrc ~/.zshrc >/dev/null
          . /.libnetstub/libnetstub.sh
      fi
      . /.libnetstub/libnetstub.sh
      exec /ros_entrypoint.sh bash
    '
fi

exit $?
