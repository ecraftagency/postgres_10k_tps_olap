#!/usr/bin/env python3
"""
Config Verifier - Verifies all settings before benchmark

Generates a markdown table for each category:
- OS Tuning (Memory, Network, Scheduler)
- RAID Config
- Block Device Tuning
- PostgreSQL Settings
"""
import subprocess
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional


@dataclass
class VerifyResult:
    """Result of a single verification check"""
    name: str
    expected: str
    actual: str
    passed: bool
    category: str


def run_cmd(cmd: str, timeout: int = 10) -> str:
    """Run shell command and return output"""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout
        )
        return result.stdout.strip()
    except Exception:
        return "N/A"


def get_sysctl(key: str) -> str:
    """Get sysctl value"""
    return run_cmd(f"sysctl -n {key} 2>/dev/null")


def get_block_param(device: str, param: str) -> str:
    """Get block device parameter"""
    return run_cmd(f"cat /sys/block/{device}/queue/{param} 2>/dev/null")


def get_pg_setting(setting: str) -> str:
    """Get PostgreSQL setting value"""
    result = run_cmd(f"sudo -u postgres psql -t -c \"SHOW {setting};\" 2>/dev/null")
    return result.strip()


def verify_config(config: Dict[str, str]) -> List[VerifyResult]:
    """
    Verify all config settings against actual system state.

    Returns list of VerifyResult for each checked setting.
    """
    results = []

    def check(category: str, name: str, expected: str, actual: str):
        # Normalize for comparison
        exp_norm = str(expected).lower().strip()
        act_norm = str(actual).lower().strip()

        # Handle unit conversions (1s == 1000ms, etc)
        if exp_norm == "1s":
            exp_norm = "1000"
        if act_norm == "1s":
            act_norm = "1000"

        # Remove trailing .0 for numeric comparisons
        exp_norm = exp_norm.rstrip('0').rstrip('.') if '.' in exp_norm else exp_norm
        act_norm = act_norm.rstrip('0').rstrip('.') if '.' in act_norm else act_norm

        passed = exp_norm == act_norm
        results.append(VerifyResult(
            name=name,
            expected=str(expected),
            actual=str(actual),
            passed=passed,
            category=category
        ))

    # =========================================================================
    # OS TUNING - MEMORY
    # =========================================================================
    check("OS Memory", "vm.swappiness", config.get('VM_SWAPPINESS', ''), get_sysctl("vm.swappiness"))
    check("OS Memory", "vm.nr_hugepages", config.get('VM_NR_HUGEPAGES', ''), get_sysctl("vm.nr_hugepages"))
    check("OS Memory", "vm.dirty_background_ratio", config.get('VM_DIRTY_BACKGROUND_RATIO', ''), get_sysctl("vm.dirty_background_ratio"))
    check("OS Memory", "vm.dirty_ratio", config.get('VM_DIRTY_RATIO', ''), get_sysctl("vm.dirty_ratio"))
    check("OS Memory", "vm.dirty_expire_centisecs", config.get('VM_DIRTY_EXPIRE_CENTISECS', ''), get_sysctl("vm.dirty_expire_centisecs"))
    check("OS Memory", "vm.dirty_writeback_centisecs", config.get('VM_DIRTY_WRITEBACK_CENTISECS', ''), get_sysctl("vm.dirty_writeback_centisecs"))
    check("OS Memory", "vm.overcommit_memory", config.get('VM_OVERCOMMIT_MEMORY', ''), get_sysctl("vm.overcommit_memory"))
    check("OS Memory", "vm.overcommit_ratio", config.get('VM_OVERCOMMIT_RATIO', ''), get_sysctl("vm.overcommit_ratio"))
    check("OS Memory", "vm.min_free_kbytes", config.get('VM_MIN_FREE_KBYTES', ''), get_sysctl("vm.min_free_kbytes"))

    # =========================================================================
    # OS TUNING - FILE DESCRIPTORS
    # =========================================================================
    check("OS FileDesc", "fs.file-max", config.get('FS_FILE_MAX', ''), get_sysctl("fs.file-max"))
    check("OS FileDesc", "fs.aio-max-nr", config.get('FS_AIO_MAX_NR', ''), get_sysctl("fs.aio-max-nr"))

    # =========================================================================
    # OS TUNING - NETWORK
    # =========================================================================
    check("OS Network", "net.core.somaxconn", config.get('NET_CORE_SOMAXCONN', ''), get_sysctl("net.core.somaxconn"))
    check("OS Network", "net.core.rmem_max", config.get('NET_CORE_RMEM_MAX', ''), get_sysctl("net.core.rmem_max"))
    check("OS Network", "net.core.wmem_max", config.get('NET_CORE_WMEM_MAX', ''), get_sysctl("net.core.wmem_max"))
    check("OS Network", "net.ipv4.tcp_tw_reuse", config.get('NET_IPV4_TCP_TW_REUSE', ''), get_sysctl("net.ipv4.tcp_tw_reuse"))
    check("OS Network", "net.ipv4.tcp_fin_timeout", config.get('NET_IPV4_TCP_FIN_TIMEOUT', ''), get_sysctl("net.ipv4.tcp_fin_timeout"))

    # =========================================================================
    # BLOCK DEVICE TUNING - DATA (md0)
    # =========================================================================
    check("Block md0", "read_ahead_kb", config.get('DATA_READ_AHEAD_KB', ''), get_block_param("md0", "read_ahead_kb"))
    check("Block md0", "rotational", config.get('DATA_ROTATIONAL', ''), get_block_param("md0", "rotational"))
    check("Block md0", "add_random", config.get('DATA_ADD_RANDOM', ''), get_block_param("md0", "add_random"))
    check("Block md0", "nomerges", config.get('DATA_NOMERGES', ''), get_block_param("md0", "nomerges"))
    check("Block md0", "max_sectors_kb", config.get('DATA_MAX_SECTORS_KB', ''), get_block_param("md0", "max_sectors_kb"))

    # =========================================================================
    # BLOCK DEVICE TUNING - WAL (md1)
    # =========================================================================
    check("Block md1", "read_ahead_kb", config.get('WAL_READ_AHEAD_KB', ''), get_block_param("md1", "read_ahead_kb"))
    check("Block md1", "rotational", config.get('WAL_ROTATIONAL', ''), get_block_param("md1", "rotational"))
    check("Block md1", "add_random", config.get('WAL_ADD_RANDOM', ''), get_block_param("md1", "add_random"))
    check("Block md1", "nomerges", config.get('WAL_NOMERGES', ''), get_block_param("md1", "nomerges"))
    check("Block md1", "max_sectors_kb", config.get('WAL_MAX_SECTORS_KB', ''), get_block_param("md1", "max_sectors_kb"))

    # =========================================================================
    # POSTGRESQL - CONNECTIONS & MEMORY
    # =========================================================================
    check("PG Memory", "max_connections", config.get('PG_MAX_CONNECTIONS', ''), get_pg_setting("max_connections"))
    check("PG Memory", "shared_buffers", config.get('PG_SHARED_BUFFERS', ''), get_pg_setting("shared_buffers"))
    check("PG Memory", "huge_pages", config.get('PG_HUGE_PAGES', ''), get_pg_setting("huge_pages"))
    check("PG Memory", "work_mem", config.get('PG_WORK_MEM', ''), get_pg_setting("work_mem"))
    check("PG Memory", "maintenance_work_mem", config.get('PG_MAINTENANCE_WORK_MEM', ''), get_pg_setting("maintenance_work_mem"))
    check("PG Memory", "effective_cache_size", config.get('PG_EFFECTIVE_CACHE_SIZE', ''), get_pg_setting("effective_cache_size"))

    # =========================================================================
    # POSTGRESQL - DISK I/O
    # =========================================================================
    check("PG DiskIO", "random_page_cost", config.get('PG_RANDOM_PAGE_COST', ''), get_pg_setting("random_page_cost"))
    check("PG DiskIO", "effective_io_concurrency", config.get('PG_EFFECTIVE_IO_CONCURRENCY', ''), get_pg_setting("effective_io_concurrency"))

    # =========================================================================
    # POSTGRESQL - WAL
    # =========================================================================
    check("PG WAL", "wal_compression", config.get('PG_WAL_COMPRESSION', ''), get_pg_setting("wal_compression"))
    check("PG WAL", "wal_buffers", config.get('PG_WAL_BUFFERS', ''), get_pg_setting("wal_buffers"))
    check("PG WAL", "wal_writer_delay", config.get('PG_WAL_WRITER_DELAY', ''), get_pg_setting("wal_writer_delay"))
    check("PG WAL", "max_wal_size", config.get('PG_MAX_WAL_SIZE', ''), get_pg_setting("max_wal_size"))
    check("PG WAL", "checkpoint_timeout", config.get('PG_CHECKPOINT_TIMEOUT', ''), get_pg_setting("checkpoint_timeout"))

    # =========================================================================
    # POSTGRESQL - SYNC & COMMIT
    # =========================================================================
    check("PG Sync", "synchronous_commit", config.get('PG_SYNCHRONOUS_COMMIT', ''), get_pg_setting("synchronous_commit"))
    check("PG Sync", "commit_delay", config.get('PG_COMMIT_DELAY', ''), get_pg_setting("commit_delay"))
    check("PG Sync", "commit_siblings", config.get('PG_COMMIT_SIBLINGS', ''), get_pg_setting("commit_siblings"))

    # =========================================================================
    # POSTGRESQL - BACKGROUND WRITER
    # =========================================================================
    check("PG BGWriter", "bgwriter_delay", config.get('PG_BGWRITER_DELAY', ''), get_pg_setting("bgwriter_delay"))
    check("PG BGWriter", "bgwriter_lru_maxpages", config.get('PG_BGWRITER_LRU_MAXPAGES', ''), get_pg_setting("bgwriter_lru_maxpages"))
    check("PG BGWriter", "bgwriter_lru_multiplier", config.get('PG_BGWRITER_LRU_MULTIPLIER', ''), get_pg_setting("bgwriter_lru_multiplier"))

    # =========================================================================
    # POSTGRESQL - AUTOVACUUM
    # =========================================================================
    check("PG Autovac", "autovacuum", config.get('PG_AUTOVACUUM', ''), get_pg_setting("autovacuum"))
    check("PG Autovac", "autovacuum_max_workers", config.get('PG_AUTOVACUUM_MAX_WORKERS', ''), get_pg_setting("autovacuum_max_workers"))

    # =========================================================================
    # POSTGRESQL - PARALLEL QUERY
    # =========================================================================
    check("PG Parallel", "max_worker_processes", config.get('PG_MAX_WORKER_PROCESSES', ''), get_pg_setting("max_worker_processes"))
    check("PG Parallel", "max_parallel_workers", config.get('PG_MAX_PARALLEL_WORKERS', ''), get_pg_setting("max_parallel_workers"))
    check("PG Parallel", "max_parallel_workers_per_gather", config.get('PG_MAX_PARALLEL_WORKERS_PER_GATHER', ''), get_pg_setting("max_parallel_workers_per_gather"))
    check("PG Parallel", "jit", config.get('PG_JIT', ''), get_pg_setting("jit"))

    return results


