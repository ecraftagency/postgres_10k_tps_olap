#!/bin/bash
# =============================================================================
# 00-deps.sh - System Dependencies Installer
# =============================================================================
# Run this FIRST before any other scripts
# Installs all tools needed for RAID setup, benchmarking, and PostgreSQL
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  System Dependencies Installer${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# =============================================================================
# 1. SYSTEM UPDATE
# =============================================================================
echo -e "${YELLOW}[1/6] Updating package lists...${NC}"
sudo apt-get update -qq

# =============================================================================
# 2. CORE SYSTEM TOOLS
# =============================================================================
echo -e "${YELLOW}[2/6] Installing core system tools...${NC}"
sudo apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https

# =============================================================================
# 3. RAID & DISK TOOLS
# =============================================================================
echo -e "${YELLOW}[3/6] Installing RAID and disk tools...${NC}"
sudo apt-get install -y \
    mdadm \
    xfsprogs \
    nvme-cli \
    hdparm \
    parted \
    gdisk

# =============================================================================
# 4. BENCHMARK TOOLS
# =============================================================================
echo -e "${YELLOW}[4/6] Installing benchmark tools...${NC}"
sudo apt-get install -y \
    fio \
    sysstat \
    iotop \
    htop \
    dstat \
    blktrace

# =============================================================================
# 5. PYTHON & PACKAGES
# =============================================================================
echo -e "${YELLOW}[5/6] Installing Python and packages...${NC}"
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv

# Python packages for benchmark scripts
pip3 install --user --quiet \
    rich \
    psutil \
    pyyaml \
    tomli

# =============================================================================
# 6. POSTGRESQL 16 REPOSITORY & CLIENT
# =============================================================================
echo -e "${YELLOW}[6/6] Setting up PostgreSQL 16 repository...${NC}"

# Add PostgreSQL GPG key
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Add repository
. /etc/os-release
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
    | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

sudo apt-get update -qq

# Install PostgreSQL client tools (includes pgbench)
sudo apt-get install -y postgresql-client-16

# =============================================================================
# VERIFICATION
# =============================================================================
echo ""
echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Verifying Installations${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

verify_tool() {
    local name=$1
    local cmd=$2
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name: $(${@:2} 2>&1 | head -1)"
    else
        echo -e "${RED}✗${NC} $name: NOT FOUND"
    fi
}

# Core tools
verify_tool "curl" curl --version
verify_tool "mdadm" mdadm --version
verify_tool "xfs_info" xfs_info -V

# Benchmark tools
verify_tool "fio" fio --version
verify_tool "iostat" iostat -V
verify_tool "mpstat" mpstat -V
verify_tool "iotop" iotop --version
verify_tool "htop" htop --version
verify_tool "dstat" dstat --version

# Python
verify_tool "python3" python3 --version
verify_tool "pip3" pip3 --version

# PostgreSQL
verify_tool "pgbench" pgbench --version
verify_tool "psql" psql --version

# Python packages
echo ""
echo -e "${BLUE}Python Packages:${NC}"
python3 -c "import rich; print(f'  rich: {rich.__version__}')" 2>/dev/null || echo "  rich: NOT INSTALLED"
python3 -c "import psutil; print(f'  psutil: {psutil.__version__}')" 2>/dev/null || echo "  psutil: NOT INSTALLED"
python3 -c "import yaml; print(f'  pyyaml: installed')" 2>/dev/null || echo "  pyyaml: NOT INSTALLED"
python3 -c "import tomli; print(f'  tomli: installed')" 2>/dev/null || echo "  tomli: NOT INSTALLED"

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  All dependencies installed!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Next steps:"
echo "  1. sudo ./01-os-tuning.sh     # OS sysctl tuning"
echo "  2. sudo ./02-raid-setup.sh    # RAID10 setup"
echo "  3. sudo ./03-disk-tuning.sh   # XFS and block device tuning"
echo "  4. sudo ./05-db-install.sh    # PostgreSQL installation"
echo "  5. sudo python3 bench.py      # Run benchmarks"
echo ""
