#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

###############################################################################

set -eu -o pipefail
set -x

ARCH_URL="$(cat ./_output/url.txt)"

VERSION="$(printf '%x' $(date '+%s'))"
INSTANCE_NAME="${1:-"azdev-${VERSION}"}"

set +x
az login \
    --service-principal \
    --tenant "${AZURE_TENANT_ID}" \
    --user "${AZURE_CLIENT_ID}" \
    --password "${AZURE_CLIENT_SECRET}"
az account set --subscription "${AZURE_SUBSCRIPTION_ID}"
set -x

if [[ -z "${ARCH_URL:-}" ]]; then
    echo "ARCH_URL needs to be specified!" >&2
    exit -1
fi

param_file="$(mktemp)"
cat <<EOF >"${param_file}"
{
    "username": { "value": "${USERNAME}" },
    "instanceName": { "value": "${INSTANCE_NAME}" },
    "storageAccountName": { "value": "${AZURE_STORAGE_ACCOUNT}" },
    "vmDiskImageUrl": { "value": "${ARCH_URL}" },
    "vmSize": { "value": "${AZURE_VM_SIZE}" },
    "sshPublicKey": { "value": "$(cat ~/.ssh/id_rsa.pub)" }
}
EOF

az group deployment create \
    --name "${AZURE_RESOURCE_GROUP}-deployment-${RANDOM}" \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --template-file "./azuredeploy.json" \
    --parameters "@${param_file}"
