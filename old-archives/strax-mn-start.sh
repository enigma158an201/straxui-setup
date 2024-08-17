#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"
suExecCommandNoPreserveEnv "
if command -v dotnet &> /dev/null && command -v screen &> /dev/null; then					        screen dotnet ~/StraxNode/Stratis.StraxD.dll run -mainnet; fi
if command -v python3 &> /dev/null && [ -f ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py ]; then   python3 ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py; fi
"
# to do: migrate or import some variables