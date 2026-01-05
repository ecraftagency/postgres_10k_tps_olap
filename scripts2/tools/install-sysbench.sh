#!/bin/bash
# =============================================================================
# Install Sysbench for PostgreSQL Benchmarking
# =============================================================================
# Usage: ./install-sysbench.sh
#
# Sysbench provides OLTP benchmarks similar to TPC-C
# Works natively on ARM64
# =============================================================================

set -e

echo "=== Installing Sysbench ==="

# Install from Ubuntu repos (native ARM64)
echo "[1/2] Installing sysbench..."
sudo apt-get update
sudo apt-get install -y sysbench

# Verify
echo "[2/2] Verifying installation..."
sysbench --version

echo
echo "=== Installation Complete ==="
echo
echo "Available OLTP tests:"
echo "  - oltp_read_only    : Read-only OLTP"
echo "  - oltp_read_write   : Mixed read/write OLTP"
echo "  - oltp_write_only   : Write-only OLTP"
echo "  - oltp_point_select : Point SELECT queries"
echo
echo "Usage:"
echo "  1. Prepare: sysbench oltp_read_only --pgsql-db=bench prepare"
echo "  2. Run:     sysbench oltp_read_only --pgsql-db=bench run"
echo "  3. Cleanup: sysbench oltp_read_only --pgsql-db=bench cleanup"
