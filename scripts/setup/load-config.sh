#!/bin/bash
# =============================================================================
# Config Loader for scripts2 - Uses Python config_loader for calculations
# =============================================================================
# Usage: source load-config.sh
#
# Environment Variables:
#   HARDWARE_CONTEXT  - Hardware context name (e.g., r8g.2xlarge)
#   WORKLOAD_CONTEXT  - Workload context name (e.g., tpc-b)
#
# This script calls Python config_loader to merge hardware.env + tuning.env
# and calculate derived values (shared_buffers, hugepages, etc.)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default contexts
HARDWARE_CONTEXT="${HARDWARE_CONTEXT:-r8g.2xlarge}"
WORKLOAD_CONTEXT="${WORKLOAD_CONTEXT:-tpc-b}"

echo "[load-config] Hardware: $HARDWARE_CONTEXT"
echo "[load-config] Workload: $WORKLOAD_CONTEXT"

# Check if Python config_loader exists
CONFIG_LOADER="${ROOT_DIR}/core/config_loader.py"
if [ ! -f "$CONFIG_LOADER" ]; then
    echo "ERROR: config_loader.py not found: $CONFIG_LOADER"
    exit 1
fi

# Generate config using Python and export as shell variables
CONFIG_OUTPUT=$(python3 "$CONFIG_LOADER" "$HARDWARE_CONTEXT" "$WORKLOAD_CONTEXT" 2>&1)
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to load config"
    echo "$CONFIG_OUTPUT"
    exit 1
fi

# Parse JSON output and export each key=value
eval $(python3 -c "
import json
import sys
config = json.loads('''$CONFIG_OUTPUT''')
for key, value in config.items():
    # Escape special characters in value
    value = str(value).replace(\"'\", \"'\\\"'\\\"'\")
    print(f\"export {key}='{value}'\")
")

# Set context metadata
export HARDWARE_CONTEXT
export WORKLOAD_CONTEXT
export CONTEXT_ID="${HARDWARE_CONTEXT}--${WORKLOAD_CONTEXT}"

echo "[load-config] Context ID: $CONTEXT_ID"
