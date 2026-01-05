#!/usr/bin/env python3
"""
Benchmark Framework - Main Entry Point

Usage:
    ./bench.py --topology single-node --hardware r8g.2xlarge --workload tpc-b
    ./bench.py -L single-node -H r8g.2xlarge -W tpc-b --duration 60 --clients 100

Context naming: {topology}/{hardware}--{workload}
Report naming: {workload}_{timestamp}.md
"""
import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

# Add parent directory to path for imports
SCRIPT_DIR = Path(__file__).parent.resolve()
ROOT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(ROOT_DIR))

from core.config_loader import load_config
from core.diagnostics import (
    collect_system_info,
    DiagnosticsCollector,
    reset_pg_stats,
    run_checkpoint,
)
from core.reporter import generate_report, save_report, print_summary
from core.ai_analyzer import analyze_report, print_scorecard
from core.verifier import (
    verify_config,
    format_verification_table,
    format_verification_summary,
    print_verification,
    generate_config_matrix,
)
from drivers.base import BenchmarkResult
from drivers.pgbench import PgbenchDriver


# Driver registry
DRIVERS = {
    "tpc-b": PgbenchDriver,
    # "tpc-c": HammerDBDriver,  # TODO
    # "tpc-h": HammerDBDriver,  # TODO
}


