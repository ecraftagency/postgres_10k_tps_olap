#!/usr/bin/env python3
"""
PostgreSQL Benchmark Tool

Usage:
    sudo python3 bench.py <scenario_id>
    sudo python3 bench.py 11        # Run TPC-B benchmark
    sudo python3 bench.py --help    # Show all scenarios

All configuration is in scenarios.json
"""
import json
import os
import re
import shlex
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass
from typing import Dict, List, Optional

SCRIPT_DIR = Path(__file__).parent.resolve()
SCENARIOS_FILE = SCRIPT_DIR / "scenarios.json"
HARDWARE_ENV = SCRIPT_DIR / "hardware.env"
RESULTS_DIR = SCRIPT_DIR / "results"


def get_hardware_context() -> Dict:
    """
    Get hardware context for benchmark parameters.

    Priority (high to low):
    1. hardware.env (explicit override)
    2. Auto-detect from system

    Returns dict with: vcpu, threads, clients, scale
    """
    # Auto-detect defaults
    vcpu = os.cpu_count() or 2
    ram_gb = 16  # Conservative default

    # Try to get RAM from system
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    ram_kb = int(line.split()[1])
                    ram_gb = ram_kb // (1024 * 1024)
                    break
    except Exception:
        pass

    # Override from hardware.env if exists
    if HARDWARE_ENV.exists():
        try:
            with open(HARDWARE_ENV) as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" in line:
                        key, value = line.split("=", 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        if key == "VCPU":
                            vcpu = int(value)
                        elif key == "RAM_GB":
                            ram_gb = int(value)
        except Exception:
            pass

    # Calculate derived values
    # threads = vCPU (match CPU cores)
    # clients = vCPU * 12 (reasonable concurrency)
    # scale = 1250 (fixed, ~12GB dataset fits in shared_buffers)
    return {
        "vcpu": vcpu,
        "ram_gb": ram_gb,
        "threads": vcpu,
        "clients": vcpu * 12,
        "scale": 1250,
    }


@dataclass
class CommandResult:
    name: str
    cmd_str: str
    output: str
    success: bool
    is_primary: bool = False


def load_scenarios() -> Dict:
    """Load scenarios from JSON"""
    with open(SCENARIOS_FILE) as f:
        return json.load(f)


def show_help():
    """Show all available scenarios"""
    data = load_scenarios()
    scenarios = data.get("scenarios", {})

    print("""
================================================================================
POSTGRESQL BENCHMARK TOOL
================================================================================

Usage: sudo python3 bench.py <scenario_id>

================================================================================
FIO DISK BENCHMARKS (1-10)
================================================================================
""")

    # FIO scenarios
    for sid in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]:
        if sid in scenarios:
            s = scenarios[sid]
            target = s.get("target_disk", "data").upper()
            print(f"  [{sid:>2}] {s['name']:<20} [{target:<4}] {s['desc']}")

    print("""
================================================================================
POSTGRESQL BENCHMARKS (11-14) - pgbench
================================================================================
""")

    # pgbench scenarios
    for sid in ["11", "12", "13", "14"]:
        if sid in scenarios:
            s = scenarios[sid]
            print(f"  [{sid}] {s['name']:<20} {s['desc']}")

    print("""
================================================================================
SYSBENCH OLTP (15-18)
================================================================================
""")

    # sysbench scenarios
    for sid in ["15", "16", "17", "18"]:
        if sid in scenarios:
            s = scenarios[sid]
            print(f"  [{sid}] {s['name']:<20} {s['desc']}")

    print("""
================================================================================
EXAMPLES
================================================================================

  sudo python3 bench.py 1     # FIO: WAL commit latency
  sudo python3 bench.py 11    # pgbench: TPC-B write intensive
  sudo python3 bench.py 15    # sysbench: OLTP read-only

================================================================================
""")


def collect_system_info() -> str:
    """Collect hardware and system configuration"""
    def run_cmd(cmd: str) -> str:
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            return result.stdout.strip()
        except Exception:
            return ""

    sections = [
        "=== INSTANCE ===",
        run_cmd("uname -a"),
        run_cmd("lscpu | grep -E '^CPU\\(s\\)|^Model name|^Architecture'"),
        run_cmd("free -h"),
        "",
        "=== OS TUNING ===",
        run_cmd("sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio 2>/dev/null"),
        run_cmd("cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null"),
        "",
        "=== HUGEPAGES ===",
        run_cmd("grep -E 'HugePages|Hugepagesize' /proc/meminfo"),
        "",
        "=== DISK - RAID ===",
        run_cmd("cat /proc/mdstat"),
        "",
        "=== DISK - MOUNT ===",
        run_cmd("mount | grep -E '/data|/wal'"),
        run_cmd("df -h /data /wal 2>/dev/null"),
        "",
        "=== POSTGRESQL ===",
        run_cmd("sudo -u postgres psql -t -c \"SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers','work_mem','effective_cache_size','max_connections','wal_buffers','max_wal_size','huge_pages')\" 2>/dev/null"),
    ]
    return "\n".join(sections)


