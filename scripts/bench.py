#!/usr/bin/env python3
"""
bench.py - Benchmark Runner (Pure)

A pluggable benchmark runner that:
1. Runs all commands defined in scenario (begin, parallel, end phases)
2. Captures ALL output from each command
3. Renders everything into a markdown report for AI evaluation

Usage:
    sudo python3 bench.py <scenario_id>
    sudo python3 bench.py 1           # Run scenario 1
    sudo python3 bench.py 1-10        # Run scenarios 1 through 10
    sudo python3 bench.py --list      # Show all scenarios

Result: results/{topology}_{scenario_id}_{timestamp}.md
"""
import json
import os
import re
import shlex
import signal
import socket
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

SCRIPT_DIR = Path(__file__).parent.resolve()
SCENARIOS_FILE = SCRIPT_DIR / "scenarios.json"
RESULTS_BASE = SCRIPT_DIR / "results"
CONFIG_DIR = SCRIPT_DIR / "config"


# =============================================================================
# CONFIG READER
# =============================================================================

def load_env_file(filepath: Path) -> Dict[str, str]:
    """Load key=value pairs from .env file, ignoring comments"""
    config = {}
    if not filepath.exists():
        return config

    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                config[key.strip()] = value.strip().strip('"')
    return config


def load_all_configs() -> Dict[str, Dict[str, str]]:
    """Load all configs from scripts/config/*.env"""
    configs = {}
    for env_file in ['os.env', 'base.env', 'primary.env']:
        filepath = CONFIG_DIR / env_file
        configs[env_file] = load_env_file(filepath)
    return configs


# =============================================================================
# CONFIG VERIFICATION - Compare local intent vs actual remote values
# =============================================================================

def ssh_cmd(host: str, cmd: str, timeout: int = 10) -> str:
    """Run SSH command to remote host and return output"""
    try:
        result = subprocess.run(
            ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
             "-o", "LogLevel=ERROR", f"ubuntu@{host}", cmd],
            capture_output=True, text=True, timeout=timeout
        )
        return result.stdout.strip()
    except Exception as e:
        return f"ERROR: {e}"


def collect_actual_config(db_host: str, pg_host: str, pg_port: str) -> Dict[str, str]:
    """Collect actual configuration values from remote DB host"""
    actual = {}

    # OS - Memory (via SSH to DB host)
    os_mem_cmd = "cat /proc/sys/vm/swappiness /proc/sys/vm/dirty_ratio /proc/sys/vm/dirty_background_ratio /proc/sys/vm/dirty_expire_centisecs /proc/sys/vm/dirty_writeback_centisecs /proc/sys/vm/overcommit_memory /proc/sys/vm/overcommit_ratio /proc/sys/vm/min_free_kbytes /proc/sys/vm/zone_reclaim_mode /proc/sys/vm/nr_hugepages 2>/dev/null | tr '\\n' ' '"
    os_mem = ssh_cmd(db_host, os_mem_cmd).split()
    if len(os_mem) >= 10:
        actual['vm.swappiness'] = os_mem[0]
        actual['vm.dirty_ratio'] = os_mem[1]
        actual['vm.dirty_background_ratio'] = os_mem[2]
        actual['vm.dirty_expire_centisecs'] = os_mem[3]
        actual['vm.dirty_writeback_centisecs'] = os_mem[4]
        actual['vm.overcommit_memory'] = os_mem[5]
        actual['vm.overcommit_ratio'] = os_mem[6]
        actual['vm.min_free_kbytes'] = os_mem[7]
        actual['vm.zone_reclaim_mode'] = os_mem[8]
        actual['vm.nr_hugepages'] = os_mem[9]

    # OS - Kernel
    kernel_cmd = "cat /proc/sys/kernel/sched_autogroup_enabled /proc/sys/kernel/numa_balancing 2>/dev/null | tr '\\n' ' '"
    kernel = ssh_cmd(db_host, kernel_cmd).split()
    if len(kernel) >= 2:
        actual['kernel.sched_autogroup_enabled'] = kernel[0]
        actual['kernel.numa_balancing'] = kernel[1]

    # OS - TCP
    tcp_cmd = "cat /proc/sys/net/core/somaxconn /proc/sys/net/core/netdev_max_backlog /proc/sys/net/ipv4/tcp_max_syn_backlog /proc/sys/net/ipv4/tcp_tw_reuse /proc/sys/net/ipv4/tcp_fin_timeout /proc/sys/net/ipv4/tcp_keepalive_time /proc/sys/net/ipv4/tcp_keepalive_intvl /proc/sys/net/ipv4/tcp_keepalive_probes /proc/sys/net/core/default_qdisc /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null | tr '\\n' ' '"
    tcp = ssh_cmd(db_host, tcp_cmd).split()
    if len(tcp) >= 10:
        actual['net.core.somaxconn'] = tcp[0]
        actual['net.core.netdev_max_backlog'] = tcp[1]
        actual['net.ipv4.tcp_max_syn_backlog'] = tcp[2]
        actual['net.ipv4.tcp_tw_reuse'] = tcp[3]
        actual['net.ipv4.tcp_fin_timeout'] = tcp[4]
        actual['net.ipv4.tcp_keepalive_time'] = tcp[5]
        actual['net.ipv4.tcp_keepalive_intvl'] = tcp[6]
        actual['net.ipv4.tcp_keepalive_probes'] = tcp[7]
        actual['net.core.default_qdisc'] = tcp[8]
        actual['net.ipv4.tcp_congestion_control'] = tcp[9]

    # Disk - RAID read_ahead
    disk_cmd = "cat /sys/block/md0/queue/read_ahead_kb /sys/block/md1/queue/read_ahead_kb 2>/dev/null | tr '\\n' ' '"
    disk = ssh_cmd(db_host, disk_cmd).split()
    if len(disk) >= 2:
        actual['DATA read_ahead_kb'] = disk[0]
        actual['WAL read_ahead_kb'] = disk[1]

    # THP
    thp_cmd = "cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -o '\\[.*\\]' | tr -d '[]'"
    actual['transparent_hugepage'] = ssh_cmd(db_host, thp_cmd)

    # PostgreSQL settings via psql
    pg_settings = [
        'shared_buffers', 'effective_cache_size', 'work_mem', 'maintenance_work_mem',
        'huge_pages', 'max_connections', 'wal_level', 'wal_compression', 'wal_sync_method',
        'wal_buffers', 'wal_writer_delay', 'synchronous_commit', 'max_wal_size', 'min_wal_size',
        'checkpoint_timeout', 'checkpoint_completion_target', 'bgwriter_delay',
        'bgwriter_lru_maxpages', 'bgwriter_lru_multiplier', 'effective_io_concurrency',
        'random_page_cost', 'seq_page_cost', 'commit_delay', 'commit_siblings',
        'autovacuum', 'track_counts', 'autovacuum_vacuum_scale_factor',
        'autovacuum_analyze_scale_factor', 'autovacuum_vacuum_cost_limit',
        'autovacuum_vacuum_cost_delay', 'jit'
    ]

    pg_query = f"SELECT name || '=' || setting FROM pg_settings WHERE name IN ({','.join([repr(s) for s in pg_settings])}) ORDER BY name;"
    pg_cmd = f"PGPASSWORD=postgres psql -h {pg_host} -p {pg_port} -U postgres -t -A -c \"{pg_query}\" 2>/dev/null"
    pg_output = subprocess.run(pg_cmd, shell=True, capture_output=True, text=True, timeout=10).stdout

    for line in pg_output.strip().split('\n'):
        if '=' in line:
            key, val = line.split('=', 1)
            actual[f'pg_{key}'] = val

    return actual


