#!/bin/bash
# =============================================================================
# PgCat Installation Script
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== PgCat Installation ===${NC}"

# Install dependencies
echo -e "${YELLOW}[1/4] Installing dependencies...${NC}"
sudo apt-get update -qq
sudo apt-get install -y build-essential pkg-config libssl-dev curl git

# Install Rust
echo -e "${YELLOW}[2/4] Installing Rust...${NC}"
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Build PgCat
echo -e "${YELLOW}[3/4] Building PgCat...${NC}"
cd /tmp
rm -rf pgcat 2>/dev/null || true
git clone https://github.com/postgresml/pgcat.git
cd pgcat
source "$HOME/.cargo/env"
cargo build --release
sudo cp target/release/pgcat /usr/local/bin/

# Setup
echo -e "${YELLOW}[4/4] Setting up PgCat...${NC}"
sudo useradd -r -s /bin/false pgcat 2>/dev/null || true
sudo mkdir -p /etc/pgcat /var/log/pgcat /var/run/pgcat
sudo chown pgcat:pgcat /var/log/pgcat /var/run/pgcat

# Systemd service
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
echo "Next: Edit /etc/pgcat/pgcat.toml then: sudo systemctl enable --now pgcat"
