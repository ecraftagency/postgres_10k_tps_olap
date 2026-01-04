#!/bin/bash
# =============================================================================
# PgCat Installation Script
# =============================================================================
# Usage: ./install.sh <DB_PRIVATE_IP>
# Example: ./install.sh 10.0.1.100
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# CONFIGURATION
# =============================================================================
DB_PRIVATE_IP="${1:-}"
PGCAT_CONFIG_DIR="/etc/pgcat"
PGCAT_CONFIG_FILE="${PGCAT_CONFIG_DIR}/pgcat.toml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$DB_PRIVATE_IP" ]; then
    echo -e "${RED}ERROR: DB_PRIVATE_IP is required${NC}"
    echo "Usage: $0 <DB_PRIVATE_IP>"
    echo "Example: $0 10.0.1.100"
    exit 1
fi

echo -e "${BLUE}=== PgCat Installation ===${NC}"
echo -e "DB Private IP: ${GREEN}${DB_PRIVATE_IP}${NC}"

# =============================================================================
# STEP 1: Install dependencies
# =============================================================================
echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y build-essential pkg-config libssl-dev curl git

# =============================================================================
# STEP 2: Install Rust
# =============================================================================
echo -e "${YELLOW}[2/5] Installing Rust...${NC}"
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# =============================================================================
# STEP 3: Build PgCat
# =============================================================================
echo -e "${YELLOW}[3/5] Building PgCat...${NC}"
cd /tmp
rm -rf pgcat 2>/dev/null || true
git clone https://github.com/postgresml/pgcat.git
cd pgcat
source "$HOME/.cargo/env"
cargo build --release
sudo cp target/release/pgcat /usr/local/bin/

# =============================================================================
# STEP 4: Setup directories and config
# =============================================================================
echo -e "${YELLOW}[4/5] Setting up PgCat...${NC}"
sudo useradd -r -s /bin/false pgcat 2>/dev/null || true
sudo mkdir -p /etc/pgcat /var/log/pgcat /var/run/pgcat
sudo chown pgcat:pgcat /var/log/pgcat /var/run/pgcat

# Copy config and update DB IP
if [ -f "${SCRIPT_DIR}/pgcat.toml" ]; then
    echo "Updating pgcat.toml with DB IP: ${DB_PRIVATE_IP}"
    sed "s/10\.0\.1\.[0-9]\+/${DB_PRIVATE_IP}/g" "${SCRIPT_DIR}/pgcat.toml" | sudo tee "${PGCAT_CONFIG_FILE}" > /dev/null
else
    echo -e "${RED}ERROR: pgcat.toml not found in ${SCRIPT_DIR}${NC}"
    exit 1
fi

# =============================================================================
# STEP 5: Systemd service
# =============================================================================
echo -e "${YELLOW}[5/5] Creating systemd service...${NC}"
sudo tee /etc/systemd/system/pgcat.service > /dev/null <<'EOF'
[Unit]
Description=PgCat PostgreSQL Connection Pooler
After=network.target

[Service]
Type=simple
User=pgcat
ExecStart=/usr/local/bin/pgcat /etc/pgcat/pgcat.toml
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

echo -e "${GREEN}=== PgCat installed: $(pgcat --version 2>&1 | head -1) ===${NC}"
echo -e "${GREEN}Config: ${PGCAT_CONFIG_FILE}${NC}"
echo ""
echo "Next steps:"
echo "  1. Ensure DB allows connections from this proxy (see configure-db-auth.sh)"
echo "  2. Start PgCat: sudo systemctl enable --now pgcat"
echo "  3. Check status: sudo systemctl status pgcat"