def normalize_pg_value(name: str, raw_value: str, local_value: str) -> str:
    """Normalize PostgreSQL values for comparison (convert units)"""
    if not raw_value or raw_value == 'N/A':
        return raw_value

    try:
        # Memory settings (8kB pages -> human readable)
        if name in ['shared_buffers', 'effective_cache_size']:
            pages = int(raw_value)
            gb = pages * 8 // 1024 // 1024
            return f"{gb}GB"
        elif name in ['work_mem', 'maintenance_work_mem', 'wal_buffers']:
            kb = int(raw_value)
            mb = kb // 1024
            return f"{mb}MB"
        elif name in ['max_wal_size', 'min_wal_size']:
            # Already in MB
            return f"{raw_value}MB"
        elif name in ['checkpoint_timeout']:
            # Seconds -> minutes
            secs = int(raw_value)
            mins = secs // 60
            return f"{mins}min"
        elif name in ['wal_writer_delay', 'bgwriter_delay', 'autovacuum_vacuum_cost_delay']:
            return f"{raw_value}ms"
    except:
        pass

    return raw_value


def check_config_match(local: str, actual: str) -> str:
    """Check if local and actual values match, return status emoji"""
    if not local or not actual or actual == 'N/A':
        return "⚠️"

    # Normalize for comparison
    l = str(local).lower().strip().replace("'", "").replace('"', '')
    a = str(actual).lower().strip().replace("'", "").replace('"', '')

    if l == a:
        return "✓"
    else:
        return "✗"


# Config verification mapping: (display_name, env_key, source_file, actual_key, pg_setting_name)
CONFIG_VERIFY = {
    "OS - Memory": [
        ("vm.swappiness", "VM_SWAPPINESS", "os.env", "vm.swappiness", None),
        ("vm.dirty_ratio", "VM_DIRTY_RATIO", "os.env", "vm.dirty_ratio", None),
        ("vm.dirty_background_ratio", "VM_DIRTY_BACKGROUND_RATIO", "os.env", "vm.dirty_background_ratio", None),
        ("vm.dirty_expire_centisecs", "VM_DIRTY_EXPIRE_CENTISECS", "os.env", "vm.dirty_expire_centisecs", None),
        ("vm.dirty_writeback_centisecs", "VM_DIRTY_WRITEBACK_CENTISECS", "os.env", "vm.dirty_writeback_centisecs", None),
        ("vm.overcommit_memory", "VM_OVERCOMMIT_MEMORY", "os.env", "vm.overcommit_memory", None),
        ("vm.overcommit_ratio", "VM_OVERCOMMIT_RATIO", "os.env", "vm.overcommit_ratio", None),
        ("vm.min_free_kbytes", "VM_MIN_FREE_KBYTES", "os.env", "vm.min_free_kbytes", None),
        ("vm.zone_reclaim_mode", "VM_ZONE_RECLAIM_MODE", "os.env", "vm.zone_reclaim_mode", None),
        ("vm.nr_hugepages", "VM_NR_HUGEPAGES", "os.env", "vm.nr_hugepages", None),
    ],
    "OS - Kernel": [
        ("kernel.sched_autogroup_enabled", "KERNEL_SCHED_AUTOGROUP_ENABLED", "os.env", "kernel.sched_autogroup_enabled", None),
        ("kernel.numa_balancing", "KERNEL_NUMA_BALANCING", "os.env", "kernel.numa_balancing", None),
    ],
    "OS - TCP/Network": [
        ("net.core.somaxconn", "NET_CORE_SOMAXCONN", "os.env", "net.core.somaxconn", None),
        ("net.core.netdev_max_backlog", "NET_CORE_NETDEV_MAX_BACKLOG", "os.env", "net.core.netdev_max_backlog", None),
        ("net.ipv4.tcp_max_syn_backlog", "NET_IPV4_TCP_MAX_SYN_BACKLOG", "os.env", "net.ipv4.tcp_max_syn_backlog", None),
        ("net.ipv4.tcp_tw_reuse", "NET_IPV4_TCP_TW_REUSE", "os.env", "net.ipv4.tcp_tw_reuse", None),
        ("net.ipv4.tcp_fin_timeout", "NET_IPV4_TCP_FIN_TIMEOUT", "os.env", "net.ipv4.tcp_fin_timeout", None),
        ("net.ipv4.tcp_keepalive_time", "NET_IPV4_TCP_KEEPALIVE_TIME", "os.env", "net.ipv4.tcp_keepalive_time", None),
        ("net.ipv4.tcp_keepalive_intvl", "NET_IPV4_TCP_KEEPALIVE_INTVL", "os.env", "net.ipv4.tcp_keepalive_intvl", None),
        ("net.ipv4.tcp_keepalive_probes", "NET_IPV4_TCP_KEEPALIVE_PROBES", "os.env", "net.ipv4.tcp_keepalive_probes", None),
        ("net.core.default_qdisc", "NET_CORE_DEFAULT_QDISC", "os.env", "net.core.default_qdisc", None),
        ("net.ipv4.tcp_congestion_control", "NET_IPV4_TCP_CONGESTION_CONTROL", "os.env", "net.ipv4.tcp_congestion_control", None),
    ],
    "Disk / RAID": [
        ("DATA read_ahead_kb", "DATA_READ_AHEAD_KB", "base.env", "DATA read_ahead_kb", None),
        ("WAL read_ahead_kb", "WAL_READ_AHEAD_KB", "base.env", "WAL read_ahead_kb", None),
        ("transparent_hugepage", "THP_ENABLED", "os.env", "transparent_hugepage", None),
    ],
    "PostgreSQL - Memory": [
        ("shared_buffers", "PG_SHARED_BUFFERS", "primary.env", "pg_shared_buffers", "shared_buffers"),
        ("effective_cache_size", "PG_EFFECTIVE_CACHE_SIZE", "primary.env", "pg_effective_cache_size", "effective_cache_size"),
        ("work_mem", "PG_WORK_MEM", "primary.env", "pg_work_mem", "work_mem"),
        ("maintenance_work_mem", "PG_MAINTENANCE_WORK_MEM", "primary.env", "pg_maintenance_work_mem", "maintenance_work_mem"),
        ("huge_pages", "PG_HUGE_PAGES", "primary.env", "pg_huge_pages", None),
        ("max_connections", "PG_MAX_CONNECTIONS", "primary.env", "pg_max_connections", None),
    ],
    "PostgreSQL - WAL": [
        ("wal_level", "PG_WAL_LEVEL", "primary.env", "pg_wal_level", None),
        ("wal_compression", "PG_WAL_COMPRESSION", "primary.env", "pg_wal_compression", None),
        ("wal_sync_method", "PG_WAL_SYNC_METHOD", "primary.env", "pg_wal_sync_method", None),
        ("wal_buffers", "PG_WAL_BUFFERS", "primary.env", "pg_wal_buffers", "wal_buffers"),
        ("wal_writer_delay", "PG_WAL_WRITER_DELAY", "primary.env", "pg_wal_writer_delay", "wal_writer_delay"),
        ("synchronous_commit", "PG_SYNCHRONOUS_COMMIT", "primary.env", "pg_synchronous_commit", None),
        ("max_wal_size", "PG_MAX_WAL_SIZE", "primary.env", "pg_max_wal_size", "max_wal_size"),
        ("min_wal_size", "PG_MIN_WAL_SIZE", "primary.env", "pg_min_wal_size", "min_wal_size"),
    ],
    "PostgreSQL - Checkpoint & BGWriter": [
        ("checkpoint_timeout", "PG_CHECKPOINT_TIMEOUT", "primary.env", "pg_checkpoint_timeout", "checkpoint_timeout"),
        ("checkpoint_completion_target", "PG_CHECKPOINT_COMPLETION_TARGET", "primary.env", "pg_checkpoint_completion_target", None),
        ("bgwriter_delay", "PG_BGWRITER_DELAY", "primary.env", "pg_bgwriter_delay", "bgwriter_delay"),
        ("bgwriter_lru_maxpages", "PG_BGWRITER_LRU_MAXPAGES", "primary.env", "pg_bgwriter_lru_maxpages", None),
        ("bgwriter_lru_multiplier", "PG_BGWRITER_LRU_MULTIPLIER", "primary.env", "pg_bgwriter_lru_multiplier", None),
        ("commit_delay", "PG_COMMIT_DELAY", "primary.env", "pg_commit_delay", None),
        ("commit_siblings", "PG_COMMIT_SIBLINGS", "primary.env", "pg_commit_siblings", None),
    ],
    "PostgreSQL - Autovacuum": [
        ("autovacuum", "PG_AUTOVACUUM", "primary.env", "pg_autovacuum", None),
        ("track_counts", "PG_TRACK_COUNTS", "primary.env", "pg_track_counts", None),
        ("autovacuum_vacuum_scale_factor", "PG_AUTOVACUUM_VACUUM_SCALE_FACTOR", "primary.env", "pg_autovacuum_vacuum_scale_factor", None),
        ("autovacuum_analyze_scale_factor", "PG_AUTOVACUUM_ANALYZE_SCALE_FACTOR", "primary.env", "pg_autovacuum_analyze_scale_factor", None),
        ("autovacuum_vacuum_cost_limit", "PG_AUTOVACUUM_VACUUM_COST_LIMIT", "primary.env", "pg_autovacuum_vacuum_cost_limit", None),
        ("autovacuum_vacuum_cost_delay", "PG_AUTOVACUUM_VACUUM_COST_DELAY", "primary.env", "pg_autovacuum_vacuum_cost_delay", "autovacuum_vacuum_cost_delay"),
    ],
    "PostgreSQL - I/O & Query": [
        ("effective_io_concurrency", "PG_EFFECTIVE_IO_CONCURRENCY", "primary.env", "pg_effective_io_concurrency", None),
        ("random_page_cost", "PG_RANDOM_PAGE_COST", "primary.env", "pg_random_page_cost", None),
        ("seq_page_cost", "PG_SEQ_PAGE_COST", "primary.env", "pg_seq_page_cost", None),
        ("jit", "PG_JIT", "primary.env", "pg_jit", None),
    ],
}


