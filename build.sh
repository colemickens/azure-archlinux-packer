#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

###############################################################################

set -e
set -u
set -x

if [[ "${ENABLE_PACMAN_CACHE}" == "y" ]]; then
  IP="$(hostname -i)"
  IP="${IP%"${IP##*[![:space:]]}"}"
  SUFFIX='archlinux/$repo/os/$arch'
  PACMAN_CACHE="http://${IP}:8080/${SUFFIX}"
fi

FINAL_VHD_NAME="${FINAL_VHD_NAME:-"${IMAGE_NAME}-$(date +"%Y%m%d%H%M%S")"}"

echo "\$AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}"
echo "\$AZURE_TENANT_ID=${AZURE_TENANT_ID}"
echo "\$AZURE_CLIENT_ID=${AZURE_CLIENT_ID}"
echo "\$AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}"
echo "\$AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}"
echo "\$AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}"
echo "\$AZURE_STORAGE_CONTAINER=${AZURE_STORAGE_CONTAINER}"
echo "\$FINAL_VHD_NAME=${FINAL_VHD_NAME}"

###############################################################################

# Run Packer, let it do everything basically
export PACKER_LOG=1
export PACKER_CACHE_DIR="/var/lib/packer/cache"
export PACKER_LOG_PATH="_output/packer.log"
export PACKER_ARGS=()
mkdir -p _output
packer build \
  --var pacman_cache="${PACMAN_CACHE:-}" \
  --var arch_iso_url="${ARCH_ISO_URL:-}" \
  --var arch_iso_sha256="${ARCH_ISO_SHA256:-}" \
  --var pacman_cache="${PACMAN_CACHE:-}" \
  --var disk_size="${DISK_SIZE:-}" \
  packer.json

###############################################################################

# Upload: login
rm -rf ~/.azure # hope you're inside docker, oops (TODO, is there a cleaner way)
echo "n" | azure telemetry --disable
azure config mode arm
azure login \
  --service-principal \
  --tenant "${AZURE_TENANT_ID}" \
  --username "${AZURE_CLIENT_ID}" \
  --password "${AZURE_CLIENT_SECRET}"
azure account set "${AZURE_SUBSCRIPTION_ID}"

# Upload: Ensure resource group exists
rg_exists="$(azure group show "${AZURE_RESOURCE_GROUP}" --json || true)"
if [[ -z "${rg_exists}" ]]; then
  echo "upload: creating resource group ${AZURE_RESOURCE_GROUP}"
  azure group create -n "${AZURE_RESOURCE_GROUP}" -l "westus"
fi

# Upload: Ensure Storage Account exists
account_exists=$(azure storage account show "${AZURE_STORAGE_ACCOUNT}" -g "${AZURE_RESOURCE_GROUP}" --json | jq '.serviceName' || true)
if [[ -z "${account_exists}" ]]; then
  echo "upload: creating storage account ${AZURE_STORAGE_ACCOUNT}"
  azure storage account create -g "${AZURE_RESOURCE_GROUP}" --location 'west us' --kind Storage --sku-name LRS ${AZURE_STORAGE_ACCOUNT}
fi

# Upload: Retrieve Storage Account Key
storage_key=$(azure storage account keys list ${AZURE_STORAGE_ACCOUNT} -g "${AZURE_RESOURCE_GROUP}" --json | jq -r '.[0].value')
export AZURE_STORAGE_ACCESS_KEY="${storage_key}"

# Upload: Ensure Storage Container exists
container_exists=$(azure storage container show ${AZURE_STORAGE_CONTAINER} --json | jq -r '.name' || true)
if [[ -z "${container_exists}" ]]; then
  echo "upload: creating storage container ${AZURE_STORAGE_CONTAINER}"
  azure storage container create -p Blob ${AZURE_STORAGE_CONTAINER}
fi

# Upload: Perform the upload
azure-vhd-utils-for-go upload \
  --localvhdpath="_output/default.vhd" \
  --stgaccountname="${AZURE_STORAGE_ACCOUNT}" \
  --stgaccountkey="${AZURE_STORAGE_ACCESS_KEY}" \
  --containername="${AZURE_STORAGE_CONTAINER}" \
  --blobname="${FINAL_VHD_NAME}.vhd"

echo "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/${FINAL_VHD_NAME}.vhd" > ./_output/url.txt
