#!/bin/bash
# =============================================================================
# Configure PostgreSQL to accept connections from PgCat proxy
# =============================================================================
# Run this script on the DB machine BEFORE starting PgCat on the proxy
# Usage: ./configure-db-auth.sh [PROXY_IP]
#        If PROXY_IP not provided, allows entire VPC CIDR (10.0.0.0/16)
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
PGDATA="/data/postgresql"
PG_HBA="${PGDATA}/pg_hba.conf"
PROXY_IP="${1:-10.0.0.0/16}"

echo -e "${BLUE}=== Configure DB for PgCat Proxy ===${NC}"
echo -e "PGDATA: ${GREEN}${PGDATA}${NC}"
echo -e "Allow from: ${GREEN}${PROXY_IP}${NC}"

# =============================================================================
# Verify PostgreSQL data directory
# =============================================================================
if [ ! -f "$PG_HBA" ]; then
    echo -e "${RED}ERROR: pg_hba.conf not found at ${PG_HBA}${NC}"
    echo "Is PGDATA correct? PostgreSQL data should be at /data/postgres"
    exit 1
fi

# =============================================================================
# Check if VPC scram-sha-256 rule already exists
# =============================================================================
if grep -q "host.*all.*all.*${PROXY_IP}.*scram-sha-256" "$PG_HBA" 2>/dev/null; then
    echo -e "${GREEN}VPC auth rule already exists for ${PROXY_IP}${NC}"
else
    echo -e "${YELLOW}Adding VPC auth rule for ${PROXY_IP}...${NC}"

    # Backup pg_hba.conf
    sudo cp "$PG_HBA" "${PG_HBA}.backup.$(date +%Y%m%d_%H%M%S)"

    # Add scram-sha-256 rule for VPC connections (NEVER use trust!)
    echo "# PgCat proxy - VPC scram-sha-256 auth" | sudo tee -a "$PG_HBA" > /dev/null
    echo "host    all    all    ${PROXY_IP}    scram-sha-256" | sudo tee -a "$PG_HBA" > /dev/null

    echo -e "${GREEN}Added scram-sha-256 rule to pg_hba.conf${NC}"
fi

# =============================================================================
# Reload PostgreSQL
# =============================================================================
echo -e "${YELLOW}Reloading PostgreSQL configuration...${NC}"

# Try systemctl first, then pg_ctl
if systemctl is-active --quiet postgresql 2>/dev/null; then
    sudo systemctl reload postgresql
    echo -e "${GREEN}PostgreSQL reloaded via systemctl${NC}"
elif systemctl is-active --quiet postgresql-16 2>/dev/null; then
    sudo systemctl reload postgresql-16
    echo -e "${GREEN}PostgreSQL reloaded via systemctl${NC}"
else
    # Use pg_ctl directly
    sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl reload -D "$PGDATA" 2>/dev/null || \
    sudo -u postgres pg_ctl reload -D "$PGDATA" 2>/dev/null || \
    sudo -u postgres psql -c "SELECT pg_reload_conf();" 2>/dev/null || \
    echo -e "${YELLOW}Could not auto-reload. Please reload PostgreSQL manually.${NC}"
fi

echo ""
echo -e "${GREEN}=== DB configured for proxy connections ===${NC}"
echo "Connections from ${PROXY_IP} require password (scram-sha-256)"
echo "Ensure postgres password is set: ALTER USER postgres PASSWORD 'postgres';"
