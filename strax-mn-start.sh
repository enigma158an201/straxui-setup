#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"

suExecCommand screen dotnet ~/StraxNode/Stratis.StraxD.dll run -mainnet
suExecCommand python3 ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py