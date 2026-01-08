#!/bin/bash
# =============================================================================
# verify-config.sh - Verify actual config matches intent (env files)
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local name=$1 expected=$2 actual=$3
    if [ "$expected" == "$actual" ]; then
        echo -e "  $name: ${GREEN}OK${NC}"
        ((PASS++))
    else
        echo -e "  $name: ${RED}MISMATCH${NC} (expect=$expected, actual=$actual)"
        ((FAIL++))
    fi
}

echo "=== CONFIG VERIFICATION ==="

# Load env files
source "$CONFIG_DIR/os.env" 2>/dev/null || true
source "$CONFIG_DIR/primary.env" 2>/dev/null || true

# OS Sysctl
echo "[OS Sysctl]"
check "vm.swappiness" "$VM_SWAPPINESS" "$(sysctl -n vm.swappiness)"
check "vm.dirty_ratio" "$VM_DIRTY_RATIO" "$(sysctl -n vm.dirty_ratio)"
check "vm.nr_hugepages" "$VM_NR_HUGEPAGES" "$(sysctl -n vm.nr_hugepages)"

# PostgreSQL (if running)
if systemctl is-active --quiet postgresql-bench 2>/dev/null; then
    echo "[PostgreSQL]"
    pg_get() { sudo -u postgres psql -At -c "SHOW $1" 2>/dev/null || echo "N/A"; }
    check "shared_buffers" "$PG_SHARED_BUFFERS" "$(pg_get shared_buffers)"
    check "synchronous_commit" "$PG_SYNCHRONOUS_COMMIT" "$(pg_get synchronous_commit)"
    check "wal_sync_method" "$PG_WAL_SYNC_METHOD" "$(pg_get wal_sync_method)"
fi

# Summary
echo ""
echo "=== SUMMARY: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && echo -e "${GREEN}All configs verified${NC}" || echo -e "${RED}Some configs need attention${NC}"
exit $FAIL