def render_config_verification(configs: Dict[str, Dict[str, str]], actual: Dict[str, str]) -> str:
    """Render configuration verification matrix with Local vs Actual comparison"""
    lines = ["## Configuration Verification", ""]

    total_match = 0
    total_mismatch = 0

    for category, params in CONFIG_VERIFY.items():
        lines.append(f"### {category}")
        lines.append("| Parameter | Local | Actual | Status |")
        lines.append("|-----------|-------|--------|:------:|")

        for display_name, env_key, source_file, actual_key, pg_name in params:
            local_val = configs.get(source_file, {}).get(env_key, "N/A")
            actual_val = actual.get(actual_key, "N/A")

            # Normalize PG values for display
            if pg_name:
                actual_val = normalize_pg_value(pg_name, actual_val, local_val)

            status = check_config_match(local_val, actual_val)
            if status == "✓":
                total_match += 1
            elif status == "✗":
                total_mismatch += 1

            lines.append(f"| {display_name} | {local_val} | {actual_val} | {status} |")

        lines.append("")

    # Summary
    total = total_match + total_mismatch
    if total > 0:
        lines.insert(2, f"> **Verification Summary:** {total_match}/{total} matched, {total_mismatch} mismatched")
        lines.insert(3, "")

    return "\n".join(lines)


def get_target_hardware(configs: Dict[str, Dict[str, str]]) -> Dict:
    """Get target hardware from primary.env (DB node specs)"""
    primary = configs.get('primary.env', {})
    return {
        "instance_type": primary.get("INSTANCE_TYPE", "r8g.xlarge"),
        "vcpu": int(primary.get("VCPU", 4)),
        "ram_gb": int(primary.get("RAM_GB", 32)),
        "storage": "4x gp3 RAID0 (DATA) + 4x gp3 RAID0 (WAL)",
        "pg_version": primary.get("PG_VERSION", "16"),
    }


def get_runner_hardware() -> Dict:
    """Get runner (benchmark driver) hardware from local machine"""
    vcpu = os.cpu_count() or 4
    ram_gb = 8  # default
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    ram_kb = int(line.split()[1])
                    ram_gb = ram_kb // (1024 * 1024)
                    break
    except:
        pass

    return {
        "instance_type": "c8g.xlarge",
        "vcpu": vcpu,
        "ram_gb": ram_gb,
        "private_ip": get_private_ip(),
    }


