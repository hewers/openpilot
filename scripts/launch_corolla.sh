#!/usr/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

export FINGERPRINT="CHEVROLET VOLT PREMIER 2017"
export SKIP_FW_QUERY="1"
$DIR/../launch_openpilot.sh
