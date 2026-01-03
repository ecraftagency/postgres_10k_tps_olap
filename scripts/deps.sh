#!/bin/bash
# =============================================================================
# Benchmark Dependencies Installer
# Run this before running bench.py or 05-db-install.sh
# =============================================================================

set -e

echo "=== Installing Benchmark Dependencies ==="

# Update package list
sudo apt-get update -qq

# Core benchmark tools
sudo apt-get install -y \
    fio \
    sysstat \
    python3

# Add PostgreSQL 16 repository
echo ""
echo "=== Adding PostgreSQL 16 Repository ==="
sudo apt-get install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
. /etc/os-release
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update -qq

# Install PostgreSQL client tools (includes pgbench)
echo ""
echo "=== Installing PostgreSQL 16 Client Tools ==="
sudo apt-get install -y postgresql-client-16

# Verify installations
echo ""
echo "=== Verifying Installations ==="

echo -n "fio: "
fio --version

echo -n "iostat: "
iostat -V | head -1

echo -n "mpstat: "
mpstat -V | head -1

echo -n "python3: "
python3 --version

echo -n "pgbench: "
if command -v pgbench &> /dev/null; then
    pgbench --version
else
    echo "will be installed with postgresql-contrib (by 05-db-install.sh)"
fi

echo ""
echo "=== All dependencies installed ==="
