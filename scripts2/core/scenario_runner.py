#!/usr/bin/env python3
"""
Scenario Runner - Execute JSON-defined benchmark scenarios

100% compatible with old bench.py features:
- begin/parallel/end phase structure
- Background process handling for collectors
- FIO disk benchmarks (scenarios 1-10)
- PostgreSQL benchmarks via pgbench (scenarios 11-14)
- PgCat connection pooler support (--via-pgcat)
- AI Analysis via API
- Markdown report generation

Usage:
    ./scenario_runner.py --scenario 1 --hardware r8g.large
    ./scenario_runner.py --scenario 11 --hardware r8g.large --duration 60
    ./scenario_runner.py --via-pgcat --scenario 11  # Via connection pooler
    ./scenario_runner.py --list  # List all scenarios
    ./scenario_runner.py  # Interactive menu
"""
import argparse
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
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

SCRIPT_DIR = Path(__file__).parent.resolve()
ROOT_DIR = SCRIPT_DIR.parent

# PgCat connection pooler config
PGCAT_CONFIG = {
    "host": os.environ.get("PGCAT_HOST", "localhost"),
    "port": os.environ.get("PGCAT_PORT", "5432"),
    "user": os.environ.get("PGCAT_USER", "postgres"),
    "password": os.environ.get("PGCAT_PASSWORD", ""),
    "database": os.environ.get("PGCAT_DATABASE", "pgbench"),
}


@dataclass
class CommandResult:
    """Result of a single command execution"""
    name: str
    cmd_str: str
    output: str
    success: bool
    is_primary: bool = False