def run_benchmark(
    topology: str,
    hardware: str,
    workload: str,
    duration: int = 60,
    clients: int = 100,
    warmup: bool = True,
    diagnostics_only: bool = False,
    skip_ai: bool = False,
    skip_verify: bool = False,
) -> Path:
    """
    Run benchmark with full diagnostics.

    Args:
        topology: Infrastructure topology (single-node, proxy-single, etc.)
        hardware: Hardware context name
        workload: Workload context name
        duration: Benchmark duration in seconds
        clients: Number of concurrent clients
        warmup: Whether to run warmup phase
        diagnostics_only: Only collect diagnostics (no benchmark)
        skip_ai: Skip AI analysis
        skip_verify: Skip config verification

    Returns:
        Path to generated report
    """
    # Build full context ID: topology/hardware--workload
    context_id = f"{topology}/{hardware}--{workload}"

    # Load merged configuration
    print(f"\n{'='*60}")
    print(f"BENCHMARK: {context_id}")
    print(f"{'='*60}")

    config = load_config(hardware, workload)
    # Override context_id with full path including topology
    config['CONTEXT_ID'] = context_id
    config['TOPOLOGY'] = topology

    print(f"Context: {context_id}")
    print(f"Duration: {duration}s, Clients: {clients}")

    # =========================================================================
    # CONFIG VERIFICATION (before benchmark)
    # =========================================================================
    verification_table = None
    config_matrix_md = None

    if not skip_verify:
        print("\n--- Config Verification ---")
        verification_results = verify_config(config)
        print_verification(verification_results)

        # Check for critical failures
        passed, failed, summary = format_verification_summary(verification_results)
        if failed > 0:
            print(f"\n  WARNING: {failed} settings don't match expected values")
            print("  Continuing with benchmark anyway...")

        verification_table = format_verification_table(verification_results)

    # Generate config matrix for report
    config_matrix_md = generate_config_matrix(config)

    # Get driver
    if workload not in DRIVERS:
        print(f"Error: No driver for workload '{workload}'")
        print(f"Available: {', '.join(DRIVERS.keys())}")
        sys.exit(1)

    driver_class = DRIVERS[workload]
    driver = driver_class(config)

    # Setup output directory
    output_dir = ROOT_DIR / "results"
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    # Collect system info
    print("\nCollecting system info...")
    system_info = collect_system_info()

    # Setup diagnostics collector
    volumes = ["md0", "md1"]  # RAID devices
    diagnostics = DiagnosticsCollector(
        duration=duration,
        output_dir=output_dir / context_id,
        volumes=volumes
    )
    diagnostics.add_all_standard()

    # Pre-benchmark setup
    print("\n--- Pre-Benchmark Setup ---")
    run_checkpoint()
    reset_pg_stats()

    # Warmup phase
    if warmup and not diagnostics_only:
        print("\n--- Warmup Phase ---")
        driver.warmup(duration=30)

    # Start diagnostics collectors
    print(f"\n--- {'Diagnostics' if diagnostics_only else 'Benchmark'} Phase ({duration}s) ---")
    diagnostics.start(timestamp, workload)

    # Run benchmark (unless diagnostics-only)
    if diagnostics_only:
        print("  Collecting diagnostics only (no benchmark)...")
        import time
        time.sleep(duration)
        benchmark_result = BenchmarkResult(
            name="Diagnostics",
            primary_metric=0,
            primary_metric_unit="N/A",
            duration_seconds=duration,
            raw_output="Diagnostics-only run",
            success=True
        )
    else:
        print(f"  Running {driver.benchmark_type} benchmark...")
        benchmark_result = driver.run(duration=duration, clients=clients)

    # Stop diagnostics and collect outputs
    diagnostic_outputs = diagnostics.stop()

    # Print summary
    print_summary(benchmark_result)

    # =========================================================================
    # GENERATE RICH REPORT
    # =========================================================================
    print("\n--- Generating Report ---")
    report = generate_report(
        benchmark_result=benchmark_result,
        system_info=system_info,
        diagnostics=diagnostic_outputs,
        config=config,
        verification_table=verification_table,
        config_matrix=config_matrix_md,
    )

    # Save report
    report_path = save_report(
        report=report,
        output_dir=output_dir,
        context_id=context_id,
        timestamp=timestamp,
        workload=workload,
    )
    print(f"Report saved: {report_path}")

    # AI Analysis
    if not skip_ai and not diagnostics_only:
        ai_response = analyze_report(report)
        if ai_response:
            # Save AI report
            ai_report = f"# AI Analysis\n\n{ai_response}\n\n---\n\n{report}"
            ai_path = save_report(
                report=ai_report,
                output_dir=output_dir,
                context_id=context_id,
                timestamp=timestamp,
                workload=workload,
                suffix="_ai"
            )
            print(f"AI analysis saved: {ai_path}")
            print_scorecard(ai_response)

    return report_path


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark Framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run TPC-B benchmark (single-node topology)
  ./bench.py -L single-node -H r8g.2xlarge -W tpc-b

  # Proxy topology
  ./bench.py --topology proxy-single --hardware r8g.2xlarge --workload tpc-b

  # Custom duration and clients
  ./bench.py -L single-node -H r8g.2xlarge -W tpc-b --duration 120 --clients 200

  # Diagnostics only (no benchmark)
  ./bench.py -L single-node -H r8g.2xlarge -W tpc-b --diagnostics-only

  # Skip AI analysis
  ./bench.py -L single-node -H r8g.2xlarge -W tpc-b --skip-ai
        """
    )

    parser.add_argument(
        "--topology", "-L",
        default="single-node",
        help="Infrastructure topology (default: single-node)"
    )
    parser.add_argument(
        "--hardware", "-H",
        required=True,
        help="Hardware context (e.g., r8g.2xlarge)"
    )
    parser.add_argument(
        "--workload", "-W",
        required=True,
        help="Workload context (e.g., tpc-b, tpc-c, tpc-h)"
    )
    parser.add_argument(
        "--duration", "-T",
        type=int,
        default=60,
        help="Benchmark duration in seconds (default: 60)"
    )
    parser.add_argument(
        "--clients", "-c",
        type=int,
        default=100,
        help="Number of concurrent clients (default: 100)"
    )
    parser.add_argument(
        "--no-warmup",
        action="store_true",
        help="Skip warmup phase"
    )
    parser.add_argument(
        "--diagnostics-only",
        action="store_true",
        help="Only collect diagnostics (no benchmark)"
    )
    parser.add_argument(
        "--skip-ai",
        action="store_true",
        help="Skip AI analysis"
    )
    parser.add_argument(
        "--skip-verify",
        action="store_true",
        help="Skip config verification"
    )

    args = parser.parse_args()

    # Check root
    if os.geteuid() != 0:
        print("Error: Must run as root (sudo)")
        sys.exit(1)

    # Run benchmark
    run_benchmark(
        topology=args.topology,
        hardware=args.hardware,
        workload=args.workload,
        duration=args.duration,
        clients=args.clients,
        warmup=not args.no_warmup,
        diagnostics_only=args.diagnostics_only,
        skip_ai=args.skip_ai,
        skip_verify=args.skip_verify,
    )


if __name__ == "__main__":
    main()