def parse_pgbench_flags(cmd_str: str) -> Dict[str, str]:
    """Parse pgbench command flags for detailed breakdown"""
    flags = {}

    # -c clients
    m = re.search(r'-c\s+(\d+)', cmd_str)
    if m:
        flags['-c'] = m.group(1)

    # -j threads
    m = re.search(r'-j\s+(\d+)', cmd_str)
    if m:
        flags['-j'] = m.group(1)

    # -T duration
    m = re.search(r'-T\s+(\d+)', cmd_str)
    if m:
        flags['-T'] = m.group(1)

    # -P progress
    m = re.search(r'-P\s+(\d+)', cmd_str)
    if m:
        flags['-P'] = m.group(1)

    # -M protocol (simple/extended/prepared)
    m = re.search(r'-M\s+(\w+)', cmd_str)
    if m:
        flags['-M'] = m.group(1)

    # -S select only
    if ' -S' in cmd_str or cmd_str.endswith('-S'):
        flags['-S'] = 'yes'

    # -C connect per transaction
    if ' -C' in cmd_str or cmd_str.endswith('-C'):
        flags['-C'] = 'yes'

    # --no-vacuum
    if '--no-vacuum' in cmd_str:
        flags['--no-vacuum'] = 'yes'

    return flags


def get_dataset_info(scenario: Dict) -> Dict[str, str]:
    """Determine dataset type and scale factor from scenario"""
    scenario_id = scenario.get('id', '')

    # Detect dataset type
    if 'tpcb' in scenario_id or 'pgbench' in scenario_id.lower():
        dataset = "TPC-B"
    elif 'tpcc' in scenario_id:
        dataset = "TPC-C"
    elif 'tpch' in scenario_id:
        dataset = "TPC-H"
    elif 'fio' in scenario_id:
        dataset = "FIO (synthetic I/O)"
    else:
        dataset = "pgbench TPC-B"

    # Get scale factor from scenario or default
    scale = scenario.get('scale', 1250)

    # Estimate size based on scale (pgbench: ~16MB per scale factor)
    size_mb = scale * 16 // 1000  # ~20GB for scale 1250

    return {
        "dataset": dataset,
        "scale_factor": str(scale),
        "estimated_size": f"~{size_mb}GB",
    }


def get_benchmark_tool(scenario: Dict) -> str:
    """Determine benchmark tool from scenario"""
    parallel = scenario.get('parallel', [])
    for cmd in parallel:
        if cmd.get('primary'):
            name = cmd.get('name', '').lower()
            if 'pgbench' in name:
                return 'pgbench'
            elif 'fio' in name:
                return 'fio'
            elif 'sysbench' in name:
                return 'sysbench'
    return 'unknown'


def get_transaction_type(flags: Dict[str, str]) -> str:
    """Determine transaction type from pgbench flags"""
    if flags.get('-S') == 'yes':
        return "SELECT-only (-S)"
    elif flags.get('-C') == 'yes':
        return "Connect-per-txn (-C)"
    else:
        return "TPC-B (default)"


def get_protocol(flags: Dict[str, str]) -> str:
    """Get query protocol from pgbench -M flag"""
    m = flags.get('-M', 'simple')
    protocols = {
        'simple': 'simple',
        'extended': 'extended',
        'prepared': 'prepared',
    }
    return protocols.get(m, 'simple')


def parse_pgbench(output: str) -> Dict[str, str]:
    """Parse pgbench output for summary metrics"""
    metrics = {}

    # TPS: tps = 12461.565404 (without initial connection time)
    tps_match = re.search(r'tps = ([\d.]+)', output)
    if tps_match:
        tps = float(tps_match.group(1))
        metrics["TPS"] = f"{tps:,.0f}"

    # Latency avg: latency average = 7.947 ms
    lat_avg = re.search(r'latency average = ([\d.]+) ms', output)
    if lat_avg:
        metrics["Latency (avg)"] = f"{lat_avg.group(1)}ms"

    # Latency stddev: latency stddev = 10.056 ms
    lat_std = re.search(r'latency stddev = ([\d.]+) ms', output)
    if lat_std:
        metrics["Latency (stddev)"] = f"{lat_std.group(1)}ms"

    return metrics


def parse_cache_hit(collector_output: str) -> Optional[str]:
    """Parse cache hit percentage from pg_cache_hit_ratio output"""
    # Format: cache_hit_pct | blks_hit | blks_read
    #                 95.90 | ...
    match = re.search(r'(\d+\.?\d*)\s*\|', collector_output)
    if match:
        return f"{float(match.group(1)):.1f}%"
    return None


def render_golden_fact_template(
    scenario_topology: str,
    scenario_workload: str,
    timestamp: str,
    result_filename: str,
) -> str:
    """Render Golden Fact Template section for baking agent"""
    date_mmddyy = datetime.now().strftime("%m%d%y")

    template = f'''## Golden Fact Template

> **Instructions for Baking Agent:**
> 1. Analyze benchmark results above
> 2. Check ceiling criteria (CPU >= 90% OR disk util >= 80%)
> 3. Verify Little's Law (TPS ~= clients / latency)
> 4. Fill Observation, Pitfall, Verdict sections
> 5. If CEILING CONFIRMED, save as: `golden-facts/{{Topology}}x{{Workload}}-{{MMDDYY}}.md`

---

# Golden Fact: {scenario_topology.capitalize()} x {scenario_workload.upper()}

**ID:** {scenario_topology.capitalize()}x{scenario_workload.upper()}-{date_mmddyy}
**Date:** {{date}}
**Hardware:** {{instance_type}} ({{vcpu}} vCPU, {{ram}}GB RAM)
**Scenario:** {{scenario_id}} - {{scenario_name}}

## Ceiling Proof

### Metrics
| Metric | Value |
|--------|-------|
| TPS | {{tps}} |
| TPS/Core | {{tps_per_core}} |
| Latency (avg) | {{latency_avg}} |
| Cache Hit | {{cache_hit_pct}} |

### Little's Law Verification
```
TPS_theoretical = clients / latency
                = {{clients}} / {{latency_sec}}
                = {{theoretical_tps}}

TPS_actual      = {{actual_tps}}
Efficiency      = {{efficiency}}%
```

### Bottleneck Analysis
| Resource | Utilization | Bottleneck? |
|----------|-------------|-------------|
| CPU | {{cpu_pct}}% | {{yes/no}} |
| Disk (DATA) | {{data_util}}% | {{yes/no}} |
| Disk (WAL) | {{wal_util}}% | {{yes/no}} |
| WAL fsync | {{wal_sync_ms}}ms | {{yes/no}} |

**Primary Bottleneck:** {{bottleneck_description}}

## Configuration

### OS - Memory
| Parameter | Value |
|-----------|-------|
{{os_memory_configs}}

### OS - TCP
| Parameter | Value |
|-----------|-------|
{{os_tcp_configs}}

### Disk
| Parameter | Value |
|-----------|-------|
{{disk_configs}}

### PostgreSQL
| Parameter | Value |
|-----------|-------|
{{postgresql_configs}}

## Observation

{{observations_about_what_worked_and_why}}

## Pitfall

{{things_to_watch_out_for_edge_cases_warnings}}

## Verdict

{{CEILING CONFIRMED | CEILING NOT REACHED | NEEDS MORE TESTING}}

{{verdict_explanation}}

---
*Baked from: results/{result_filename}*
'''
    return template


