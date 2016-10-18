#!/usr/bin/env bash

set -eu -o pipefail
set -x

if [[ -z "${1:-}" ]]; then
	echo "First arg must be instance name" >&2
	exit -1
fi

ARCH_URL="$(cat ../_output/url.txt)"

if [[ -z "${ARCH_URL:-}" ]]; then
	echo "ARCH_URL needs to be specified!" >&2
	exit -1
fi

param_file="$(mktemp)"
cat <<EOF >"${param_file}"
{
	"username": { "value": "$(whoami)" },
	"instanceName": { "value": "${1}" },
	"storageAccountName": { "value": "${AZURE_STORAGE_ACCOUNT}" },
	"vmDiskImageUrl": { "value": "${ARCH_URL}" },
	"vmSize": { "value": "${AZURE_VM_SIZE}" },
	"sshPublicKey": { "value": "$(cat ~/.ssh/id_rsa.pub)" }
}
EOF

az resource group deployment create \
	--name "${AZURE_RESOURCE_GROUP}-deployment-${RANDOM}" \
	--resource-group "${AZURE_RESOURCE_GROUP}" \
	--template-file-path "./azuredeploy.json" \
	--parameters-file-path "${param_file}"
