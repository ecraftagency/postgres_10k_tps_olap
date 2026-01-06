#!/usr/bin/env python3
"""
Diagnostics Module - System and PostgreSQL metrics collection

This module provides unified metric collection that runs in parallel
with any benchmark driver (pgbench, hammerdb, fio).
"""
import os
import signal
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional


def run_cmd(cmd: str, capture: bool = True, timeout: int = 10) -> str:
    """Run shell command and return output"""
    try:
        if capture:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=timeout
            )
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
    sections.append(run_cmd(
        "curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'unknown'"
    ))
    sections.append(run_cmd("uname -a"))
    sections.append(run_cmd("lscpu | grep -E '^CPU\\(s\\)|^Model name|^Architecture'"))
    sections.append(run_cmd("free -h"))

    # OS Tuning
    sections.append("\n=== OS TUNING ===")
    sections.append(run_cmd(
        "sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio "
        "vm.dirty_expire_centisecs vm.dirty_writeback_centisecs 2>/dev/null"
    ))
    sections.append(run_cmd("cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null"))

    # HugePages
    sections.append("\n=== HUGEPAGES ===")
    sections.append(run_cmd("grep HugePages /proc/meminfo 2>/dev/null"))

    # Network
    sections.append("\n=== NETWORK ===")
    sections.append(run_cmd(
        "sysctl net.core.somaxconn net.core.rmem_max net.core.wmem_max "
        "net.ipv4.tcp_tw_reuse net.ipv4.tcp_fin_timeout 2>/dev/null"
    ))

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

    # PostgreSQL Config
    sections.append("\n=== POSTGRESQL CONFIG ===")
    sections.append(run_cmd(
        "sudo -u postgres psql -t -c \"SELECT name, setting, unit FROM pg_settings "
        "WHERE name IN ('shared_buffers', 'work_mem', 'effective_cache_size', "
        "'max_connections', 'wal_buffers', 'max_wal_size', 'huge_pages')\" 2>/dev/null"
    ))

    return "\n".join(sections)


@dataclass
class BackgroundCollector:
    """Background process for metric collection"""
    name: str
    cmd: str
    proc: Optional[subprocess.Popen] = None
    output_file: Optional[Path] = None
    output: str = ""

    def start(self, output_dir: Path, timestamp: str, prefix: str):
        """Start background collection"""
        self.output_file = output_dir / f"{prefix}_{self.name}_{timestamp}.txt"
        full_cmd = f"{self.cmd} > {self.output_file} 2>&1"
        self.proc = subprocess.Popen(full_cmd, shell=True, preexec_fn=os.setsid)

    def stop(self) -> str:
        """Stop collection and return output"""
        if self.proc:
            try:
                os.killpg(os.getpgid(self.proc.pid), signal.SIGTERM)
                time.sleep(1)
            except Exception:
                pass

        if self.output_file and self.output_file.exists():
            self.output = self.output_file.read_text()

        return self.output


class DiagnosticsCollector:
    """
    Unified diagnostics collector for all benchmarks.

    Runs iostat, mpstat, vmstat, and PostgreSQL stats in background
    during any benchmark.
    """

    def __init__(self, duration: int, output_dir: Path, volumes: Optional[List[str]] = None):
        """
        Initialize collector.

        Args:
            duration: Collection duration in seconds
            output_dir: Directory for output files
            volumes: List of disk volumes to filter (for iostat)
        """
        self.duration = duration
        self.output_dir = output_dir
        self.volumes = volumes or []
        self.collectors: List[BackgroundCollector] = []
        self.timestamp = ""
        self.prefix = ""

    def add_iostat(self):
        """Add iostat collector"""
        cmd = f"iostat -xz 1 {self.duration + 10}"
        if self.volumes:
            filter_pattern = "|".join(self.volumes)
            cmd = f"iostat -xz 1 {self.duration + 10} | grep -E 'Device|{filter_pattern}'"
        self.collectors.append(BackgroundCollector(name="iostat", cmd=cmd))

    def add_mpstat(self):
        """Add mpstat collector"""
        cmd = f"mpstat -P ALL 1 {self.duration + 10}"
        self.collectors.append(BackgroundCollector(name="mpstat", cmd=cmd))

    def add_vmstat(self):
        """Add vmstat collector"""
        cmd = f"vmstat 1 {self.duration + 10}"
        self.collectors.append(BackgroundCollector(name="vmstat", cmd=cmd))

    def add_pg_wait_events(self):
        """Add PostgreSQL wait events collector"""
        cmd = f"""bash -c 'for i in $(seq 1 {self.duration}); do
            echo "=== $(date +%H:%M:%S) ===";
            sudo -u postgres psql -t -c "
                SELECT coalesce(wait_event_type,'"'"'CPU'"'"') as type,
                       coalesce(wait_event,'"'"'Running'"'"') as event,
                       count(*) as cnt
                FROM pg_stat_activity
                WHERE state='"'"'active'"'"' AND pid<>pg_backend_pid()
                GROUP BY 1,2 ORDER BY 3 DESC LIMIT 5
            ";
            sleep 1;
        done'"""
        self.collectors.append(BackgroundCollector(name="pg_wait_events", cmd=cmd))

    def add_pg_stats(self):
        """Add PostgreSQL stats collector"""
        interval = max(5, self.duration // 12)
        iterations = self.duration // interval
        cmd = f"""bash -c 'echo "Time,HitRatio,TPS,Active,WaitLock,Deadlock,WalBytes";
        for i in $(seq 1 {iterations}); do
            sudo -u postgres psql -t -A -F'"'"','"'"' -c "
                SELECT to_char(now(), '"'"'HH24:MI:SS'"'"'),
                       round(d.blks_hit::numeric / (d.blks_hit + d.blks_read + 1) * 100, 2),
                       (d.xact_commit + d.xact_rollback),
                       (SELECT count(*) FROM pg_stat_activity WHERE state='"'"'active'"'"'),
                       (SELECT count(*) FROM pg_stat_activity WHERE wait_event_type='"'"'Lock'"'"'),
                       d.deadlocks,
                       w.wal_bytes
                FROM pg_stat_database d, pg_stat_wal w
                WHERE d.datname = current_database()
            ";
            sleep {interval};
        done'"""
        self.collectors.append(BackgroundCollector(name="pg_stats", cmd=cmd))

    def add_all_standard(self):
        """Add all standard collectors"""
        self.add_iostat()
        self.add_mpstat()
        self.add_pg_wait_events()
        self.add_pg_stats()

    def start(self, timestamp: str, prefix: str):
        """Start all collectors"""
        self.timestamp = timestamp
        self.prefix = prefix
        self.output_dir.mkdir(parents=True, exist_ok=True)

        for collector in self.collectors:
            collector.start(self.output_dir, timestamp, prefix)
            print(f"  Started collector: {collector.name}")

        # Wait for collectors to initialize
        time.sleep(2)

    def stop(self) -> Dict[str, str]:
        """Stop all collectors and return outputs"""
        print("  Stopping collectors...")
        time.sleep(2)

        results = {}
        for collector in self.collectors:
            results[collector.name] = collector.stop()

        return results


def reset_pg_stats():
    """Reset PostgreSQL statistics before benchmark"""
    run_cmd("sudo -u postgres psql -c 'SELECT pg_stat_reset()' 2>/dev/null")
    run_cmd("sudo -u postgres psql -c \"SELECT pg_stat_reset_shared('bgwriter')\" 2>/dev/null")


def run_checkpoint():
    """Run PostgreSQL checkpoint"""
    run_cmd("sudo -u postgres psql -c 'CHECKPOINT' 2>/dev/null", timeout=60)
