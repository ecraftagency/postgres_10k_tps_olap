#!/usr/bin/env python3
"""
Reporter Module - Unified markdown report generation

Generates consistent reports across all benchmark types
with the same structure and format.

Features:
- Rich config matrix with all settings grouped by topic
- Verification results showing expected vs actual
- Phase-based output (begin/parallel/end commands)
- Full diagnostics with iostat, mpstat, pg_stat_*
"""
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

from drivers.base import BenchmarkResult, CommandResult


def generate_report(
    benchmark_result: BenchmarkResult,
    system_info: str,
    diagnostics: Dict[str, str],
    config: Dict[str, str],
    extra_commands: Optional[List[CommandResult]] = None,
    verification_table: Optional[str] = None,
    config_matrix: Optional[str] = None,
    phase_commands: Optional[Dict[str, List[CommandResult]]] = None,
) -> str:
    """
    Generate unified markdown report.

    Args:
        benchmark_result: Results from the benchmark driver
        system_info: System configuration info
        diagnostics: Dict of diagnostic outputs {name: output}
        config: Merged hardware + workload config
        extra_commands: Additional command outputs
        verification_table: Pre-formatted verification table markdown
        config_matrix: Pre-formatted config matrix markdown
        phase_commands: Commands organized by phase {begin: [], parallel: [], end: []}

    Returns:
        Markdown formatted report
    """
    sections = []

    context_id = config.get('CONTEXT_ID', 'unknown')
    hardware = config.get('HARDWARE_CONTEXT', 'unknown')
    workload = config.get('WORKLOAD_CONTEXT', 'unknown')
    instance = config.get('INSTANCE_TYPE', 'unknown')
    vcpu = config.get('VCPU', '?')
    ram = config.get('RAM_GB', '?')

    # Header
    sections.append(f"# Benchmark Report: {benchmark_result.name}")
    sections.append("")
    sections.append(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sections.append(f"**Context:** `{context_id}`")
    sections.append(f"**Hardware:** {instance} ({vcpu} vCPU, {ram} GB RAM)")
    sections.append(f"**Workload:** {workload}")
    sections.append("")

    # =========================================================================
    # SUMMARY BOX (Top-level metrics)
    # =========================================================================
    sections.append("## Summary")
    sections.append("")
    sections.append("| Metric | Value |")
    sections.append("|--------|-------|")
    sections.append(f"| **{benchmark_result.primary_metric_unit}** | **{benchmark_result.primary_metric:,.0f}** |")
    sections.append(f"| Duration | {benchmark_result.duration_seconds}s |")
    sections.append(f"| Avg Latency | {benchmark_result.latency_avg_ms:.2f}ms |")
    if benchmark_result.latency_stddev_ms > 0:
        sections.append(f"| Latency Stddev | {benchmark_result.latency_stddev_ms:.2f}ms |")
    if benchmark_result.latency_p99_ms > 0:
        sections.append(f"| P99 Latency | {benchmark_result.latency_p99_ms:.2f}ms |")
    if benchmark_result.total_transactions > 0:
        sections.append(f"| Total Transactions | {benchmark_result.total_transactions:,} |")
    if benchmark_result.failed_transactions > 0:
        sections.append(f"| Failed | {benchmark_result.failed_transactions} |")
    sections.append("")

    # Extra Metrics (benchmark-specific)
    if benchmark_result.extra_metrics:
        sections.append("### Additional Metrics")
        sections.append("")
        sections.append("| Metric | Value |")
        sections.append("|--------|-------|")
        for key, value in benchmark_result.extra_metrics.items():
            if isinstance(value, float):
                sections.append(f"| {key} | {value:.2f} |")
            else:
                sections.append(f"| {key} | {value} |")
        sections.append("")

    sections.append("---")
    sections.append("")

    # =========================================================================
    # CONFIG MATRIX (Full settings grouped by topic)
    # =========================================================================
    if config_matrix:
        sections.append(config_matrix)
        sections.append("---")
        sections.append("")
    else:
        # Fallback to simple key settings
        sections.append("## Configuration")
        sections.append("")
        sections.append("### Key Settings")
        sections.append("")
        sections.append("| Setting | Value |")
        sections.append("|---------|-------|")

        key_settings = [
            ('INSTANCE_TYPE', 'Instance'),
            ('VCPU', 'vCPU'),
            ('RAM_GB', 'RAM (GB)'),
            ('PG_SHARED_BUFFERS', 'shared_buffers'),
            ('PG_HUGE_PAGES', 'huge_pages'),
            ('PG_WORK_MEM', 'work_mem'),
            ('PG_WAL_BUFFERS', 'wal_buffers'),
            ('PG_MAX_CONNECTIONS', 'max_connections'),
            ('VM_NR_HUGEPAGES', 'HugePages'),
            ('PG_BGWRITER_DELAY', 'bgwriter_delay'),
            ('PG_COMMIT_DELAY', 'commit_delay'),
            ('PGBENCH_SCALE', 'pgbench_scale'),
        ]

        for key, label in key_settings:
            if key in config:
                sections.append(f"| {label} | `{config[key]}` |")

        sections.append("")
        sections.append("---")
        sections.append("")

    # =========================================================================
    # VERIFICATION TABLE (Expected vs Actual)
    # =========================================================================
    if verification_table:
        sections.append("## Configuration Verification")
        sections.append("")
        sections.append(verification_table)
        sections.append("---")
        sections.append("")

    # =========================================================================
    # SYSTEM INFO
    # =========================================================================
    sections.append("## System Configuration")
    sections.append("")
    sections.append("```")
    sections.append(system_info)
    sections.append("```")
    sections.append("")
    sections.append("---")
    sections.append("")

    # =========================================================================
    # BENCHMARK OUTPUT
    # =========================================================================
    sections.append("## Benchmark Output")
    sections.append("")
    sections.append("```")
    sections.append(benchmark_result.raw_output)
    sections.append("```")
    sections.append("")
    sections.append("---")
    sections.append("")

    # =========================================================================
    # PHASE COMMANDS (begin/parallel/end)
    # =========================================================================
    if phase_commands:
        sections.append("## Command Outputs")
        sections.append("")

        for phase_name in ['begin', 'parallel', 'end']:
            commands = phase_commands.get(phase_name, [])
            if commands:
                sections.append(f"### Phase: {phase_name.upper()}")
                sections.append("")

                for cmd_result in commands:
                    sections.append(f"#### {cmd_result.name}")
                    sections.append("")
                    sections.append("**Command:**")
                    sections.append("```bash")
                    sections.append(cmd_result.cmd_str)
                    sections.append("```")
                    sections.append("")
                    sections.append("**Output:**")
                    sections.append("```")
                    # Truncate long outputs
                    lines = cmd_result.output.split('\n')
                    if len(lines) > 100:
                        sections.append('\n'.join(lines[:50]))
                        sections.append(f"\n... ({len(lines) - 100} lines omitted) ...\n")
                        sections.append('\n'.join(lines[-50:]))
                    else:
                        sections.append(cmd_result.output)
                    sections.append("```")
                    sections.append("")

        sections.append("---")
        sections.append("")

    # =========================================================================
    # DIAGNOSTICS (iostat, mpstat, pg_stat_*, etc.)
    # =========================================================================
    if diagnostics:
        sections.append("## Diagnostics")
        sections.append("")

        for name, output in diagnostics.items():
            sections.append(f"### {name}")
            sections.append("")
            sections.append("```")
            # Truncate very long outputs
            lines = output.split('\n')
            if len(lines) > 100:
                sections.append('\n'.join(lines[:50]))
                sections.append(f"\n... ({len(lines) - 100} lines omitted) ...\n")
                sections.append('\n'.join(lines[-50:]))
            else:
                sections.append(output)
            sections.append("```")
            sections.append("")

        sections.append("---")
        sections.append("")

    # =========================================================================
    # EXTRA COMMANDS (legacy support)
    # =========================================================================
    if extra_commands:
        sections.append("## Additional Commands")
        sections.append("")

        for i, result in enumerate(extra_commands, 1):
            sections.append(f"### {result.name}")
            sections.append("")
            sections.append("**Command:**")
            sections.append("```bash")
            sections.append(result.cmd_str)
            sections.append("```")
            sections.append("")
            sections.append("**Output:**")
            sections.append("```")
            sections.append(result.output)
            sections.append("```")
            sections.append("")

    return "\n".join(sections)


def save_report(
    report: str,
    output_dir: Path,
    context_id: str,
    timestamp: str,
    suffix: str = "",
) -> Path:
    """
    Save report to file with proper naming.

    Args:
        report: Markdown report content
        output_dir: Base output directory
        context_id: Hardware--workload context
        timestamp: Timestamp string
        suffix: Optional suffix (e.g., "_ai")

    Returns:
        Path to saved report
    """
    # Create context-specific directory
    context_dir = output_dir / context_id
    context_dir.mkdir(parents=True, exist_ok=True)

    # Generate filename
    filename = f"{timestamp}{suffix}.md"
    report_path = context_dir / filename

    report_path.write_text(report)
    return report_path


def print_summary(result: BenchmarkResult):
    """Print quick summary to console"""
    print("\n" + "=" * 60)
    print("BENCHMARK RESULTS")
    print("=" * 60)
    print(f"\n  {result.summary()}")

    if result.extra_metrics:
        print("\n  Additional metrics:")
        for key, value in result.extra_metrics.items():
            if isinstance(value, float):
                print(f"    - {key}: {value:.2f}")
            else:
                print(f"    - {key}: {value}")

    print("")