class ScenarioRunner:
    """Execute benchmark scenarios from JSON definition - 100% compatible with old bench.py"""

    def __init__(self, hardware: str, scenarios_file: Optional[Path] = None):
        self.hardware = hardware
        self.scenarios_file = scenarios_file or ROOT_DIR / "workloads" / "tpc-b" / "scenarios.json"
        self.scenarios_data = self._load_scenarios()
        self.results_dir = ROOT_DIR / "results"

    def _load_scenarios(self) -> Dict:
        """Load scenarios from JSON file"""
        with open(self.scenarios_file) as f:
            return json.load(f)

    @property
    def disks(self) -> Dict:
        return self.scenarios_data.get("disks", {})

    @property
    def scenarios(self) -> Dict:
        return self.scenarios_data.get("scenarios", {})

    def list_scenarios(self) -> None:
        """Print list of available scenarios (grouped by target)"""
        print("\n" + "=" * 70)
        print("BENCHMARK SCENARIOS")
        print("=" * 70)

        # Group by target
        wal_scenarios = []
        data_scenarios = []
        postgres_scenarios = []

        for sid, scenario in sorted(self.scenarios.items(), key=lambda x: int(x[0])):
            target = scenario.get("target_disk", "data")
            disk = self.disks.get(target, {})
            entry = (sid, scenario["name"], scenario["desc"])

            if target == "wal":
                wal_scenarios.append(entry)
            elif target == "postgres":
                postgres_scenarios.append(entry)
            else:
                data_scenarios.append(entry)

        print("\n  WAL DISK (FIO):")
        for sid, name, desc in wal_scenarios:
            print(f"    [{sid:>2}] {name:<20} - {desc}")

        print("\n  DATA DISK (FIO):")
        for sid, name, desc in data_scenarios:
            print(f"    [{sid:>2}] {name:<20} - {desc}")

        print("\n  POSTGRESQL (pgbench):")
        for sid, name, desc in postgres_scenarios:
            print(f"    [{sid:>2}] {name:<20} - {desc}")

        print("\n" + "=" * 70)
        print(f"Total: {len(self.scenarios)} scenarios")
        print("=" * 70 + "\n")

    def interactive_menu(self, via_pgcat: bool = False) -> None:
        """Interactive menu for selecting scenarios"""
        while True:
            self.list_scenarios()
            print("  [q] Quit\n")

            choice = input("Select scenario: ").strip().lower()

            if choice == "q":
                print("Bye!")
                break
            elif choice in self.scenarios:
                self.run_scenario(choice, via_pgcat=via_pgcat)
                input("\nPress Enter to continue...")
            else:
                print("Invalid choice!")

    def _modify_cmd_for_pgcat(self, cmd: List[str], via_pgcat: bool) -> List[str]:
        """Modify pgbench/psql commands to connect via PgCat"""
        if not via_pgcat:
            return cmd

        # Find pgbench or psql in the command
        pg_cmd_idx = -1
        for i, arg in enumerate(cmd):
            if arg in ("pgbench", "psql"):
                pg_cmd_idx = i
                break

        if pg_cmd_idx == -1:
            return cmd

        # Skip "sudo -u postgres" prefix
        start_idx = 0
        if len(cmd) >= 3 and cmd[0] == "sudo" and cmd[1] == "-u" and cmd[2] == "postgres":
            start_idx = 3

        # Build new command
        new_cmd = [cmd[pg_cmd_idx]]
        new_cmd.extend([
            "-h", PGCAT_CONFIG["host"],
            "-p", PGCAT_CONFIG["port"],
            "-U", PGCAT_CONFIG["user"],
        ])

        # Process remaining args
        remaining = cmd[pg_cmd_idx + 1:]
        skip_next = False

        for i, arg in enumerate(remaining):
            if skip_next:
                skip_next = False
                continue
            if arg in ("-h", "-p", "-U", "-d", "--host", "--port", "--username", "--dbname"):
                skip_next = True
                continue
            if i == len(remaining) - 1 and not arg.startswith("-"):
                continue
            new_cmd.append(arg)

        new_cmd.append(PGCAT_CONFIG["database"])
        return new_cmd

    def _build_iostat_filter(self, disk: Dict) -> str:
        """Build iostat grep filter for target volumes"""
        device_name = disk.get("device", "").split("/")[-1]
        volumes = "|".join(disk.get("volumes", []))
        return f"{device_name}|{volumes}"

    def run_scenario(
        self,
        scenario_id: str,
        duration: Optional[int] = None,
        via_pgcat: bool = False,
    ) -> Path:
        """
        Run a single scenario with begin/parallel/end phases.

        Args:
            scenario_id: Scenario number (1-14)
            duration: Override duration (uses scenario default if None)
            via_pgcat: Connect via PgCat pooler

        Returns:
            Path to generated report
        """
        if scenario_id not in self.scenarios:
            raise ValueError(f"Scenario {scenario_id} not found")

        scenario = self.scenarios[scenario_id]
        disk = self.disks.get(scenario.get("target_disk", "data"), {})
        duration = duration or scenario.get("duration", 60)

        display_name = f"[{disk.get('name', 'DISK')}] {scenario['name']} - {scenario['desc']}"
        export_prefix = scenario.get("id", f"scenario_{scenario_id}")

        if via_pgcat:
            display_name = f"{display_name} [via PgCat]"
            export_prefix = f"{export_prefix}_via_pgcat"
            if PGCAT_CONFIG["password"]:
                os.environ["PGPASSWORD"] = PGCAT_CONFIG["password"]

        print(f"\n>>> Running: {display_name}")
        print("=" * 70)

        # Setup
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_dir = self.results_dir / "single-node" / f"{self.hardware}--scenarios"
        output_dir.mkdir(parents=True, exist_ok=True)

        # Collect system info
        print("Collecting system info...")
        system_info = self._collect_system_info()

        # Prepare iostat filter
        iostat_filter = self._build_iostat_filter(disk)
        command_results: List[CommandResult] = []

        # =====================================================================
        # PHASE 1: BEGIN (sequential)
        # =====================================================================
        begin_results = self._run_sequential_commands(
            commands=scenario.get("begin", []),
            phase_name="Begin",
            export_prefix=export_prefix,
            timestamp=timestamp,
            duration=duration,
            output_dir=output_dir,
            via_pgcat=via_pgcat,
        )
        command_results.extend(begin_results)

        # =====================================================================
        # PHASE 2: PARALLEL (concurrent with background processes)
        # =====================================================================
        parallel_results = self._run_parallel_commands(
            commands=scenario.get("parallel", []),
            export_prefix=export_prefix,
            timestamp=timestamp,
            duration=duration,
            output_dir=output_dir,
            iostat_filter=iostat_filter,
            via_pgcat=via_pgcat,
        )
        command_results.extend(parallel_results)

        # =====================================================================
        # PHASE 3: END (sequential)
        # =====================================================================
        end_results = self._run_sequential_commands(
            commands=scenario.get("end", []),
            phase_name="End",
            export_prefix=export_prefix,
            timestamp=timestamp,
            duration=duration,
            output_dir=output_dir,
            via_pgcat=via_pgcat,
        )
        command_results.extend(end_results)

        # Generate report
        report_path = self._generate_report(
            scenario=scenario,
            disk=disk,
            system_info=system_info,
            command_results=command_results,
            output_dir=output_dir,
            export_prefix=export_prefix,
            timestamp=timestamp,
        )

        # Print quick summary
        self._print_quick_summary(command_results)

        print(f"\nReport saved: {report_path}")
        return report_path

    def _run_sequential_commands(
        self,
        commands: List[Dict],
        phase_name: str,
        export_prefix: str,
        timestamp: str,
        duration: int,
        output_dir: Path,
        via_pgcat: bool = False,
    ) -> List[CommandResult]:
        """Run commands sequentially"""
        results = []

        if not commands:
            return results

        print(f"\n--- {phase_name} Phase ---")

        for cmd_def in commands:
            cmd = [str(c).replace("{duration}", str(duration)) for c in cmd_def.get("cmd", [])]
            cmd = self._modify_cmd_for_pgcat(cmd, via_pgcat)
            cmd_str = " ".join(shlex.quote(c) for c in cmd)

            print(f"  Running: {cmd_def.get('name', 'unknown')}...")

            try:
                result = subprocess.run(
                    cmd_str,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=duration + 60,
                )
                output = result.stdout + result.stderr
                success = result.returncode == 0
            except Exception as e:
                output = f"Error: {e}"
                success = False

            # Save output
            output_file = output_dir / f"{export_prefix}_{phase_name.lower()}_{cmd_def.get('name', 'cmd')}_{timestamp}.txt"
            output_file.write_text(output)

            results.append(CommandResult(
                name=f"{phase_name}:{cmd_def.get('name', 'unknown')}",
                cmd_str=cmd_str,
                output=output,
                success=success,
            ))

            # Cleanup
            cleanup_path = cmd_def.get("cleanup")
            if cleanup_path:
                os.system(f"rm -f {cleanup_path} 2>/dev/null")

        return results

    def _run_parallel_commands(
        self,
        commands: List[Dict],
        export_prefix: str,
        timestamp: str,
        duration: int,
        output_dir: Path,
        iostat_filter: str,
        via_pgcat: bool = False,
    ) -> List[CommandResult]:
        """Run commands in parallel - background collectors + foreground primary"""
        results = []
        background_procs = []
        primary_cmd = None

        print(f"\n--- Parallel Phase ({duration}s) ---")

        # Find primary and start background commands
        for cmd_def in commands:
            if cmd_def.get("primary", False):
                primary_cmd = cmd_def
            else:
                # Start as background process
                cmd = [str(c).replace("{duration}", str(duration + 10)) for c in cmd_def.get("cmd", [])]
                cmd = self._modify_cmd_for_pgcat(cmd, via_pgcat)
                cmd_str = " ".join(shlex.quote(c) for c in cmd)

                output_file = output_dir / f"{export_prefix}_{cmd_def.get('name', 'bg')}_{timestamp}.txt"

                # Build command with filter if needed
                if cmd_def.get("filter_volumes", False):
                    full_cmd = f"{cmd_str} | grep -E 'Device|{iostat_filter}' > {output_file} 2>&1"
                else:
                    full_cmd = f"{cmd_str} > {output_file} 2>&1"

                proc = subprocess.Popen(full_cmd, shell=True, preexec_fn=os.setsid)
                background_procs.append({
                    "proc": proc,
                    "name": cmd_def.get("name", "bg"),
                    "cmd_str": cmd_str,
                    "output_file": output_file,
                })
                print(f"  Started background: {cmd_def.get('name', 'unknown')}")

        # Wait for backgrounds to initialize
        if background_procs:
            time.sleep(2)

        # Run primary command in foreground
        if primary_cmd:
            cmd = [str(c).replace("{duration}", str(duration)) for c in primary_cmd.get("cmd", [])]
            cmd = self._modify_cmd_for_pgcat(cmd, via_pgcat)
            cmd_str = " ".join(shlex.quote(c) for c in cmd)

            print(f"  Running primary: {primary_cmd.get('name', 'primary')} ({duration}s)...")

            output_file = output_dir / f"{export_prefix}_{primary_cmd.get('name', 'primary')}_{timestamp}.txt"

            # Check if FIO
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
                output = f"Error: {e}"
                success = False

            results.append(CommandResult(
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
            print("  Stopping background commands...")
            time.sleep(2)

            for bg in background_procs:
                try:
                    os.killpg(os.getpgid(bg["proc"].pid), signal.SIGTERM)
                except Exception:
                    pass

                output = bg["output_file"].read_text() if bg["output_file"].exists() else "No output"
                results.append(CommandResult(
                    name=bg["name"],
                    cmd_str=bg["cmd_str"],
                    output=output,
                    success=True,
                ))

        return results

    def _collect_system_info(self) -> str:
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
            "\n=== OS TUNING ===",
            run_cmd("sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio 2>/dev/null"),
            run_cmd("cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null"),
            "\n=== HUGEPAGES ===",
            run_cmd("grep -E 'HugePages|Hugepagesize' /proc/meminfo"),
            "\n=== NETWORK ===",
            run_cmd("sysctl net.core.somaxconn net.core.rmem_max 2>/dev/null"),
            "\n=== DISK - RAID ===",
            run_cmd("cat /proc/mdstat"),
            run_cmd("mdadm --detail /dev/md0 2>/dev/null | head -20"),
            run_cmd("mdadm --detail /dev/md1 2>/dev/null | head -20"),
            "\n=== DISK - BLOCK TUNING ===",
            "--- md0 ---",
            f"read_ahead_kb: {run_cmd('cat /sys/block/md0/queue/read_ahead_kb 2>/dev/null')}",
            "--- md1 ---",
            f"read_ahead_kb: {run_cmd('cat /sys/block/md1/queue/read_ahead_kb 2>/dev/null')}",
            "\n=== DISK - MOUNT ===",
            run_cmd("mount | grep -E '/data|/wal'"),
            run_cmd("df -h /data /wal 2>/dev/null"),
            "\n=== POSTGRESQL CONFIG ===",
            run_cmd("sudo -u postgres psql -t -c \"SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers','work_mem','effective_cache_size','max_connections','wal_buffers','max_wal_size','huge_pages')\" 2>/dev/null"),
        ]
        return "\n".join(sections)

    def _generate_report(
        self,
        scenario: Dict,
        disk: Dict,
        system_info: str,
        command_results: List[CommandResult],
        output_dir: Path,
        export_prefix: str,
        timestamp: str,
    ) -> Path:
        """Generate markdown report"""
        display_name = f"[{disk.get('name', 'DISK')}] {scenario['name']}"

        # Find primary result for metrics
        primary_result = next((r for r in command_results if r.is_primary), None)
        metrics = {}

        if primary_result:
            if "fio" in primary_result.name.lower():
                metrics = self._parse_fio_output(primary_result.output)
            elif "pgbench" in primary_result.name.lower():
                metrics = self._parse_pgbench_output(primary_result.output)

        # Build report
        lines = [
            f"# Benchmark Report: {display_name}",
            "",
            f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"**Context:** `single-node/{self.hardware}--scenario-{scenario.get('id', 'unknown')}`",
            f"**Hardware:** {self.hardware}",
            f"**Scenario:** {scenario['desc']}",
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
            "## Target Disk",
            "",
            "| Property | Value |",
            "|----------|-------|",
            f"| Name | {disk.get('name', 'N/A')} |",
            f"| Mount Point | `{disk.get('mount_point', 'N/A')}` |",
            f"| Device | `{disk.get('device', 'N/A')}` |",
            "",
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

        # Command outputs
        for i, result in enumerate(command_results, 1):
            lines.extend([
                f"## Command {i}: {result.name}",
                "",
                "### Command",
                "```bash",
                result.cmd_str,
                "```",
                "",
                "### Output",
                "```",
                result.output[:10000] if len(result.output) > 10000 else result.output,
                "```",
                "",
                "---",
                "",
            ])

        report = "\n".join(lines)

        # Save
        report_path = output_dir / f"{export_prefix}_report_{timestamp}.md"
        report_path.write_text(report)

        return report_path

    def _parse_fio_output(self, output: str) -> Dict[str, str]:
        """Parse FIO output for key metrics"""
        metrics = {}

        iops_match = re.search(r'IOPS=(\d+\.?\d*[kKmM]?)', output)
        if iops_match:
            metrics["IOPS"] = iops_match.group(1)

        bw_match = re.search(r'BW=(\d+\.?\d*\s*[kKmMgG]?i?B/s)', output)
        if bw_match:
            metrics["Bandwidth"] = bw_match.group(1)

        lat_avg = re.search(r'lat.*avg=\s*(\d+\.?\d*)', output)
        if lat_avg:
            metrics["Avg Latency"] = f"{lat_avg.group(1)}us"

        p99 = re.search(r'99\.00th=\[\s*(\d+)\]', output)
        if p99:
            metrics["P99 Latency"] = f"{p99.group(1)}us"

        return metrics

    def _parse_pgbench_output(self, output: str) -> Dict[str, str]:
        """Parse pgbench output for key metrics"""
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

    def _print_quick_summary(self, results: List[CommandResult]) -> None:
        """Print quick summary from results"""
        print("\n--- Quick Summary ---")

        for result in results:
            if result.is_primary:
                if "fio" in result.name.lower():
                    for line in result.output.split("\n"):
                        if "IOPS=" in line or "bw=" in line.lower():
                            print(f"  {line.strip()}")
                elif "pgbench" in result.name.lower():
                    for line in result.output.split("\n"):
                        if "tps =" in line or "latency" in line:
                            print(f"  {line.strip()}")


def main():
    parser = argparse.ArgumentParser(
        description="Scenario Runner - 100% compatible with old bench.py",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("--list", "-l", action="store_true", help="List scenarios")
    parser.add_argument("--scenario", "-s", type=str, help="Scenario number (1-14)")
    parser.add_argument("--hardware", "-H", default="r8g.large", help="Hardware context")
    parser.add_argument("--duration", "-T", type=int, help="Override duration")
    parser.add_argument("--via-pgcat", action="store_true", help="Connect via PgCat pooler")
    parser.add_argument("--all", action="store_true", help="Run all scenarios")

    args = parser.parse_args()

    runner = ScenarioRunner(hardware=args.hardware)

    if args.list:
        runner.list_scenarios()
        return

    if args.all:
        for sid in sorted(runner.scenarios.keys(), key=int):
            try:
                runner.run_scenario(sid, duration=args.duration, via_pgcat=args.via_pgcat)
            except Exception as e:
                print(f"Scenario {sid} failed: {e}")
        return

    if args.scenario:
        if os.geteuid() != 0:
            print("Error: Must run as root (sudo)")
            sys.exit(1)
        runner.run_scenario(args.scenario, duration=args.duration, via_pgcat=args.via_pgcat)
        return

    # Interactive mode
    if os.geteuid() != 0:
        print("Error: Must run as root (sudo)")
        sys.exit(1)
    runner.interactive_menu(via_pgcat=args.via_pgcat)


if __name__ == "__main__":
    main()