def format_verification_table(results: List[VerifyResult]) -> str:
    """Format verification results as markdown tables grouped by category"""
    lines = []

    # Group by category
    categories = {}
    for r in results:
        if r.category not in categories:
            categories[r.category] = []
        categories[r.category].append(r)

    # Generate table for each category
    for category, checks in categories.items():
        lines.append(f"### {category}")
        lines.append("")
        lines.append("| Setting | Expected | Actual | Status |")
        lines.append("|---------|----------|--------|--------|")

        for r in checks:
            status = "✓" if r.passed else "✗"
            lines.append(f"| {r.name} | `{r.expected}` | `{r.actual}` | {status} |")

        lines.append("")

    return "\n".join(lines)


def format_verification_summary(results: List[VerifyResult]) -> Tuple[int, int, str]:
    """Generate summary of verification results"""
    total = len(results)
    passed = sum(1 for r in results if r.passed)
    failed = total - passed

    if failed == 0:
        summary = f"✓ All {total} configurations verified"
    else:
        summary = f"✗ {failed}/{total} configurations need review"

    return passed, failed, summary


def print_verification(results: List[VerifyResult]):
    """Print verification results to console"""
    print("\n" + "=" * 70)
    print("CONFIG VERIFICATION")
    print("=" * 70)

    # Group by category
    categories = {}
    for r in results:
        if r.category not in categories:
            categories[r.category] = []
        categories[r.category].append(r)

    for category, checks in categories.items():
        print(f"\n--- {category} ---")
        for r in checks:
            status = "OK" if r.passed else "MISMATCH"
            symbol = "✓" if r.passed else "✗"
            print(f"  {symbol} {r.name:40s} expected={r.expected:15s} actual={r.actual:15s} [{status}]")

    # Summary
    passed, failed, summary = format_verification_summary(results)
    print("\n" + "=" * 70)
    print(f"SUMMARY: {summary}")
    print("=" * 70)


