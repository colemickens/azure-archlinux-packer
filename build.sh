#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

###############################################################################

ARCHLINUX_VERSION="${ARCHLINUX_VERSION:-"2017.07.01"}"
ARCH_ISO_SHA1="${ARCH_ISO_SHA1:-"dd03d811211c332d29155069d8e4bb2306c70f33"}"
ARCH_ISO_URL="${ARCH_ISO_URL:-"http://mirrors.kernel.org/archlinux/iso/${ARCHLINUX_VERSION}/archlinux-${ARCHLINUX_VERSION}-x86_64.iso"}"
IMAGE_NAME="${IMAGE_NAME:-"archlinux-${ARCHLINUX_VERSION}-azure"}"
DISK_SIZE="${DISK_SIZE:-"30000"}"

set -eu
set -x

if [[ "${ENABLE_PACMAN_CACHE:-}" == "y" ]]; then
  #IP="$(hostname -i)"
  #IP="${IP%"${IP##*[![:space:]]}"}"
  #IP=172.17.0.1
  IP=10.0.0.2
  SUFFIX='archlinux/$repo/os/$arch'
  PACMAN_CACHE="http://${IP}:8080/${SUFFIX}"
fi

mkdir -p "${DIR}/_output"

# Run Packer, let it do everything basically
export PACKER_LOG=1
export PACKER_CACHE_DIR="/var/lib/packer/cache"
export PACKER_LOG_PATH="${DIR}/_output/packer.log"
packer build \
  --var arch_iso_url="${ARCH_ISO_URL:-}" \
  --var arch_iso_sha1="${ARCH_ISO_SHA1:-}" \
  --var pacman_cache="${PACMAN_CACHE:-}" \
  --var disk_size="${DISK_SIZE:-}" \
  packer.json
