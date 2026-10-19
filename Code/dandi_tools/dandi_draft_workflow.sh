#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <dandiset_id> [max_files]"
  echo "Example: $0 002034 10"
  exit 1
fi

DANDISET_ID="$1"
MAX_FILES="${2:-0}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PYTHON_BIN="$REPO_ROOT/.venv/bin/python"
NWBINSPECTOR_BIN="$REPO_ROOT/.venv/bin/nwbinspector"
DANDI_BIN="$REPO_ROOT/.venv/bin/dandi"

cd "$REPO_ROOT"

echo "[1/5] Downloading local draft dandiset $DANDISET_ID"
"$DANDI_BIN" download "https://dandiarchive.org/dandiset/${DANDISET_ID}/draft"

echo "[2/5] Converting MAT to NWB into local dandiset folder"
if [[ "$MAX_FILES" == "0" ]]; then
  "$PYTHON_BIN" Code/dandi_tools/mat_to_nwb.py --output-dir "$DANDISET_ID"
else
  "$PYTHON_BIN" Code/dandi_tools/mat_to_nwb.py --output-dir "$DANDISET_ID" --max-files "$MAX_FILES"
fi

echo "[3/5] Running NWB Inspector with DANDI config"
"$NWBINSPECTOR_BIN" --config dandi "$DANDISET_ID"

echo "[4/5] Running dandi validate"
"$DANDI_BIN" validate "$DANDISET_ID"

echo "[5/5] Ready to upload (manual auth may be required)"
echo "Run: $DANDI_BIN upload $DANDISET_ID"
