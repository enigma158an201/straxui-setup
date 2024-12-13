#!/usr/bin/env bash

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
#source "${sLaunchDir}/include/file-edition.sh"
suExecCommandNoPreserveEnv "
if command -v dotnet &> /dev/null && command -v screen &> /dev/null; then					        screen dotnet ~/StraxNode/Stratis.StraxD.dll run -mainnet; fi
if command -v python3 &> /dev/null && [[ -f ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py ]]; then   python3 ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py; fi
"
# to do: migrate or import some variables