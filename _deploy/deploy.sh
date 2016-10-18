#!/usr/bin/env bash

set -eu -o pipefail
set -x

RESOURCE_GROUP="colemick-acs-linuxdev"
LOCATION="westus2"

# TODO: fix this
# see: https://github.com/Azure/azure-cli/issues/1061

#az resource group create \
#	--name "${RESOURCE_GROUP}" \
#	--location "${LOCATION}"

az resource group deployment create \
	--name "${RESOURCE_GROUP}-deployment-${RANDOM}" \
	--resource-group "${RESOURCE_GROUP}" \
	--template-file-path "./azuredeploy.json" \
	--parameters-file-path "./azuredeploy.parameters.json"
