#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install "$1" 3>&1 2>&1
exit