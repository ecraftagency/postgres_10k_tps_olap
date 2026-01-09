#!/bin/bash
# =============================================================================
# 00-deps.sh - System Dependencies
# =============================================================================
# Dependencies for PostgreSQL benchmarking infrastructure
# =============================================================================

set -e

echo "=== Installing Dependencies ==="

apt-get update -qq

# RAID + Filesystem tools
apt-get install -y mdadm xfsprogs nvme-cli

# Common tools
apt-get install -y fio sysstat python3 python3-pip postgresql-16

# NOTE: PgCat is installed via 06-pgcat.sh on proxy node only

# =============================================================================
# Sysbench - Database Benchmark Tool
# =============================================================================
echo "=== Installing Sysbench ==="
if command -v sysbench &> /dev/null; then
    echo "sysbench already installed: $(sysbench --version)"
else
    # Install from apt (Ubuntu 24.04 has sysbench 1.0.20)
    apt-get install -y sysbench
    echo "sysbench installed: $(sysbench --version)"
fi

# Download TPC-C lua scripts (not included in Ubuntu package)
if [ ! -f /usr/share/sysbench/tpcc.lua ]; then
    echo "Downloading sysbench TPC-C scripts..."
    TPCC_URL="https://raw.githubusercontent.com/Percona-Lab/sysbench-tpcc/master"
    for f in tpcc.lua tpcc_common.lua tpcc_run.lua tpcc_check.lua; do
        curl -sSL "$TPCC_URL/$f" -o "/usr/share/sysbench/$f"
    done
    echo "TPC-C scripts installed"
fi

# go-tpc for TPC-H benchmarks (ARM64 Graviton)
# echo "=== Installing go-tpc ==="
# GO_TPC_VERSION="v1.0.10"
# ARCH=$(uname -m)
# if [ "$ARCH" = "aarch64" ]; then
#     GO_TPC_ARCH="arm64"
# else
#     GO_TPC_ARCH="amd64"
# fi

# if command -v go-tpc &> /dev/null; then
#     echo "go-tpc already installed"
# else
#     URL="https://github.com/pingcap/go-tpc/releases/download/${GO_TPC_VERSION}/go-tpc_${GO_TPC_VERSION}_linux_${GO_TPC_ARCH}.tar.gz"
#     echo "Downloading from $URL..."
#     TMP_DIR=$(mktemp -d)
#     if wget -q "$URL" -O "$TMP_DIR/go-tpc.tar.gz"; then
#         tar -xzf "$TMP_DIR/go-tpc.tar.gz" -C /usr/local/bin
#         echo "go-tpc ${GO_TPC_VERSION} installed"
#     else
#         echo "Failed to download go-tpc from $URL"
#         # Fallback or alternative check might be needed if URL is wrong
#         exit 1
#     fi
#     rm -rf "$TMP_DIR"
# fi

# Verify
echo ""
echo "=== Verification ==="
fio --version
iostat -V
sysbench --version 2>/dev/null || echo "sysbench: not installed"
psql --version

echo ""
echo "=== Done! Next: sudo ./01-os-tuning.sh ==="
