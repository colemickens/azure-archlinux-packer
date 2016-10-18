#!/usr/bin/env bash

set -x
set -u
set -e

vhdurl="$1"
location="westus2"
uniqid="$(date "+%Y%m%d%H%M%S")"
deployid="colemick-dev-${uniqid}"

azure config mode arm

# TODO: re-enable premium storage

param_file="$(mktemp)"

azure account set 27b750cd-ed43-42fd-9044-8d75e124ae55

cat <<EOF >"${param_file}"
{
	"deploymentName": { "value": "colemick-dev-${uniqid}" },
	"adminUsername": { "value": "cole" },
	"adminPassword": { "value": "ChangeThisP@ssword" },
	"storageAccountName": { "value": "colemickvhds1" },
	"osDiskVhdUri": { "value": "http://colemickvhds1.blob.core.windows.net/vhd-instances/colemick-dev-${uniqid}.vhd" },
	"imageVhdUri": { "value": "${vhdurl}" },
	"vmSize": { "value": "Standard_DS4_v2" }
}
EOF

echo "param file: ${param_file}"

azure group create \
	--name "${deployid}" \
	--deployment-name "${deployid}" \
	--location "${location}" \
	--template-file "azuredeploy.json" \
	--parameters-file "${param_file}"
