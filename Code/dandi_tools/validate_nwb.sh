#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <nwb_dir>"
  exit 1
fi

NWB_DIR="$1"

if [[ ! -d "$NWB_DIR" ]]; then
  echo "Directory not found: $NWB_DIR"
  exit 1
fi

echo "Running NWB Inspector (DANDI config)..."
nwbinspector --config dandi "$NWB_DIR"

echo "Running DANDI validator..."
dandi validate "$NWB_DIR"

echo "Validation complete."
