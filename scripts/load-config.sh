#!/bin/bash
# =============================================================================
# Config Loader - Sources config.env from hardware context
# =============================================================================
# Usage: source load-config.sh
#
# Environment Variables:
#   HARDWARE_CONTEXT  - Hardware context name (e.g., c8g.2xlarge.15.10.8disk.raid10)
#                       If not set, falls back to legacy config.env in scripts/
#
# This script sets CONFIG_FILE to the path of the loaded config.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine config file location
if [ -n "$HARDWARE_CONTEXT" ]; then
    # Use hardware-specific config
    CONFIG_FILE="${SCRIPT_DIR}/hardware/${HARDWARE_CONTEXT}/config.env"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: Config not found for hardware context: $HARDWARE_CONTEXT"
        echo "Expected: $CONFIG_FILE"
        echo ""
        echo "Available contexts:"
        ls -1 "${SCRIPT_DIR}/hardware/" 2>/dev/null | grep -v "^_" | grep -v "\.sh$"
        exit 1
    fi
    echo "[load-config] Using hardware context: $HARDWARE_CONTEXT"
else
    # Legacy: use config.env in scripts directory
    CONFIG_FILE="${SCRIPT_DIR}/config.env"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: No config.env found and HARDWARE_CONTEXT not set"
        echo ""
        echo "Options:"
        echo "  1. Set HARDWARE_CONTEXT environment variable:"
        echo "     export HARDWARE_CONTEXT=c8g.2xlarge.15.10.8disk.raid10"
        echo ""
        echo "  2. Create legacy config.env symlink:"
        echo "     ln -s hardware/c8g.2xlarge.15.10.8disk.raid10/config.env config.env"
        echo ""
        echo "Available hardware contexts:"
        ls -1 "${SCRIPT_DIR}/hardware/" 2>/dev/null | grep -v "^_" | grep -v "\.sh$"
        exit 1
    fi
    echo "[load-config] Using legacy config: $CONFIG_FILE"
fi

# Source the config
source "$CONFIG_FILE"

# Export for child processes
export CONFIG_FILE
export HARDWARE_CONTEXT
