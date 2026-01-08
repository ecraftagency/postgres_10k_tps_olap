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

# =============================================================================
# PgCat - PostgreSQL Connection Pooler
# =============================================================================
echo "=== Installing PgCat ==="
PGCAT_VERSION="v1.2.0"
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    PGCAT_ARCH="aarch64"
else
    PGCAT_ARCH="x86_64"
fi

if command -v pgcat &> /dev/null; then
    echo "pgcat already installed: $(pgcat --version)"
else
    URL="https://github.com/postgresml/pgcat/releases/download/${PGCAT_VERSION}/pgcat.${PGCAT_ARCH}-unknown-linux-gnu.tar.gz"
    echo "Downloading PgCat from $URL..."
    TMP_DIR=$(mktemp -d)
    if curl -sSL "$URL" -o "$TMP_DIR/pgcat.tar.gz"; then
        tar -xzf "$TMP_DIR/pgcat.tar.gz" -C "$TMP_DIR"
        mv "$TMP_DIR/pgcat" /usr/local/bin/pgcat
        chmod +x /usr/local/bin/pgcat
        echo "PgCat ${PGCAT_VERSION} installed"
    else
        echo "WARNING: Failed to download PgCat (non-fatal)"
    fi
    rm -rf "$TMP_DIR"
fi

# Create pgcat config directory
mkdir -p /etc/pgcat

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
pgcat --version 2>/dev/null || echo "pgcat: not installed"
psql --version

echo ""
echo "=== Done! Next: sudo ./01-os-tuning.sh ==="
