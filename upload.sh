#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

###############################################################################


set -eu
set -x

BLOB_NAME="${BLOB_NAME:-"archlinux-$(date +"%Y%m%d%H%M%S")"}"

echo "\$AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}"
echo "\$AZURE_TENANT_ID=${AZURE_TENANT_ID}"
echo "\$AZURE_CLIENT_ID=${AZURE_CLIENT_ID}"
echo "\$AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}"
echo "\$AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}"
echo "\$AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}"
echo "\$AZURE_STORAGE_CONTAINER=${AZURE_STORAGE_CONTAINER}"
echo "\$BLOB_NAME=${BLOB_NAME}"

# Upload: login
rm -rf ~/.az
az login \
  --service-principal \
  --tenant "${AZURE_TENANT_ID}" \
  --username "${AZURE_CLIENT_ID}" \
  --password "${AZURE_CLIENT_SECRET}"
az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

# Upload: Ensure resource group exists
rg_exists="$(az resource show --name "${AZURE_RESOURCE_GROUP}" || true)"
if [[ -z "${rg_exists}" ]]; then
  echo "upload: creating resource group ${AZURE_RESOURCE_GROUP}"
  az resource create -n "${AZURE_RESOURCE_GROUP}" -l "westus"
fi

# Upload: Ensure Storage Account exists
account_exists=$(az storage account show --name "${AZURE_STORAGE_ACCOUNT}" -g "${AZURE_RESOURCE_GROUP}" | jq '.serviceName' || true)
if [[ -z "${account_exists}" ]]; then
  echo "upload: creating storage account ${AZURE_STORAGE_ACCOUNT}"
  az storage account create -g "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --kind Storage --sku "${AZURE_STORAGE_TYPE}" --name "${AZURE_STORAGE_ACCOUNT}"
fi

# Upload: Retrieve Storage Account Key
storage_key=$(az storage account keys list --name "${AZURE_STORAGE_ACCOUNT}" -g "${AZURE_RESOURCE_GROUP}" | jq -r '.keys[0].value')
export AZURE_STORAGE_ACCESS_KEY="${storage_key}"

# Upload: Ensure Storage Container exists
container_exists=$(az storage container show --name "${AZURE_STORAGE_CONTAINER}" | jq -r '.name' || true)
if [[ -z "${container_exists}" ]]; then
  echo "upload: creating storage container ${AZURE_STORAGE_CONTAINER}"
  az storage container create -p Blob "${AZURE_STORAGE_CONTAINER}"
fi

# Upload: Perform the upload
azure-vhd-utils upload \
  --localvhdpath="_output/default.vhd" \
  --stgaccountname="${AZURE_STORAGE_ACCOUNT}" \
  --stgaccountkey="${AZURE_STORAGE_ACCESS_KEY}" \
  --containername="${AZURE_STORAGE_CONTAINER}" \
  --blobname="${BLOB_NAME}.vhd"

echo "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/${BLOB_NAME}.vhd" > ./_output/url.txt
