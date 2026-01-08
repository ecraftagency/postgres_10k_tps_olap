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


# Config category mapping for RESULT-STRUCTURE.md format
CONFIG_CATEGORIES = {
    "OS - Memory": [
        ("vm.swappiness", "VM_SWAPPINESS", "os.env"),
        ("vm.dirty_background_ratio", "VM_DIRTY_BACKGROUND_RATIO", "os.env"),
        ("vm.dirty_ratio", "VM_DIRTY_RATIO", "os.env"),
        ("vm.dirty_expire_centisecs", "VM_DIRTY_EXPIRE_CENTISECS", "os.env"),
        ("vm.dirty_writeback_centisecs", "VM_DIRTY_WRITEBACK_CENTISECS", "os.env"),
        ("vm.overcommit_memory", "VM_OVERCOMMIT_MEMORY", "os.env"),
        ("vm.overcommit_ratio", "VM_OVERCOMMIT_RATIO", "os.env"),
        ("vm.min_free_kbytes", "VM_MIN_FREE_KBYTES", "os.env"),
        ("vm.zone_reclaim_mode", "VM_ZONE_RECLAIM_MODE", "os.env"),
        ("vm.nr_hugepages", "VM_NR_HUGEPAGES", "os.env"),
    ],
    "OS - File Descriptors": [
        ("fs.file-max", "FS_FILE_MAX", "os.env"),
        ("fs.aio-max-nr", "FS_AIO_MAX_NR", "os.env"),
    ],
    "OS - Kernel": [
        ("kernel.sched_autogroup_enabled", "KERNEL_SCHED_AUTOGROUP_ENABLED", "os.env"),
        ("kernel.numa_balancing", "KERNEL_NUMA_BALANCING", "os.env"),
    ],
    "OS - TCP": [
        ("net.core.somaxconn", "NET_CORE_SOMAXCONN", "os.env"),
        ("net.core.netdev_max_backlog", "NET_CORE_NETDEV_MAX_BACKLOG", "os.env"),
        ("net.core.rmem_default", "NET_CORE_RMEM_DEFAULT", "os.env"),
        ("net.core.rmem_max", "NET_CORE_RMEM_MAX", "os.env"),
        ("net.core.wmem_default", "NET_CORE_WMEM_DEFAULT", "os.env"),
        ("net.core.wmem_max", "NET_CORE_WMEM_MAX", "os.env"),
        ("net.ipv4.tcp_max_syn_backlog", "NET_IPV4_TCP_MAX_SYN_BACKLOG", "os.env"),
        ("net.ipv4.tcp_tw_reuse", "NET_IPV4_TCP_TW_REUSE", "os.env"),
        ("net.ipv4.tcp_fin_timeout", "NET_IPV4_TCP_FIN_TIMEOUT", "os.env"),
    ],
    "Disk": [
        ("DATA read_ahead_kb", "DATA_READ_AHEAD_KB", "base.env"),
        ("WAL read_ahead_kb", "WAL_READ_AHEAD_KB", "base.env"),
        ("DATA filesystem", "FS_TYPE", "base.env"),
        ("WAL filesystem", "FS_TYPE", "base.env"),
        ("DATA mount", "DATA_MOUNT", "base.env"),
        ("WAL mount", "WAL_MOUNT", "base.env"),
        ("transparent_hugepage", "THP_ENABLED", "os.env"),
    ],
    "PostgreSQL - Memory": [
        ("shared_buffers", "PG_SHARED_BUFFERS", "primary.env"),
        ("effective_cache_size", "PG_EFFECTIVE_CACHE_SIZE", "primary.env"),
        ("work_mem", "PG_WORK_MEM", "primary.env"),
        ("maintenance_work_mem", "PG_MAINTENANCE_WORK_MEM", "primary.env"),
        ("huge_pages", "PG_HUGE_PAGES", "primary.env"),
        ("max_connections", "PG_MAX_CONNECTIONS", "primary.env"),
    ],
    "PostgreSQL - WAL": [
        ("wal_level", "PG_WAL_LEVEL", "primary.env"),
        ("wal_compression", "PG_WAL_COMPRESSION", "primary.env"),
        ("wal_sync_method", "PG_WAL_SYNC_METHOD", "primary.env"),
        ("wal_buffers", "PG_WAL_BUFFERS", "primary.env"),
        ("wal_writer_delay", "PG_WAL_WRITER_DELAY", "primary.env"),
        ("synchronous_commit", "PG_SYNCHRONOUS_COMMIT", "primary.env"),
        ("max_wal_size", "PG_MAX_WAL_SIZE", "primary.env"),
        ("min_wal_size", "PG_MIN_WAL_SIZE", "primary.env"),
    ],
    "PostgreSQL - Checkpoint": [
        ("checkpoint_timeout", "PG_CHECKPOINT_TIMEOUT", "primary.env"),
        ("checkpoint_completion_target", "PG_CHECKPOINT_COMPLETION_TARGET", "primary.env"),
    ],
    "PostgreSQL - Background Writer": [
        ("bgwriter_delay", "PG_BGWRITER_DELAY", "primary.env"),
        ("bgwriter_lru_maxpages", "PG_BGWRITER_LRU_MAXPAGES", "primary.env"),
        ("bgwriter_lru_multiplier", "PG_BGWRITER_LRU_MULTIPLIER", "primary.env"),
    ],
    "PostgreSQL - I/O": [
        ("effective_io_concurrency", "PG_EFFECTIVE_IO_CONCURRENCY", "primary.env"),
        ("random_page_cost", "PG_RANDOM_PAGE_COST", "primary.env"),
        ("seq_page_cost", "PG_SEQ_PAGE_COST", "primary.env"),
    ],
}


def render_config_matrix(configs: Dict[str, Dict[str, str]]) -> str:
    """Render full configuration matrix grouped by category"""
    lines = ["## Configuration Matrix", ""]

    for category, params in CONFIG_CATEGORIES.items():
        lines.append(f"### {category} ({len(params)} params)")
        lines.append("| Parameter | Value | Source |")
        lines.append("|-----------|-------|--------|")

        for display_name, env_key, source_file in params:
            value = configs.get(source_file, {}).get(env_key, "N/A")
            lines.append(f"| {display_name} | {value} | {source_file} |")

        lines.append("")

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
    variables = {
        "duration": scenario.get("duration", defaults.get("duration", 60)),
        "clients": scenario.get("clients", hw["clients"]),
        "threads": scenario.get("threads", hw["threads"]),
        "scale": scenario.get("scale", hw["scale"]),
        "vcpu": hw["vcpu"],
        "ram_gb": hw["ram_gb"],
        "host": host,
        "port": variables_override.get("port", "5432"),
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

    # Render full configuration matrix (configs already loaded above)
    config_matrix = render_config_matrix(configs)
    lines.append(config_matrix)

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
