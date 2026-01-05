#!/bin/bash
# =============================================================================
# Install HammerDB for PostgreSQL Benchmarking
# =============================================================================
# Usage: ./install-hammerdb.sh
#
# Installs HammerDB 4.10 (latest) for ARM64/aarch64
# =============================================================================

set -e

HAMMERDB_VERSION="4.10"
HAMMERDB_DIR="/opt/hammerdb"

echo "=== Installing HammerDB ${HAMMERDB_VERSION} ==="

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "WARNING: This script is optimized for ARM64, detected: $ARCH"
fi

# Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    tcl \
    tcllib \
    libpq-dev \
    postgresql-client \
    wget \
    unzip

# Download HammerDB
echo "[2/4] Downloading HammerDB ${HAMMERDB_VERSION}..."
cd /tmp
wget -q "https://github.com/TPC-Council/HammerDB/releases/download/v${HAMMERDB_VERSION}/HammerDB-${HAMMERDB_VERSION}-Linux.tar.gz" \
    -O hammerdb.tar.gz

# Extract
echo "[3/4] Extracting to ${HAMMERDB_DIR}..."
sudo rm -rf ${HAMMERDB_DIR}
sudo mkdir -p ${HAMMERDB_DIR}
sudo tar -xzf hammerdb.tar.gz -C /opt/
sudo mv /opt/HammerDB-${HAMMERDB_VERSION}/* ${HAMMERDB_DIR}/
sudo rm -rf /opt/HammerDB-${HAMMERDB_VERSION}
rm hammerdb.tar.gz

# Create symlink
echo "[4/4] Creating symlinks..."
sudo ln -sf ${HAMMERDB_DIR}/hammerdbcli /usr/local/bin/hammerdbcli

# Verify installation
echo
echo "=== Verification ==="
${HAMMERDB_DIR}/hammerdbcli --version 2>/dev/null || echo "HammerDB installed at ${HAMMERDB_DIR}"

echo
echo "=== Installation Complete ==="
echo "HammerDB location: ${HAMMERDB_DIR}"
echo "CLI command: hammerdbcli"
echo
echo "Next steps:"
echo "  1. Create TPC-C schema: hammerdbcli < build_tpcc.tcl"
echo "  2. Run benchmark: hammerdbcli < run_tpcc.tcl"
