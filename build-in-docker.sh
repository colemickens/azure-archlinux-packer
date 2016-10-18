#/usr/bin/env bash

set -x
set -eu -o pipefail

ARCHLINUX_VERSION="2016.10.01"
ARCH_ISO_SHA256="3d2556b2c5ae1fea555c64f0790b728afa0ad7184d5b2742a06e1a29b2d857c2"
ARCH_ISO_URL="http://mirrors.kernel.org/archlinux/iso/${ARCHLINUX_VERSION}/archlinux-${ARCHLINUX_VERSION}-dual.iso"
IMAGE_NAME="archlinux-${ARCHLINUX_VERSION}-azure"
DISK_SIZE="30000"

IMAGE="azure-archlinux-packer"
CMD="./build.sh"
DOCKER_ARGS=()
if [[ "${DEV:-}" == "y" ]]; then
  CMD="/bin/bash"
  DOCKER_ARGS+=(--volume="$(pwd):/azure-archlinux-packer")
else
  DOCKER_ARGS+=(--volume="$(pwd)/_output:/azure-archlinux-packer/_output")
fi

docker_args=()

docker build --pull -f Dockerfile -t "${IMAGE}" .
docker run -it --rm \
  --privileged \
  --net=host \
  --volume='/dev/kvm:/dev/kvm' \
  --volume='/var/lib/packer/cache:/var/lib/packer/cache' \
  ${DOCKER_ARGS[@]} \
  --env=ENABLE_PACMAN_CACHE="${ENABLE_PACMAN_CACHE:-}" \
  --env=ARCH_ISO_URL="${ARCH_ISO_URL}" \
  --env=ARCH_ISO_SHA256="${ARCH_ISO_SHA256}" \
  --env=DISK_SIZE="${DISK_SIZE}" \
  --env-file="user.env" \
  --env=IMAGE_NAME="${IMAGE_NAME}" \
    "${IMAGE}" "${CMD:-"./build.sh"}"