def substitute_vars(text: str, variables: Dict) -> str:
    """Substitute {var} placeholders in text"""
    result = str(text)
    for key, value in variables.items():
        result = result.replace(f"{{{key}}}", str(value))
    return result


def run_benchmark(scenario_id: str) -> Path:
    """Run a benchmark scenario"""
    data = load_scenarios()
    scenarios = data.get("scenarios", {})
    disks = data.get("disks", {})
    json_defaults = data.get("defaults", {})

    if scenario_id not in scenarios:
        print(f"Error: Scenario {scenario_id} not found")
        print("Run 'python3 bench.py --help' to see available scenarios")
        sys.exit(1)

    scenario = scenarios[scenario_id]
    disk = disks.get(scenario.get("target_disk", "data"), {})

    # Get hardware context (auto-detect + hardware.env)
    hw = get_hardware_context()

    # Build variables with priority: scenario > json_defaults > hardware
    variables = {
        "duration": json_defaults.get("duration", 60),
        "clients": hw["clients"],      # From hardware context
        "threads": hw["threads"],      # From hardware context
        "scale": hw["scale"],          # From hardware context
        "vcpu": hw["vcpu"],
        "ram_gb": hw["ram_gb"],
    }
    # Override with json defaults if explicitly set
    for key in ["clients", "threads", "scale"]:
        if key in json_defaults:
            variables[key] = json_defaults[key]
    # Override with scenario-specific values (highest priority)
    for key in ["duration", "clients", "threads", "scale"]:
        if key in scenario:
            variables[key] = scenario[key]

    duration = variables["duration"]

    print(f"\n{'='*70}")
    print(f"SCENARIO {scenario_id}: {scenario['name']}")
    print(f"{'='*70}")
    print(f"Hardware: {hw['vcpu']} vCPU, {hw['ram_gb']} GB RAM")
    print(f"Description: {substitute_vars(scenario['desc'], variables)}")
    print(f"Target: {disk.get('name', 'N/A')}")
    print(f"Duration: {duration}s | Clients: {variables['clients']} | Threads: {variables['threads']}")

    # Setup
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = RESULTS_DIR / scenario.get("id", f"scenario_{scenario_id}")
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

    # Start background collectors
    bg_variables = {**variables, "duration": duration + 10}  # Extra buffer for collectors
    for cmd_def in parallel_cmds:
        if cmd_def.get("primary", False):
            primary_cmd = cmd_def
            continue

        cmd = [substitute_vars(str(c), bg_variables) for c in cmd_def.get("cmd", [])]
        cmd_str = " ".join(shlex.quote(c) for c in cmd)

        output_file = output_dir / f"{cmd_def.get('name', 'bg')}_{timestamp}.txt"

        if cmd_def.get("filter_volumes", False):
            # Use stdbuf to disable pipe buffering so output is written immediately
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

    # Run primary command
    if primary_cmd:
        cmd = [substitute_vars(str(c), variables) for c in primary_cmd.get("cmd", [])]
        cmd_str = " ".join(shlex.quote(c) for c in cmd)
        output_file = output_dir / f"{primary_cmd.get('name', 'primary')}_{timestamp}.txt"

        print(f"  Running: {primary_cmd.get('name', 'primary')} ({duration}s)...")

        is_fio = "fio" in cmd

        try:
            if is_fio:
                cmd_with_output = cmd + [f"--output={output_file}"]
                subprocess.run(cmd_with_output, check=True, timeout=duration + 120)
                output = output_file.read_text() if output_file.exists() else "No output"
            else:
                result = subprocess.run(
                    cmd_str,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=duration + 120,
                )
                output = result.stdout + result.stderr
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

        # Cleanup
        cleanup_path = primary_cmd.get("cleanup")
        if cleanup_path:
            os.system(f"rm -f {cleanup_path} 2>/dev/null")

    # Stop background processes
    if background_procs:
        print("  Stopping collectors...")
        time.sleep(2)

        for bg in background_procs:
            try:
                os.killpg(os.getpgid(bg["proc"].pid), signal.SIGTERM)
            except Exception:
                pass

            output = bg["output_file"].read_text() if bg["output_file"].exists() else "No output"
            command_results.append(CommandResult(
                name=bg["name"],
                cmd_str=bg["cmd_str"],
                output=output,
                success=True,
            ))

    # === END PHASE ===
    end_cmds = scenario.get("end", [])
    if end_cmds:
        print("\n--- End Phase ---")
        for cmd_def in end_cmds:
            cmd = [substitute_vars(str(c), variables) for c in cmd_def.get("cmd", [])]
            cmd_str = " ".join(shlex.quote(c) for c in cmd)
            print(f"  Running: {cmd_def.get('name', 'cmd')}...")
            subprocess.run(cmd_str, shell=True, capture_output=True, timeout=60)

    # === GENERATE REPORT ===
    report_path = generate_report(
        scenario=scenario,
        disk=disk,
        system_info=system_info,
        command_results=command_results,
        output_dir=output_dir,
        timestamp=timestamp,
        variables=variables,
    )

    # Print summary
    print_summary(command_results)

    print(f"\nReport: {report_path}")
    return report_path


