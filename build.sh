#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

###############################################################################

ARCHLINUX_VERSION="${ARCHLINUX_VERSION:-"2016.10.01"}"
ARCH_ISO_SHA256="${ARCH_ISO_SHA256:-"3d2556b2c5ae1fea555c64f0790b728afa0ad7184d5b2742a06e1a29b2d857c2"}"
ARCH_ISO_URL="${ARCH_ISO_URL:-"http://mirrors.kernel.org/archlinux/iso/${ARCHLINUX_VERSION}/archlinux-${ARCHLINUX_VERSION}-dual.iso"}"
IMAGE_NAME="${IMAGE_NAME:-"archlinux-${ARCHLINUX_VERSION}-azure"}"
DISK_SIZE="${DISK_SIZE:-"30000"}"

set -eu
set -x

if [[ "${ENABLE_PACMAN_CACHE:-}" == "y" ]]; then
  IP="$(hostname -i)"
  IP="${IP%"${IP##*[![:space:]]}"}"
  SUFFIX='archlinux/$repo/os/$arch'
  PACMAN_CACHE="http://${IP}:8080/${SUFFIX}"
fi

mkdir -p "${DIR}/_output"

# Run Packer, let it do everything basically
export PACKER_LOG=1
export PACKER_CACHE_DIR="/var/lib/packer/cache"
export PACKER_LOG_PATH="${DIR}/_output/packer.log"
packer build \
  --var pacman_cache="${PACMAN_CACHE:-}" \
  --var arch_iso_url="${ARCH_ISO_URL:-}" \
  --var arch_iso_sha256="${ARCH_ISO_SHA256:-}" \
  --var pacman_cache="${PACMAN_CACHE:-}" \
  --var disk_size="${DISK_SIZE:-}" \
  packer.json
