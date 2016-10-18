#!/bin/bash

set -x
set -e
set -u

WORKDIR='/var/lib/pacman-nginx-cache'

sudo mkdir -p "${WORKDIR}"
sudo chown -R http:http "${WORKDIR}"

sudo nginx -c "$(pwd)/nginx.conf"
