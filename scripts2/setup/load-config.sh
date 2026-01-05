#!/bin/bash
# =============================================================================
# Config Loader for scripts2 - Sources hardware.env + tuning.env
# =============================================================================
# Usage: source load-config.sh
#
# Environment Variables:
#   HARDWARE_CONTEXT  - Hardware context name (e.g., r8g.2xlarge)
#   WORKLOAD_CONTEXT  - Workload context name (e.g., tpc-b)
#
# This script merges hardware.env + tuning.env and exports all variables.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default contexts
HARDWARE_CONTEXT="${HARDWARE_CONTEXT:-r8g.2xlarge}"
WORKLOAD_CONTEXT="${WORKLOAD_CONTEXT:-tpc-b}"

# Config file paths
HARDWARE_ENV="${ROOT_DIR}/hardware/${HARDWARE_CONTEXT}/hardware.env"
TUNING_ENV="${ROOT_DIR}/workloads/${WORKLOAD_CONTEXT}/tuning.env"

# Check hardware.env exists
if [ ! -f "$HARDWARE_ENV" ]; then
    echo "ERROR: hardware.env not found: $HARDWARE_ENV"
    echo ""
    echo "Available hardware contexts:"
    ls -1 "${ROOT_DIR}/hardware/" 2>/dev/null
    exit 1
fi

# Check tuning.env exists
if [ ! -f "$TUNING_ENV" ]; then
    echo "ERROR: tuning.env not found: $TUNING_ENV"
    echo ""
    echo "Available workload contexts:"
    ls -1 "${ROOT_DIR}/workloads/" 2>/dev/null
    exit 1
fi

echo "[load-config] Hardware: $HARDWARE_CONTEXT"
echo "[load-config] Workload: $WORKLOAD_CONTEXT"

# Source hardware.env first (base config)
source "$HARDWARE_ENV"

# Source tuning.env (overrides and workload-specific settings)
source "$TUNING_ENV"

# Set context metadata
export HARDWARE_CONTEXT
export WORKLOAD_CONTEXT
export CONTEXT_ID="${HARDWARE_CONTEXT}--${WORKLOAD_CONTEXT}"

echo "[load-config] Context ID: $CONTEXT_ID"
