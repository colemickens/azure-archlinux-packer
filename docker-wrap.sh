#/usr/bin/env bash

set -x
set -eu -o pipefail

CMD="${1:-"/bin/bash"}"

IMAGE="azure-archlinux-packer"
docker build --pull -f Dockerfile -t "${IMAGE}" .
docker run -it --rm \
  --privileged \
  --net=host \
  --volume='/dev/kvm:/dev/kvm' \
  --volume='/var/lib/packer/cache:/var/lib/packer/cache' \
  --volume="$(pwd):/azure-archlinux-packer" \
  --volume="${HOME}/.ssh:/root/.ssh" \
  --workdir="/azure-archlinux-packer" \
  --env-file="user.env" \
  --env=USERNAME="$(whoami)" \
    "${IMAGE}" \
        "${CMD}"
