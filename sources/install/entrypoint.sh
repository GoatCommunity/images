#!/bin/bash

set -e

source package_base.sh
source package_desktop.sh
source package_light.sh
source package_recon.sh
source package_pentest.sh
source package_full.sh

if [[ $EUID -ne 0 ]]; then
  criticalecho "You must be a root user"
fi

if declare -f "$1" > /dev/null; then
  colorecho "Running Goat build step: $1"
  "$@"
else
  echo "'$1' is not a known function name" >&2
  exit 1
fi
