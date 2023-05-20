#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"

if (which dotnet 1>/dev/null) && (which screen 1>/dev/null); then								suExecCommand screen dotnet ~/StraxNode/Stratis.StraxD.dll run -mainnet; fi
if (which python3 1>/dev/null) && [ -f ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py ]; then	suExecCommand python3 ~/StraxCLI/StraxCLI-StraxCLI-1.0.0/straxcli.py; fi

# to do: migrate or import some variables