def detect_hardware_type() -> str:
    """Detect hardware type from instance metadata or config"""
    # Try EC2 metadata
    try:
        import urllib.request
        token_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
            method="PUT"
        )
        with urllib.request.urlopen(token_req, timeout=2) as resp:
            token = resp.read().decode()
        
        type_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/instance-type",
            headers={"X-aws-ec2-metadata-token": token}
        )
        with urllib.request.urlopen(type_req, timeout=2) as resp:
            return resp.read().decode().strip()
    except:
        pass
    
    # Fallback: derive from RAM
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    ram_kb = int(line.split()[1])
                    ram_gb = ram_kb // (1024 * 1024)
                    vcpu = os.cpu_count() or 4
                    # Guess based on specs
                    if ram_gb >= 60:
                        return "r8g.2xlarge"
                    elif ram_gb >= 28:
                        if vcpu >= 8:
                            return "c8g.4xlarge" 
                        return "r8g.xlarge"
                    else:
                        return "r8g.large"
    except:
        pass
    
    return "unknown"


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class CommandResult:
    name: str
    cmd_str: str
    output: str
    success: bool
    is_primary: bool = False


# =============================================================================
# TOPOLOGY & HARDWARE DETECTION
# =============================================================================

IP_ROLES = {
    "10.0.1.10": "primary",
    "10.0.1.11": "replica",
    "10.0.1.20": "proxy",
}