def generate_config_matrix(config: Dict[str, str]) -> str:
    """
    Generate a config matrix markdown section showing all settings.
    This is for embedding in the benchmark report.
    """
    lines = []
    lines.append("## Configuration Matrix")
    lines.append("")
    lines.append(f"**Context:** `{config.get('CONTEXT_ID', 'unknown')}`")
    lines.append(f"**Hardware:** {config.get('INSTANCE_TYPE', 'unknown')} ({config.get('VCPU', '?')} vCPU, {config.get('RAM_GB', '?')} GB RAM)")
    lines.append(f"**Workload:** {config.get('WORKLOAD_CONTEXT', 'unknown')}")
    lines.append("")

    # PostgreSQL Memory Settings
    lines.append("### PostgreSQL - Memory")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| shared_buffers | `{config.get('PG_SHARED_BUFFERS', 'N/A')}` |")
    lines.append(f"| huge_pages | `{config.get('PG_HUGE_PAGES', 'N/A')}` |")
    lines.append(f"| work_mem | `{config.get('PG_WORK_MEM', 'N/A')}` |")
    lines.append(f"| maintenance_work_mem | `{config.get('PG_MAINTENANCE_WORK_MEM', 'N/A')}` |")
    lines.append(f"| effective_cache_size | `{config.get('PG_EFFECTIVE_CACHE_SIZE', 'N/A')}` |")
    lines.append(f"| max_connections | `{config.get('PG_MAX_CONNECTIONS', 'N/A')}` |")
    lines.append("")

    # PostgreSQL WAL Settings
    lines.append("### PostgreSQL - WAL")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| wal_buffers | `{config.get('PG_WAL_BUFFERS', 'N/A')}` |")
    lines.append(f"| wal_compression | `{config.get('PG_WAL_COMPRESSION', 'N/A')}` |")
    lines.append(f"| max_wal_size | `{config.get('PG_MAX_WAL_SIZE', 'N/A')}` |")
    lines.append(f"| checkpoint_timeout | `{config.get('PG_CHECKPOINT_TIMEOUT', 'N/A')}` |")
    lines.append(f"| synchronous_commit | `{config.get('PG_SYNCHRONOUS_COMMIT', 'N/A')}` |")
    lines.append(f"| commit_delay | `{config.get('PG_COMMIT_DELAY', 'N/A')}` |")
    lines.append("")

    # PostgreSQL Background Writer
    lines.append("### PostgreSQL - Background Writer")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| bgwriter_delay | `{config.get('PG_BGWRITER_DELAY', 'N/A')}` |")
    lines.append(f"| bgwriter_lru_maxpages | `{config.get('PG_BGWRITER_LRU_MAXPAGES', 'N/A')}` |")
    lines.append(f"| bgwriter_lru_multiplier | `{config.get('PG_BGWRITER_LRU_MULTIPLIER', 'N/A')}` |")
    lines.append("")

    # PostgreSQL Parallel
    lines.append("### PostgreSQL - Parallel Query")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| max_worker_processes | `{config.get('PG_MAX_WORKER_PROCESSES', 'N/A')}` |")
    lines.append(f"| max_parallel_workers | `{config.get('PG_MAX_PARALLEL_WORKERS', 'N/A')}` |")
    lines.append(f"| max_parallel_workers_per_gather | `{config.get('PG_MAX_PARALLEL_WORKERS_PER_GATHER', 'N/A')}` |")
    lines.append(f"| jit | `{config.get('PG_JIT', 'N/A')}` |")
    lines.append("")

    # OS Tuning
    lines.append("### OS Tuning")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| vm.nr_hugepages | `{config.get('VM_NR_HUGEPAGES', 'N/A')}` |")
    lines.append(f"| vm.swappiness | `{config.get('VM_SWAPPINESS', 'N/A')}` |")
    lines.append(f"| vm.dirty_background_ratio | `{config.get('VM_DIRTY_BACKGROUND_RATIO', 'N/A')}` |")
    lines.append(f"| vm.dirty_ratio | `{config.get('VM_DIRTY_RATIO', 'N/A')}` |")
    lines.append("")

    # Block Device Tuning
    lines.append("### Block Device Tuning")
    lines.append("")
    lines.append("| Device | read_ahead_kb | scheduler | nomerges |")
    lines.append("|--------|---------------|-----------|----------|")
    lines.append(f"| md0 (DATA) | `{config.get('DATA_READ_AHEAD_KB', 'N/A')}` | `{config.get('DATA_SCHEDULER', 'N/A')}` | `{config.get('DATA_NOMERGES', 'N/A')}` |")
    lines.append(f"| md1 (WAL) | `{config.get('WAL_READ_AHEAD_KB', 'N/A')}` | `{config.get('WAL_SCHEDULER', 'N/A')}` | `{config.get('WAL_NOMERGES', 'N/A')}` |")
    lines.append("")

    # Benchmark Config
    lines.append("### Benchmark Config")
    lines.append("")
    lines.append("| Setting | Value |")
    lines.append("|---------|-------|")
    lines.append(f"| pgbench_scale | `{config.get('PGBENCH_SCALE', 'N/A')}` |")
    lines.append(f"| pgbench_duration | `{config.get('PGBENCH_DURATION', 'N/A')}` |")
    lines.append(f"| pgbench_clients_heavy | `{config.get('PGBENCH_CLIENTS_HEAVY', 'N/A')}` |")
    lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    sys.path.insert(0, str(__file__).rsplit("/", 2)[0])
    from core.config_loader import load_config

    if len(sys.argv) != 3:
        print("Usage: verifier.py <hardware> <workload>")
        print("Example: verifier.py r8g.2xlarge tpc-b")
        sys.exit(1)

    hardware = sys.argv[1]
    workload = sys.argv[2]

    config = load_config(hardware, workload)
    results = verify_config(config)
    print_verification(results)

    # Print config matrix
    print("\n" + generate_config_matrix(config))