def generate_report(
    scenario: Dict,
    disk: Dict,
    system_info: str,
    command_results: List[CommandResult],
    output_dir: Path,
    timestamp: str,
    variables: Optional[Dict] = None,
) -> Path:
    """Generate markdown report"""
    variables = variables or {}

    # Find primary result
    primary = next((r for r in command_results if r.is_primary), None)
    metrics = {}

    if primary:
        if "fio" in primary.name.lower():
            metrics = parse_fio(primary.output)
        elif "pgbench" in primary.name.lower():
            metrics = parse_pgbench(primary.output)
        elif "sysbench" in primary.name.lower():
            metrics = parse_sysbench(primary.output)

    desc = substitute_vars(scenario['desc'], variables)
    lines = [
        f"# Benchmark: {scenario['name']}",
        "",
        f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Scenario:** {scenario['id']}",
        f"**Description:** {desc}",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
    ]

    for key, value in metrics.items():
        lines.append(f"| **{key}** | {value} |")

    lines.extend([
        "",
        "---",
        "",
        "## Target",
        "",
        f"- **Disk:** {disk.get('name', 'N/A')}",
        f"- **Device:** {disk.get('device', 'N/A')}",
        f"- **Mount:** {disk.get('mount_point', 'N/A')}",
        "",
        "---",
        "",
        "## System",
        "",
        "```",
        system_info,
        "```",
        "",
        "---",
        "",
    ])

    # Command outputs
    for i, result in enumerate(command_results, 1):
        lines.extend([
            f"## {i}. {result.name}",
            "",
            "```bash",
            result.cmd_str,
            "```",
            "",
            "```",
            result.output[:8000] if len(result.output) > 8000 else result.output,
            "```",
            "",
        ])

    report = "\n".join(lines)
    report_path = output_dir / f"report_{timestamp}.md"
    report_path.write_text(report)

    return report_path


def parse_fio(output: str) -> Dict[str, str]:
    """Parse FIO output"""
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


def parse_pgbench(output: str) -> Dict[str, str]:
    """Parse pgbench output"""
    metrics = {}

    tps = re.search(r'tps = ([\d.]+)', output)
    if tps:
        metrics["TPS"] = f"{float(tps.group(1)):,.0f}"

    lat = re.search(r'latency average = ([\d.]+) ms', output)
    if lat:
        metrics["Avg Latency"] = f"{lat.group(1)}ms"

    stddev = re.search(r'latency stddev = ([\d.]+) ms', output)
    if stddev:
        metrics["Stddev"] = f"{stddev.group(1)}ms"

    txn = re.search(r'number of transactions actually processed: (\d+)', output)
    if txn:
        metrics["Transactions"] = f"{int(txn.group(1)):,}"

    return metrics


def parse_sysbench(output: str) -> Dict[str, str]:
    """Parse sysbench output"""
    metrics = {}

    tps = re.search(r'transactions:\s+\d+\s+\(([\d.]+)\s+per sec', output)
    if tps:
        metrics["TPS"] = f"{float(tps.group(1)):,.0f}"

    qps = re.search(r'queries:\s+\d+\s+\(([\d.]+)\s+per sec', output)
    if qps:
        metrics["QPS"] = f"{float(qps.group(1)):,.0f}"

    lat = re.search(r'avg:\s+([\d.]+)', output)
    if lat:
        metrics["Avg Latency"] = f"{lat.group(1)}ms"

    p95 = re.search(r'95th percentile:\s+([\d.]+)', output)
    if p95:
        metrics["P95 Latency"] = f"{p95.group(1)}ms"

    return metrics


def print_summary(results: List[CommandResult]):
    """Print quick summary"""
    print("\n--- Summary ---")

    for result in results:
        if result.is_primary:
            if "fio" in result.name.lower():
                for line in result.output.split("\n"):
                    if "IOPS=" in line or "bw=" in line.lower():
                        print(f"  {line.strip()}")
            elif "pgbench" in result.name.lower():
                for line in result.output.split("\n"):
                    if "tps =" in line:
                        print(f"  {line.strip()}")
            elif "sysbench" in result.name.lower():
                for line in result.output.split("\n"):
                    if "transactions:" in line or "queries:" in line:
                        print(f"  {line.strip()}")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h", "help"]:
        show_help()
        sys.exit(0)

    scenario_id = sys.argv[1]

    if os.geteuid() != 0:
        print("Error: Must run as root (sudo)")
        sys.exit(1)

    run_benchmark(scenario_id)


if __name__ == "__main__":
    main()
