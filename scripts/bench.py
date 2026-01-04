#!/usr/bin/env python3
"""
Disk Benchmark Tool for PostgreSQL OLTP on RAID10 EBS gp3

Configuration is loaded from scenarios.json
Each scenario runs N commands in parallel and collects all outputs
"""
import os
import subprocess
import sys
import json
import shlex
import urllib.request
import urllib.error
import signal
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR = Path(__file__).parent.resolve()
OUTPUT_DIR = SCRIPT_DIR / "results"
SCENARIOS_FILE = SCRIPT_DIR / "scenarios.json"

# PgCat connection pooler config (for --via-pgcat mode)
# Run benchmark from proxy server, so host = localhost
PGCAT_CONFIG = {
    "host": os.environ.get("PGCAT_HOST", "localhost"),
    "port": os.environ.get("PGCAT_PORT", "5432"),
    "user": os.environ.get("PGCAT_USER", "postgres"),
    "password": os.environ.get("PGCAT_PASSWORD", ""),
    "database": os.environ.get("PGCAT_DATABASE", "pgbench"),
}

# Gemini API for AI analysis
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


def load_scenarios() -> tuple:
    """Load DISKS and SCENARIOS from scenarios.json"""
    if not SCENARIOS_FILE.exists():
        print(f"Error: {SCENARIOS_FILE} not found")
        sys.exit(1)

    with open(SCENARIOS_FILE, "r") as f:
        data = json.load(f)

    return data["disks"], data["scenarios"]


# Load configuration
DISKS, SCENARIOS = load_scenarios()

# =============================================================================
# AI PROMPT
# =============================================================================

AI_PROMPT = """You are an expert database infrastructure engineer. Analyze this disk benchmark report and provide:

1. **Executive Summary** - 2-3 sentences about overall system readiness for PostgreSQL OLTP

2. **Score Card** (MUST include this section with exact format):

| Aspect | Score | Assessment |
|--------|-------|------------|
| **Speed** | X/10 | (Compare actual IOPS/latency vs theoretical limits) |
| **Stability** | X/10 | (How close is P99 to P50? Jitter analysis) |
| **Config Alignment** | X/10 | (RAID chunk, XFS sunit/swidth, mount options) |

3. **Detailed Analysis** - Key observations from each command output

4. **Recommendations** - Prioritized list of improvements (if any)

IMPORTANT:
- EBS gp3 single-operation latency is ~1.5-2.5ms (network storage)
- Max IOPS @ QD1+fsync = 1000ms / latency_ms ≈ 400-600 IOPS
- High latency at high iodepth is NORMAL (queueing effect)

Format your response as clean, well-structured Markdown.

---

BENCHMARK REPORT TO ANALYZE:

"""


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def run_cmd(cmd: str, capture: bool = True, timeout: int = 10) -> str:
    """Run shell command and return output"""
    try:
        if capture:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
            return result.stdout.strip()
        else:
            subprocess.run(cmd, shell=True, check=True)
            return ""
    except Exception:
        return ""