def get_private_ip() -> str:
    """Get this node's private IP"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("10.0.1.1", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "unknown"


def detect_topology() -> str:
    """Auto-detect topology based on private IP and reachable nodes"""
    my_ip = get_private_ip()
    
    def check_host(host, port, timeout=1):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(timeout)
            s.connect((host, port))
            s.close()
            return True
        except:
            return False
    
    has_proxy = check_host("10.0.1.20", 6432)
    has_replica = check_host("10.0.1.11", 5432)
    
    if has_proxy and has_replica:
        return "primary-replica-proxy"
    elif has_proxy:
        return "proxy-single"
    elif has_replica:
        return "primary-replica"
    else:
        return "single-node"


def get_hardware_context() -> Dict:
    """Get hardware context for benchmark parameters"""
    vcpu = os.cpu_count() or 4
    ram_gb = 32
    
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    ram_kb = int(line.split()[1])
                    ram_gb = ram_kb // (1024 * 1024)
                    break
    except:
        pass
    
    return {
        "vcpu": vcpu,
        "ram_gb": ram_gb,
        "threads": vcpu,
        "clients": vcpu * 12,
        "scale": 1250,
    }


def get_target_name(variables: Dict) -> str:
    """Determine target name (primary, replica, proxy, etc)"""
    host = variables.get('host')
    if host and host != "localhost" and host != "127.0.0.1":
        # Resolve role from IP
        target = IP_ROLES.get(host, host)
    else:
        # Use local role
        my_ip = get_private_ip()
        target = IP_ROLES.get(my_ip, "local")
    
    # Clean target name for filesystem
    return target.lower().replace('.', '_')


# =============================================================================
# HELPERS
# =============================================================================

def load_scenarios() -> Dict:
    """Load scenarios from JSON"""
    with open(SCENARIOS_FILE) as f:
        return json.load(f)


def substitute_vars(text: str, variables: Dict) -> str:
    """Substitute {var} placeholders in text"""
    result = str(text)
    for key, value in variables.items():
        result = result.replace(f"{{{key}}}", str(value))
    return result


def collect_system_info() -> str:
    """Collect hardware and system configuration"""
    def run_cmd(cmd: str) -> str:
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            return result.stdout.strip()
        except:
            return ""
    
    sections = [
        "=== INSTANCE ===",
        run_cmd("uname -a"),
        run_cmd("lscpu | grep -E '^CPU\\(s\\)|^Model name|^Architecture'"),
        run_cmd("free -h"),
        "",
        "=== OS TUNING ===",
        run_cmd("sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio 2>/dev/null"),
        "",
        "=== DISK - RAID ===",
        run_cmd("cat /proc/mdstat"),
        "",
        "=== DISK - MOUNT ===",
        run_cmd("mount | grep -E '/data|/wal'"),
        run_cmd("df -h /data /wal 2>/dev/null"),
        "",
        "=== BLOCK DEVICE TUNING ===",
        run_cmd("cat /sys/block/md0/queue/read_ahead_kb 2>/dev/null | xargs -I{} echo 'md0 read_ahead_kb: {}'"),
        run_cmd("cat /sys/block/md1/queue/read_ahead_kb 2>/dev/null | xargs -I{} echo 'md1 read_ahead_kb: {}'"),
    ]
    return "\n".join(sections)


# =============================================================================
# PARSERS (for summary extraction)
# =============================================================================

def parse_fio(output: str) -> Dict[str, str]:
    """Parse FIO output for summary metrics"""
    metrics = {}
    
    iops = re.search(r'IOPS=(\d+\.?\d*[kKmM]?)', output)
    if iops:
        metrics["IOPS"] = iops.group(1)
    
    bw = re.search(r'BW=(\d+\.?\d*\s*[kKmMgG]?i?B/s)', output)
    if bw:
        metrics["Bandwidth"] = bw.group(1)
    
    lat = re.search(r'lat.*avg=\s*(\d+\.?\d*)', output)
    if lat:
        metrics["Avg Latency"] = f"{lat.group(1)}us"
    
    p99 = re.search(r'99\.00th=\[\s*(\d+)\]', output)
    if p99:
        metrics["P99 Latency"] = f"{p99.group(1)}us"
    
    return metrics


# =============================================================================
# SCENARIO RUNNER
# =============================================================================

def run_scenario(scenario_id: str, topology: str, variables_override: Dict = {}) -> Optional[Path]:
    """Run a complete benchmark scenario"""
    data = load_scenarios()
    scenarios = data.get("scenarios", {})
    disks = data.get("disks", {})
    defaults = data.get("defaults", {})
    
    if scenario_id not in scenarios:
        print(f"Error: Scenario {scenario_id} not found")
        return None
    
    scenario = scenarios[scenario_id]
    disk = disks.get(scenario.get("target_disk", "data"), {})
    hw = get_hardware_context()
    hardware = detect_hardware_type()
    
    # Build variables
    host = variables_override.get("host", "localhost")
    port = variables_override.get("port", "5432")

    # Dynamic clients based on connection path (direct vs pgcat)
    if str(port) == "6432" and "clients_pgcat" in scenario:
        clients = scenario["clients_pgcat"]
    else:
        clients = scenario.get("clients", hw["clients"])

    variables = {
        "duration": scenario.get("duration", defaults.get("duration", 60)),
        "clients": clients,
        "threads": scenario.get("threads", hw["threads"]),
        "scale": scenario.get("scale", hw["scale"]),
        "warehouses": scenario.get("warehouses", 200),
        "vcpu": hw["vcpu"],
        "ram_gb": hw["ram_gb"],
        "host": host,
        "port": port,
        "db_host": variables_override.get("db_host", host),  # For SSH to DB node
    }
    duration = variables["duration"]
    
    print(f"\n{'='*70}")
    print(f"SCENARIO {scenario_id}: {scenario['name']}")
    print(f"{'='*70}")
    print(f"Topology: {topology}")
    print(f"Hardware: {hardware} ({hw['vcpu']} vCPU, {hw['ram_gb']} GB RAM)")
    print(f"Description: {substitute_vars(scenario['desc'], variables)}")
    print(f"Target: {disk.get('name', 'N/A')} ({disk.get('device', 'N/A')})")
    print(f"Duration: {duration}s")
    
    # Setup output directory (flat structure, temp files in /tmp)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = Path("/tmp") / f"bench-{scenario.get('id', scenario_id)}-{timestamp}"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Collect system info
    print("\nCollecting system info...")
    system_info = collect_system_info()
    
    # Build iostat filter
    volumes = disk.get("volumes", [])
    iostat_filter = "|".join(volumes) if volumes else "md0|md1"
    
    command_results: List[CommandResult] = []
    
    # === BEGIN PHASE ===
    begin_cmds = scenario.get("begin", [])
    if begin_cmds:
        print("\n--- Begin Phase ---")
        for cmd_def in begin_cmds:
            cmd = [substitute_vars(str(c), variables) for c in cmd_def.get("cmd", [])]
            cmd_str = " ".join(shlex.quote(c) for c in cmd)
            print(f"  Running: {cmd_def.get('name', 'cmd')}...")
            
            try:
                result = subprocess.run(cmd_str, shell=True, capture_output=True, text=True, timeout=60)
                output = result.stdout + result.stderr
            except Exception as e:
                output = str(e)
            
            command_results.append(CommandResult(
                name=f"begin:{cmd_def.get('name', 'cmd')}",
                cmd_str=cmd_str,
                output=output,
                success=True,
            ))
    
    # === PARALLEL PHASE ===
    parallel_cmds = scenario.get("parallel", [])
    background_procs = []
    primary_cmd = None
    
    print(f"\n--- Benchmark Phase ({duration}s) ---")
    
    try:
        # Start background collectors (iostat, mpstat)
        bg_variables = {**variables, "duration": duration + 10}
        for cmd_def in parallel_cmds:
            if cmd_def.get("primary", False):
                primary_cmd = cmd_def
                continue
            
            cmd = [substitute_vars(str(c), bg_variables) for c in cmd_def.get("cmd", [])]
            cmd_str = " ".join(shlex.quote(c) for c in cmd)
            output_file = output_dir / f"{cmd_def.get('name', 'bg')}_{timestamp}.txt"
            
            if cmd_def.get("filter_volumes", False):
                full_cmd = f"stdbuf -oL {cmd_str} | stdbuf -oL grep -E 'Device|{iostat_filter}' > {output_file} 2>&1"
            else:
                full_cmd = f"{cmd_str} > {output_file} 2>&1"
            
            proc = subprocess.Popen(full_cmd, shell=True, preexec_fn=os.setsid)
            background_procs.append({
                "proc": proc,
                "name": cmd_def.get("name", "bg"),
                "cmd_str": cmd_str,
                "output_file": output_file,
            })
            print(f"  Started: {cmd_def.get('name', 'bg')}")
        
        # Wait for backgrounds to start
        if background_procs:
            time.sleep(2)
        
        # Run primary command (FIO or pgbench)
        if primary_cmd:
            cmd = [substitute_vars(str(c), variables) for c in primary_cmd.get("cmd", [])]
            cmd_str = " ".join(shlex.quote(c) for c in cmd)
            output_file = output_dir / f"{primary_cmd.get('name', 'primary')}_{timestamp}.txt"
            
            print(f"  Running: {primary_cmd.get('name', 'primary')} ({duration}s)...")
            
            try:
                # For FIO, use --output flag; for others, capture stdout
                if cmd[0] == "fio":
                    cmd_with_output = cmd + [f"--output={output_file}"]
                    subprocess.run(cmd_with_output, check=True, timeout=duration + 120)
                    output = output_file.read_text() if output_file.exists() else "No output"
                else:
                    # For pgbench and other commands, capture stdout
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=duration + 120)
                    output = result.stdout + "\n" + result.stderr
                    output_file.write_text(output)
                success = True
            except Exception as e:
                output = str(e)
                success = False
            
            command_results.append(CommandResult(
                name=primary_cmd.get("name", "primary"),
                cmd_str=cmd_str,
                output=output,
                success=success,
                is_primary=True,
            ))
            
            # Cleanup test file
            cleanup_path = primary_cmd.get("cleanup")
            if cleanup_path:
                os.system(f"rm -f {cleanup_path} 2>/dev/null")

        # Stop background processes (now handled by finally but we can explicitly stop them here too for clean collection)
        if background_procs:
            print("  Stopping collectors...")
            for bg in background_procs:
                if bg["proc"].poll() is None:
                    try:
                        os.killpg(os.getpgid(bg["proc"].pid), signal.SIGTERM)
                    except:
                        pass
                
                output = bg["output_file"].read_text() if bg["output_file"].exists() else "No output"
                command_results.append(CommandResult(
                    name=bg["name"],
                    cmd_str=bg["cmd_str"],
                    output=output,
                    success=True,
                ))
    finally:
        # Ensure all background processes are stopped no matter what
        if background_procs:
            for bg in background_procs:
                if bg["proc"].poll() is None:  # Still running
                    try:
                        os.killpg(os.getpgid(bg["proc"].pid), signal.SIGTERM)
                        # Wait up to 2 seconds for graceful termination
                        for _ in range(20):
                            if bg["proc"].poll() is not None:
                                break
                            time.sleep(0.1)
                        # Force kill if still running
                        if bg["proc"].poll() is None:
                            os.killpg(os.getpgid(bg["proc"].pid), signal.SIGKILL)
                    except:
                        pass
    
    # === END PHASE ===
    end_cmds = scenario.get("end", [])
    if end_cmds:
        print("\n--- End Phase ---")
        for cmd_def in end_cmds:
            cmd = [substitute_vars(str(c), variables) for c in cmd_def.get("cmd", [])]
            cmd_str = " ".join(shlex.quote(c) for c in cmd)
            print(f"  Running: {cmd_def.get('name', 'cmd')}...")
            
            try:
                result = subprocess.run(cmd_str, shell=True, capture_output=True, text=True, timeout=60)
                output = result.stdout + result.stderr
            except Exception as e:
                output = str(e)
                
            command_results.append(CommandResult(
                name=f"end:{cmd_def.get('name', 'cmd')}",
                cmd_str=cmd_str,
                output=output,
                success=True,
            ))
    
    # === GENERATE REPORT ===
    report_path = generate_report(
        scenario=scenario,
        scenario_id=scenario_id,
        disk=disk,
        topology=topology,
        hardware=hardware,
        system_info=system_info,
        command_results=command_results,
        timestamp=timestamp,
        variables=variables,
    )
    
    # Print summary
    print_summary(command_results)
    print(f"\nReport: {report_path}")
    
    return report_path

def generate_report(
    scenario: Dict,
    scenario_id: str,
    disk: Dict,
    topology: str,
    hardware: str,
    system_info: str,
    command_results: List[CommandResult],
    timestamp: str,
    variables: Dict,
) -> Path:

    """
    Generate comprehensive markdown report following docs/RESULT-STRUCTURE.md.

    Structure:
    1. Header
    2. Benchmark Environment (Runner + Target specs)
    3. Scenario Context (definition, workload params, command flags)
    4. Summary
    5. Benchmark Output
    6. Diagnostics
    7. Configuration Matrix
    8. Golden Fact Template
    """

    # Load configs first to get target hardware
    configs = load_all_configs()
    target_hw = get_target_hardware(configs)
    runner_hw = get_runner_hardware()

    # Find primary result and parse metrics
    primary = next((r for r in command_results if r.is_primary), None)
    metrics = {}
    primary_cmd_str = ""
    pgbench_flags = {}

    if primary:
        primary_cmd_str = primary.cmd_str
        if "fio" in primary.name.lower():
            metrics = parse_fio(primary.output)
        elif "pgbench" in primary.name.lower():
            metrics = parse_pgbench(primary.output)
            pgbench_flags = parse_pgbench_flags(primary_cmd_str)

    desc = substitute_vars(scenario['desc'], variables)
    duration = variables.get('duration', 60)
    clients = variables.get('clients', scenario.get('clients', 100))
    threads = variables.get('threads', scenario.get('threads', 4))

    # Separate collectors from primary
    collectors = {r.name: r for r in command_results if not r.is_primary}

    # Extract cache hit from end phase collector
    cache_hit_collector = collectors.get('end:pg_cache_hit_ratio')
    if cache_hit_collector:
        cache_hit = parse_cache_hit(cache_hit_collector.output)
        if cache_hit:
            metrics["Cache Hit"] = cache_hit

    # Extract topology and workload for golden fact path
    scenario_topology = scenario.get('topology', 'standalone')
    scenario_workload = scenario.get('workload', 'mixed')
    date_mmddyy = datetime.now().strftime("%m%d%y")
    golden_fact_path = f"golden-facts/{scenario_topology.capitalize()}x{scenario_workload.upper()}-{date_mmddyy}.md"

    # Get dataset and benchmark tool info
    dataset_info = get_dataset_info(scenario)
    benchmark_tool = get_benchmark_tool(scenario)
    transaction_type = get_transaction_type(pgbench_flags)
    protocol = get_protocol(pgbench_flags)

    # Target host IP
    target_ip = variables.get('host', '10.0.1.10')

    # =======================================================================
    # 1. Header
    # =======================================================================
    lines = [
        f"# Benchmark Report: {scenario['name']}",
        "",
        f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Scenario ID:** {scenario_id}",
        f"**Topology:** {scenario_topology}",
        f"**Workload:** {scenario_workload}",
        "",
        f"> **Golden Fact Path:** `{golden_fact_path}`",
        "",
        "---",
        "",
    ]

    # =======================================================================
    # 2. Benchmark Environment
    # =======================================================================
    lines.extend([
        "## Benchmark Environment",
        "",
        "### Runner (Benchmark Driver)",
        "| Property | Value |",
        "|----------|-------|",
        "| Role | proxy / benchmark driver |",
        f"| Instance | {runner_hw['instance_type']} |",
        f"| vCPU | {runner_hw['vcpu']} |",
        f"| RAM | {runner_hw['ram_gb']} GB |",
        f"| Private IP | {runner_hw['private_ip']} |",
        "",
        "### Target (Database Server)",
        "| Property | Value |",
        "|----------|-------|",
        f"| Role | {scenario_topology} |",
        f"| Instance | {target_hw['instance_type']} |",
        f"| vCPU | {target_hw['vcpu']} |",
        f"| RAM | {target_hw['ram_gb']} GB |",
        f"| Private IP | {target_ip} |",
        f"| Storage | {target_hw['storage']} |",
        f"| PostgreSQL | {target_hw['pg_version']} |",
        "",
        "---",
        "",
    ])

    # =======================================================================
    # 3. Scenario Context
    # =======================================================================
    lines.extend([
        "## Scenario Context",
        "",
        "### Scenario Definition",
        "| Property | Value |",
        "|----------|-------|",
        f"| ID | {scenario_id} |",
        f"| Name | {scenario['id']} |",
        f"| Description | {desc} |",
        f"| Benchmark Tool | {benchmark_tool} |",
        f"| Dataset | {dataset_info['dataset']} |",
        f"| Scale Factor | {dataset_info['scale_factor']} ({dataset_info['estimated_size']}) |",
        "",
        "### Workload Parameters",
        "| Parameter | Value |",
        "|-----------|-------|",
        f"| Duration | {duration}s |",
        f"| Clients | {clients} |",
        f"| Threads | {threads} |",
        f"| Protocol | {protocol} |",
        f"| Transaction Type | {transaction_type} |",
        "",
        "### Primary Command",
        "```bash",
        primary_cmd_str,
        "```",
        "",
    ])

    # Command flags breakdown for pgbench
    if pgbench_flags:
        lines.extend([
            "### Command Flags Breakdown",
            "| Flag | Value | Meaning |",
            "|------|-------|---------|",
        ])
        flag_meanings = {
            '-c': 'Number of concurrent clients',
            '-j': 'Number of worker threads',
            '-T': 'Duration in seconds',
            '-P': 'Progress report interval (seconds)',
            '-M': 'Query protocol (simple/extended/prepared)',
            '-S': 'SELECT-only mode',
            '-C': 'Establish new connection per transaction',
            '--no-vacuum': 'Skip vacuum before test',
        }
        for flag, value in pgbench_flags.items():
            meaning = flag_meanings.get(flag, '')
            lines.append(f"| {flag} | {value} | {meaning} |")
        lines.append("")

    lines.extend([
        "---",
        "",
    ])

    # =======================================================================
    # 4. Summary
    # =======================================================================
    lines.extend([
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|------:|",
    ])

    # Add parsed metrics (highlighted)
    for key, value in metrics.items():
        lines.append(f"| **{key}** | **{value}** |")

    # Add TPS/vCPU if TPS available
    if "TPS" in metrics:
        try:
            tps_val = float(metrics["TPS"].replace(",", ""))
            tps_per_vcpu = int(tps_val / target_hw['vcpu'])
            lines.append(f"| **TPS/vCPU** | **{tps_per_vcpu:,}** |")
        except:
            pass

    lines.extend([
        f"| Duration | {duration}s |",
        "",
        "---",
        "",
    ])

    # Collect actual config from DB host and render verification matrix
    # Always query DB directly (10.0.1.10:5432) even when benchmark runs via PgCat
    print("  Collecting actual config from DB host for verification...")
    db_host = variables.get('db_host', '10.0.1.10')
    actual_config = collect_actual_config(db_host, pg_host='10.0.1.10', pg_port='5432')
    config_verification = render_config_verification(configs, actual_config)
    lines.append(config_verification)

    lines.extend([
        "---",
        "",
        "## System Configuration",
        "",
        "```",
        system_info,
        "```",
        "",
        "---",
        "",
    ])
    
    # Primary driver output
    if primary:
        lines.extend([
            f"## 📈 Benchmark Output ({primary.name})",
            "",
            "**Command:**",
            "```bash",
            primary.cmd_str,
            "```",
            "",
            "**Output:**",
            "```",
            primary.output[:15000] if len(primary.output) > 15000 else primary.output,
            "```",
            "",
            "---",
            "",
        ])
    
    # Diagnostics section (collectors)
    lines.append("## 📉 Diagnostics")
    lines.append("")
    
    for name in ['iostat', 'mpstat']:
        if name in collectors:
            result = collectors[name]
            lines.extend([
                f"### {name}",
                "",
                "```",
                result.output[:20000] if len(result.output) > 20000 else result.output,
                "```",
                "",
            ])
    
    # Any other collectors (Postgres stats, etc)
    # Group by prefix for better structure
    prefixes = ['begin:', 'end:', '']
    for prefix in prefixes:
        for name, result in sorted(collectors.items()):
            if name in ['iostat', 'mpstat']: continue
            if prefix and not name.startswith(prefix): continue
            if not prefix and (name.startswith('begin:') or name.startswith('end:')): continue
            
            display_name = name.removeprefix(prefix)
            section_title = f"{prefix}{display_name}"
            
            lines.extend([
                f"### {section_title}",
                "",
                "```",
                result.output[:10000] if len(result.output) > 10000 else result.output,
                "```",
                "",
            ])
    
    lines.append("---")
    lines.append("")

    # Add Golden Fact Template section
    result_filename = f"{scenario['id']}-{timestamp}.md"
    golden_fact_template = render_golden_fact_template(
        scenario_topology=scenario_topology,
        scenario_workload=scenario_workload,
        timestamp=timestamp,
        result_filename=result_filename,
    )
    lines.append(golden_fact_template)
    lines.append("")

    report = "\n".join(lines)

    # Flat results directory: results/{scenario_id}-{timestamp}.md
    RESULTS_BASE.mkdir(parents=True, exist_ok=True)
    report_path = RESULTS_BASE / result_filename
    report_path.write_text(report)

    return report_path



def print_summary(results: List[CommandResult]):
    """Print quick summary from primary result"""
    print("\n--- Summary ---")
    
    for result in results:
        if result.is_primary:
            if "fio" in result.name.lower():
                for line in result.output.split("\n"):
                    if "IOPS=" in line or "bw=" in line.lower():
                        print(f"  {line.strip()}")


# =============================================================================
# CLI
# =============================================================================

def show_help():
    """Show all available scenarios"""
    data = load_scenarios()
    scenarios = data.get("scenarios", {})
    topology = detect_topology()
    hw = get_hardware_context()
    
    print(f"""
