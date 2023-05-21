#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

LANG=C /usr/bin/dpkg -i $1 3>&1 2>&1
exit