def collect_system_info() -> str:
    """Collect hardware context and system configuration"""
    sections = []

    # Instance
    sections.append("=== INSTANCE ===")
    sections.append(run_cmd("curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'unknown'"))
    sections.append(run_cmd("uname -a"))
    sections.append(run_cmd("lscpu | grep -E '^CPU\\(s\\)|^Model name|^Architecture'"))
    sections.append(run_cmd("free -h"))

    # OS Tuning
    sections.append("\n=== OS TUNING ===")
    sections.append(run_cmd("sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio vm.dirty_expire_centisecs vm.dirty_writeback_centisecs 2>/dev/null"))
    sections.append(run_cmd("cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null"))

    # Network
    sections.append("\n=== NETWORK ===")
    sections.append(run_cmd("sysctl net.core.somaxconn net.core.rmem_max net.core.wmem_max net.ipv4.tcp_tw_reuse net.ipv4.tcp_fin_timeout 2>/dev/null"))

    # Disk - RAID
    sections.append("\n=== DISK - RAID ===")
    sections.append(run_cmd("cat /proc/mdstat"))
    sections.append(run_cmd("mdadm --detail /dev/md0 2>/dev/null"))
    sections.append(run_cmd("mdadm --detail /dev/md1 2>/dev/null"))

    # Disk - Block Tuning
    sections.append("\n=== DISK - BLOCK TUNING ===")
    for dev in ["md0", "md1"]:
        sections.append(f"--- {dev} ---")
        sections.append(f"scheduler: {run_cmd(f'cat /sys/block/{dev}/queue/scheduler 2>/dev/null')}")
        sections.append(f"read_ahead_kb: {run_cmd(f'cat /sys/block/{dev}/queue/read_ahead_kb 2>/dev/null')}")
        sections.append(f"nr_requests: {run_cmd(f'cat /sys/block/{dev}/queue/nr_requests 2>/dev/null')}")

    # Disk - Mount
    sections.append("\n=== DISK - MOUNT ===")
    sections.append(run_cmd("mount | grep -E '/data|/wal'"))
    sections.append(run_cmd("df -h /data /wal 2>/dev/null"))

    # Disk - XFS
    sections.append("\n=== DISK - XFS ===")
    sections.append(run_cmd("xfs_info /data 2>/dev/null"))
    sections.append(run_cmd("xfs_info /wal 2>/dev/null"))

    return "\n".join(sections)


def get_display_name(scenario: dict, disk: dict) -> str:
    """Generate display name for scenario"""
    return f"[{disk['name']} DISK] {scenario['name']} - {scenario['desc'].split(' - ')[0]}"


def get_export_prefix(scenario: dict, disk: dict) -> str:
    """Generate export filename prefix - uses scenario id which already has disk prefix"""
    return scenario['id']


def build_iostat_filter(disk: dict) -> str:
    """Build iostat grep filter for target volumes"""
    device_name = disk["device"].split("/")[-1]  # md0 or md1
    volumes = "|".join(disk["volumes"])
    return f"{device_name}|{volumes}"


