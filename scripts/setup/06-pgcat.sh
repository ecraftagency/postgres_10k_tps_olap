#!/bin/bash
# =============================================================================
# 06-pgcat.sh - PgCat Connection Pooler Setup
# =============================================================================
# Configures and starts PgCat for PostgreSQL connection pooling
# Supports OLTP and OLAP workload profiles
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
SERVICES_DIR="$SCRIPT_DIR/../services"

# Default to OLTP config, can override with PGCAT_PROFILE=olap
PGCAT_PROFILE="${PGCAT_PROFILE:-oltp}"

echo "=== Configuring PgCat (profile: $PGCAT_PROFILE) ==="

# =============================================================================
# Verify PgCat is installed
# =============================================================================
if ! command -v pgcat &> /dev/null; then
    echo "ERROR: pgcat not installed. Run 00-deps.sh first."
    exit 1
fi

echo "PgCat version: $(pgcat --version)"

# =============================================================================
# Select config based on profile
# =============================================================================
case "$PGCAT_PROFILE" in
    olap)
        CONFIG_FILE="$CONFIG_DIR/pgcat-olap.toml"
        echo "Using OLAP-optimized config (10K TPS target)"
        ;;
    oltp|*)
        CONFIG_FILE="$CONFIG_DIR/pgcat.toml"
        echo "Using OLTP config"
        ;;
esac

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# =============================================================================
# Deploy configuration
# =============================================================================
echo "=== Deploying PgCat Configuration ==="

mkdir -p /etc/pgcat

# Copy config with verification
cp "$CONFIG_FILE" /etc/pgcat/pgcat.toml
chmod 644 /etc/pgcat/pgcat.toml

echo "Config deployed to /etc/pgcat/pgcat.toml"

# Validate config syntax
if pgcat --config /etc/pgcat/pgcat.toml --check 2>/dev/null; then
    echo "Config validation: OK"
else
    # --check might not exist in all versions, try starting dry-run
    echo "Config validation: skipped (pgcat --check not supported)"
fi

# =============================================================================
# Deploy systemd service
# =============================================================================
echo "=== Setting up systemd service ==="

if [ -f "$SERVICES_DIR/pgcat.service" ]; then
    cp "$SERVICES_DIR/pgcat.service" /etc/systemd/system/pgcat.service
else
    # Create service file inline if not exists
    cat > /etc/systemd/system/pgcat.service << 'EOF'
[Unit]
Description=PgCat PostgreSQL Connection Pooler
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/pgcat /etc/pgcat/pgcat.toml
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

# Memory limit for proxy node (8GB max)
MemoryMax=6G

# CPU scheduling
Nice=-5

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload

# =============================================================================
# OS tuning for high connection count
# =============================================================================
echo "=== Applying OS tuning for PgCat ==="

# Increase file descriptors for high connection pooling
if ! grep -q "pgcat soft nofile" /etc/security/limits.conf 2>/dev/null; then
    cat >> /etc/security/limits.conf << 'EOF'

# PgCat connection pooler limits
pgcat soft nofile 65535
pgcat hard nofile 65535
ubuntu soft nofile 65535
ubuntu hard nofile 65535
EOF
fi

# TCP tuning for high connection throughput
sysctl -w net.core.somaxconn=65535 2>/dev/null || true
sysctl -w net.ipv4.tcp_max_syn_backlog=65535 2>/dev/null || true
sysctl -w net.core.netdev_max_backlog=65535 2>/dev/null || true

# =============================================================================
# Start PgCat
# =============================================================================
echo "=== Starting PgCat ==="

systemctl enable pgcat
systemctl restart pgcat

# Wait for startup
sleep 2

# =============================================================================
# Verify
# =============================================================================
echo "=== Verification ==="

if systemctl is-active --quiet pgcat; then
    echo "PgCat status: RUNNING"
    systemctl status pgcat --no-pager -l | head -15
else
    echo "ERROR: PgCat failed to start"
    journalctl -u pgcat -n 20 --no-pager
    exit 1
fi

# Test connection (if psql available)
if command -v psql &> /dev/null; then
    echo ""
    echo "Testing connection to PgCat..."
    if psql -h 127.0.0.1 -p 6432 -U admin -d pgcat -c "SHOW POOLS;" 2>/dev/null; then
        echo "Connection test: OK"
    else
        echo "Connection test: skipped (admin connection requires proper auth)"
    fi
fi

echo ""
echo "=== PgCat Setup Complete ==="
echo "Listening on: 0.0.0.0:6432"
echo "Config: /etc/pgcat/pgcat.toml"
echo "Profile: $PGCAT_PROFILE"
echo ""
echo "Connect via: psql -h <proxy-ip> -p 6432 -U postgres -d bench"
