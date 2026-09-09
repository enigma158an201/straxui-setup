#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

if command -v dpkg >/dev/null 2>&1; then
    LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/dpkg -i "$1" 3>&1 2>&1
    exit
fi