def call_gemini(prompt: str, api_key: str) -> str:
    """Call Gemini API and return response text"""
    request_body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 8192,
        }
    }

    url = f"{GEMINI_API_URL}?key={api_key}"
    req = urllib.request.Request(
        url,
        data=json.dumps(request_body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            data = json.loads(response.read().decode("utf-8"))
            candidates = data.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                if parts:
                    return parts[0].get("text", "")
            return "No response from AI"
    except urllib.error.HTTPError as e:
        return f"API Error {e.code}: {e.read().decode('utf-8')}"
    except Exception as e:
        return f"Error: {str(e)}"


# =============================================================================
# BENCHMARK RUNNER
# =============================================================================

@dataclass
class CommandResult:
    """Result of a single command execution"""
    name: str
    cmd_str: str
    output: str
    success: bool


def modify_cmd_for_pgcat(cmd: List[str], via_pgcat: bool) -> List[str]:
    """Modify pgbench/psql commands to connect via PgCat instead of local socket"""
    if not via_pgcat:
        return cmd

    # Find pgbench or psql in the command (may be after sudo -u postgres)
    pg_cmd_idx = -1
    for i, arg in enumerate(cmd):
        if arg in ("pgbench", "psql"):
            pg_cmd_idx = i
            break

    if pg_cmd_idx == -1:
        return cmd  # Not a postgres command

    # Start fresh - skip "sudo -u postgres" prefix if present
    # When using PgCat, we connect over network, no need for sudo
    start_idx = 0
    if len(cmd) >= 3 and cmd[0] == "sudo" and cmd[1] == "-u" and cmd[2] == "postgres":
        start_idx = 3  # Skip sudo -u postgres

    # Build new command starting with pgbench/psql
    new_cmd = [cmd[pg_cmd_idx]]

    # Add connection params right after pgbench/psql
    new_cmd.extend([
        "-h", PGCAT_CONFIG["host"],
        "-p", PGCAT_CONFIG["port"],
        "-U", PGCAT_CONFIG["user"],
    ])

    # Process remaining args - skip existing connection flags and final db name
    remaining = cmd[pg_cmd_idx + 1:]
    skip_next = False

    for i, arg in enumerate(remaining):
        if skip_next:
            skip_next = False
            continue

        # Skip existing connection flags
        if arg in ("-h", "-p", "-U", "-d", "--host", "--port", "--username", "--dbname"):
            skip_next = True
            continue

        # Skip last positional arg if it looks like a database name (no dash prefix)
        if i == len(remaining) - 1 and not arg.startswith("-") and arg not in ("tpcb-like",):
            continue

        new_cmd.append(arg)

    # Add database at the end
    new_cmd.append(PGCAT_CONFIG["database"])

    return new_cmd


def run_sequential_commands(
    commands: List[dict],
    phase_name: str,
    export_prefix: str,
    timestamp: str,
    duration: int,
    iostat_filter: str,
    via_pgcat: bool = False,
) -> List[CommandResult]:
    """
    Run a list of commands sequentially.
    Returns list of CommandResult.
    """
    results = []

    if not commands:
        return results

    print(f"\n--- {phase_name} Phase ---")

    for cmd_def in commands:
        cmd = cmd_def["cmd"].copy()

        # Replace placeholders
        cmd = [str(c).replace("{duration}", str(duration)) for c in cmd]

        # Modify for PgCat if needed
        cmd = modify_cmd_for_pgcat(cmd, via_pgcat)

        cmd_str = " ".join(shlex.quote(c) for c in cmd)

        print(f"  Running: {cmd_def['name']}...")

        # Output file
        output_file = OUTPUT_DIR / f"{export_prefix}_{phase_name.lower()}_{cmd_def['name']}_{timestamp}.txt"

        try:
            # Run command and capture output
            result = subprocess.run(
                cmd_str,
                shell=True,
                capture_output=True,
                text=True,
                timeout=duration + 60  # Allow some buffer
            )
            output = result.stdout + result.stderr
            output_file.write_text(output)
            success = result.returncode == 0
        except subprocess.TimeoutExpired:
            output = f"Command timed out after {duration + 60}s"
            success = False
        except Exception as e:
            output = f"Command failed: {e}"
            success = False

        results.append(CommandResult(
            name=f"{phase_name}:{cmd_def['name']}",
            cmd_str=cmd_str,
            output=output,
            success=success,
        ))

        # Cleanup if specified
        cleanup_path = cmd_def.get("cleanup")
        if cleanup_path:
            os.system(f"rm -f {cleanup_path} 2>/dev/null")

    return results


def run_benchmark(scenario_id: str, via_pgcat: bool = False) -> Optional[Path]:
    """
    Run a benchmark scenario with begin/parallel/end phases.

    Structure:
    - begin: commands to run sequentially before benchmark
    - parallel: commands to run concurrently (one marked primary=true controls duration)
    - end: commands to run sequentially after benchmark

    Args:
        scenario_id: The scenario number to run
        via_pgcat: If True, connect via PgCat pooler instead of direct PostgreSQL

    Returns path to the generated report.
    """
    import time

    scenario = SCENARIOS[scenario_id]
    disk = DISKS[scenario["target_disk"]]
    duration = scenario.get("duration", 60)

    display_name = get_display_name(scenario, disk)
    export_prefix = get_export_prefix(scenario, disk)

    # Add PgCat suffix if connecting via pooler
    if via_pgcat:
        display_name = f"{display_name} [via PgCat]"
        export_prefix = f"{export_prefix}_via_pgcat"
        # Set PGPASSWORD environment variable for pgbench/psql
        if PGCAT_CONFIG["password"]:
            os.environ["PGPASSWORD"] = PGCAT_CONFIG["password"]

    print(f"\n>>> Running: {display_name}")
    print("=" * 60)

    # Create output directory
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Collect system info
    print("Collecting system info...")
    system_info = collect_system_info()

    # Prepare iostat filter
    iostat_filter = build_iostat_filter(disk)
    command_results: List[CommandResult] = []

    # =========================================================================
    # PHASE 1: BEGIN (sequential)
    # =========================================================================
    begin_commands = scenario.get("begin", [])
    begin_results = run_sequential_commands(
        commands=begin_commands,
        phase_name="Begin",
        export_prefix=export_prefix,
        timestamp=timestamp,
        duration=duration,
        iostat_filter=iostat_filter,
        via_pgcat=via_pgcat,
    )
    command_results.extend(begin_results)

    # =========================================================================
    # PHASE 2: PARALLEL (concurrent)
    # =========================================================================
    parallel_commands = scenario.get("parallel", [])
    background_procs = []
    primary_cmd = None

    # Find primary command and start background commands
    print(f"\n--- Parallel Phase ({duration}s) ---")

    for cmd_def in parallel_commands:
        if cmd_def.get("primary", False):
            primary_cmd = cmd_def
        else:
            # Start as background process
            cmd = cmd_def["cmd"].copy()

            # Replace placeholders (add buffer for background commands)
            cmd = [str(c).replace("{duration}", str(duration + 10)) for c in cmd]

            # Modify for PgCat if needed
            cmd = modify_cmd_for_pgcat(cmd, via_pgcat)

            cmd_str = " ".join(shlex.quote(c) for c in cmd)

            # Output file
            output_file = OUTPUT_DIR / f"{export_prefix}_{cmd_def['name']}_{timestamp}.txt"

            # Build full command with filter if needed
            if cmd_def.get("filter_volumes", False):
                full_cmd = f"{cmd_str} | grep -E 'Device|{iostat_filter}' > {output_file} 2>&1"
            else:
                full_cmd = f"{cmd_str} > {output_file} 2>&1"

            # Start background process
            proc = subprocess.Popen(full_cmd, shell=True, preexec_fn=os.setsid)
            background_procs.append({
                "proc": proc,
                "name": cmd_def["name"],
                "cmd_str": cmd_str,
                "output_file": output_file,
            })
            print(f"  Started background: {cmd_def['name']}")

    # Wait for background processes to initialize
    if background_procs:
        time.sleep(2)

    # Run primary command in foreground (controls benchmark duration)
    if primary_cmd:
        cmd = primary_cmd["cmd"].copy()

        # Replace placeholders
        cmd = [str(c).replace("{duration}", str(duration)) for c in cmd]

        # Modify for PgCat if needed
        cmd = modify_cmd_for_pgcat(cmd, via_pgcat)

        cmd_str = " ".join(shlex.quote(c) for c in cmd)

        print(f"  Running primary: {primary_cmd['name']} ({duration}s)...")

        # Output file
        output_file = OUTPUT_DIR / f"{export_prefix}_{primary_cmd['name']}_{timestamp}.txt"

        # Check if command supports --output= flag (fio-specific)
        is_fio = cmd[0] == "fio" or (len(cmd) > 1 and cmd[1] == "fio")

        try:
            if is_fio:
                # fio uses --output= flag
                cmd_with_output = cmd + [f"--output={output_file}"]
                subprocess.run(cmd_with_output, check=True)
                output = output_file.read_text() if output_file.exists() else "No output"
            else:
                # Other commands: capture stdout/stderr directly
                result = subprocess.run(
                    cmd_str,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=duration + 120  # Buffer for startup/shutdown
                )
                output = result.stdout + result.stderr
                output_file.write_text(output)
            success = True
        except subprocess.TimeoutExpired:
            output = f"Command timed out after {duration + 120}s"
            success = False
        except subprocess.CalledProcessError as e:
            output = f"Command failed: {e}"
            success = False

        command_results.append(CommandResult(
            name=primary_cmd["name"],
            cmd_str=cmd_str,
            output=output,
            success=success,
        ))

        # Cleanup test file
        cleanup_path = primary_cmd.get("cleanup")
        if cleanup_path:
            os.system(f"rm -f {cleanup_path} 2>/dev/null")

    # Stop background processes and collect outputs
    if background_procs:
        print("  Stopping background commands...")
        time.sleep(2)

        for bg in background_procs:
            # Kill background process
            try:
                os.killpg(os.getpgid(bg["proc"].pid), signal.SIGTERM)
            except Exception:
                pass

            # Read output
            output = bg["output_file"].read_text() if bg["output_file"].exists() else "No output"
            command_results.append(CommandResult(
                name=bg["name"],
                cmd_str=bg["cmd_str"],
                output=output,
                success=True,
            ))

    # =========================================================================
    # PHASE 3: END (sequential)
    # =========================================================================
    end_commands = scenario.get("end", [])
    end_results = run_sequential_commands(
        commands=end_commands,
        phase_name="End",
        export_prefix=export_prefix,
        timestamp=timestamp,
        duration=duration,
        iostat_filter=iostat_filter,
        via_pgcat=via_pgcat,
    )
    command_results.extend(end_results)

    # Generate markdown report
    markdown = generate_report(
        scenario=scenario,
        disk=disk,
        system_info=system_info,
        command_results=command_results,
        timestamp=timestamp,
    )

    # Save report
    report_file = OUTPUT_DIR / f"{export_prefix}_report_{timestamp}.md"
    report_file.write_text(markdown)
    print(f"\nReport saved to: {report_file}")

    # Print quick summary
    print_quick_summary(command_results)

    # AI Analysis (optional)
    api_key = os.environ.get("GEMINI_API_KEY")
    if api_key:
        print("\n" + "=" * 60)
        print("Sending to AI for analysis...")
        print("=" * 60)

        ai_response = call_gemini(AI_PROMPT + markdown, api_key)

        ai_file = OUTPUT_DIR / f"{export_prefix}_report_ai_{timestamp}.md"
        ai_markdown = f"""# AI Analysis: {display_name}

**Generated:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

---

{ai_response}

---

## Appendix: Raw Benchmark Data

<details>
<summary>Click to expand raw data</summary>

{markdown}

</details>
"""
        ai_file.write_text(ai_markdown)
        print(f"AI analysis saved to: {ai_file}")

        # Print score card preview
        print_ai_scorecard(ai_response)

        return ai_file
    else:
        print("\n[!] GEMINI_API_KEY not set - skipping AI analysis")
        print("    Set it with: export GEMINI_API_KEY=your_key")
        return report_file


def generate_report(
    scenario: dict,
    disk: dict,
    system_info: str,
    command_results: List[CommandResult],
    timestamp: str,
) -> str:
    """Generate markdown report from benchmark results"""

    display_name = get_display_name(scenario, disk)
    volumes_str = ", ".join(disk["volumes"])

    sections = []

    # Header
    sections.append(f"# Benchmark: {display_name}")
    sections.append("")
    sections.append(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sections.append(f"**Scenario:** {scenario['desc']}")
    sections.append("")
    sections.append("---")
    sections.append("")

    # Target Disk
    sections.append("## Target Disk")
    sections.append("")
    sections.append("| Property | Value |")
    sections.append("|----------|-------|")
    sections.append(f"| **Name** | **{disk['name']}** |")
    sections.append(f"| **Mount Point** | `{disk['mount_point']}` |")
    sections.append(f"| **Device** | `{disk['device']}` |")
    sections.append(f"| **Volumes** | `{volumes_str}` |")
    sections.append("")
    sections.append("---")
    sections.append("")

    # System Configuration
    sections.append("## System Configuration")
    sections.append("")
    sections.append("```")
    sections.append(system_info)
    sections.append("```")
    sections.append("")
    sections.append("---")
    sections.append("")

    # Commands and Outputs
    for i, result in enumerate(command_results, 1):
        sections.append(f"## Command {i}: {result.name}")
        sections.append("")
        sections.append("### Command")
        sections.append("```bash")
        sections.append(result.cmd_str)
        sections.append("```")
        sections.append("")
        sections.append("### Output")
        sections.append("```")
        sections.append(result.output)
        sections.append("```")
        sections.append("")
        sections.append("---")
        sections.append("")

    return "\n".join(sections)


def print_quick_summary(command_results: List[CommandResult]):
    """Print quick summary from fio output"""
    print("\n--- Quick Summary ---")
    for result in command_results:
        if result.name == "fio":
            for line in result.output.split("\n"):
                if "IOPS=" in line or ("lat" in line.lower() and "percentiles" in line.lower()):
                    print(line.strip())
            break


def print_ai_scorecard(ai_response: str):
    """Print AI score card from response"""
    print("\n--- AI Score Card ---")
    in_table = False
    for line in ai_response.split("\n"):
        if "| Aspect |" in line or "| **Speed**" in line or "| **Stability**" in line or "| **Config" in line:
            print(line)
            in_table = True
        elif in_table and line.startswith("|"):
            print(line)
        elif in_table and not line.startswith("|"):
            in_table = False


# =============================================================================
# CLI
# =============================================================================

def show_menu():
    """Show interactive scenario menu"""
    print("\n" + "=" * 60)
    print("BENCHMARK TOOL - Disk & PostgreSQL")
    print("=" * 60)
    print("\nAvailable scenarios:\n")

    # Group by target
    wal_scenarios = []
    data_scenarios = []
    postgres_scenarios = []

    for key, scenario in SCENARIOS.items():
        disk = DISKS[scenario["target_disk"]]
        display_name = get_display_name(scenario, disk)
        if scenario["target_disk"] == "wal":
            wal_scenarios.append((key, display_name, scenario["desc"]))
        elif scenario["target_disk"] == "postgres":
            postgres_scenarios.append((key, display_name, scenario["desc"]))
        else:
            data_scenarios.append((key, display_name, scenario["desc"]))

    print("  WAL DISK:")
    for key, name, desc in wal_scenarios:
        print(f"    [{key}] {name}")
        print(f"        {desc}\n")

    print("  DATA DISK:")
    for key, name, desc in data_scenarios:
        print(f"    [{key}] {name}")
        print(f"        {desc}\n")

    if postgres_scenarios:
        print("  POSTGRESQL:")
        for key, name, desc in postgres_scenarios:
            print(f"    [{key}] {name}")
            print(f"        {desc}\n")

    print("  [q] Quit\n")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Disk Benchmark Tool")
    parser.add_argument("--run", type=str, help="Run scenario directly (e.g., --run 1)")
    parser.add_argument("--via-pgcat", action="store_true",
                        help="Connect via PgCat pooler instead of direct PostgreSQL")
    args = parser.parse_args()

    if os.geteuid() != 0:
        print("Error: Must run as root (sudo)")
        sys.exit(1)

    # Show PgCat config if enabled
    if args.via_pgcat:
        print(f"[PgCat Mode] Connecting via {PGCAT_CONFIG['host']}:{PGCAT_CONFIG['port']}")

    # Non-interactive mode
    if args.run:
        if args.run in SCENARIOS:
            run_benchmark(args.run, via_pgcat=args.via_pgcat)
        else:
            print(f"Unknown scenario: {args.run}")
            print(f"Available: {', '.join(SCENARIOS.keys())}")
            sys.exit(1)
        return

    # Interactive mode
    while True:
        show_menu()

        choice = input("Select scenario: ").strip().lower()

        if choice == "q":
            print("Bye!")
            break
        elif choice in SCENARIOS:
            run_benchmark(choice, via_pgcat=args.via_pgcat)
            input("\nPress Enter to continue...")
        else:
            print("Invalid choice!")


if __name__ == "__main__":
    main()