================================================================================
BENCHMARK RUNNER
================================================================================

Topology: {topology}
Hardware: {hw['vcpu']} vCPU, {hw['ram_gb']} GB RAM

Usage: sudo python3 bench.py <scenario_id>

================================================================================
FIO DISK BENCHMARKS (1-10)
================================================================================
""")
    
    for sid in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]:
        if sid in scenarios:
            s = scenarios[sid]
            target = s.get("target_disk", "data").upper()
            print(f"  [{sid:>2}] {s['name']:<20} [{target:<4}] {s['desc']}")
    
    print("""
================================================================================
EXAMPLES
================================================================================

  sudo python3 bench.py 1       # Run scenario 1
  sudo python3 bench.py 1-10    # Run all FIO scenarios
  sudo python3 bench.py --list  # Show this help

================================================================================
""")


def parse_scenario_range(arg: str) -> List[str]:
    """Parse scenario argument like '1', '1-10', '1,3,5'"""
    if "-" in arg and "," not in arg:
        start, end = arg.split("-")
        return [str(i) for i in range(int(start), int(end) + 1)]
    elif "," in arg:
        return [s.strip() for s in arg.split(",")]
    else:
        return [arg]


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h", "help", "--list", "-l"]:
        show_help()
        sys.exit(0)
    
    if os.geteuid() != 0:
        print("Error: Must run as root (sudo)")
        sys.exit(1)
    
    # Simple argument parsing
    scenario_arg = sys.argv[1]
    variables_override = {}
    
    if "--host" in sys.argv:
        host_idx = sys.argv.index("--host")
        if len(sys.argv) > host_idx + 1:
            variables_override["host"] = sys.argv[host_idx + 1]

    if "--port" in sys.argv:
        port_idx = sys.argv.index("--port")
        if len(sys.argv) > port_idx + 1:
            variables_override["port"] = sys.argv[port_idx + 1]

    if "--db-host" in sys.argv:
        db_host_idx = sys.argv.index("--db-host")
        if len(sys.argv) > db_host_idx + 1:
            variables_override["db_host"] = sys.argv[db_host_idx + 1]

    # Detect topology
    topology = detect_topology()
    
    # Parse scenarios
    scenario_ids = parse_scenario_range(scenario_arg)
    
    print(f"\n=== Benchmark Runner ===")
    print(f"Topology: {topology}")
    print(f"Scenarios: {', '.join(scenario_ids)}")
    if "host" in variables_override:
        port = variables_override.get('port', '5432')
        print(f"Target: {variables_override['host']}:{port}")
    
    # Run each scenario
    for sid in scenario_ids:
        run_scenario(sid, topology, variables_override)
    
    print(f"\n=== All benchmarks complete ===")
    print(f"Results in: {RESULTS_BASE}")


if __name__ == "__main__":
    main()
