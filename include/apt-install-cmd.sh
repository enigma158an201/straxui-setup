#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

if command -v apt-get >/dev/null 2>&1; then
    LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install "$1" 3>&1 2>&1
    exit
fi