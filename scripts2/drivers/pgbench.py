#!/usr/bin/env python3
"""
pgbench Driver - TPC-B benchmark implementation
"""
import re
import subprocess
from typing import Dict, Optional

from drivers.base import BaseDriver, BenchmarkResult


class PgbenchDriver(BaseDriver):
    """Driver for pgbench (TPC-B-like) benchmarks"""

    @property
    def name(self) -> str:
        return "pgbench"

    @property
    def benchmark_type(self) -> str:
        return "TPC-B"

    def build_schema(self, scale: Optional[int] = None) -> bool:
        """
        Initialize pgbench schema.

        Args:
            scale: Scale factor (default from config)

        Returns:
            True if successful
        """
        scale = scale or int(self.config.get('PGBENCH_SCALE', 100))
        database = self.config.get('PGBENCH_DATABASE', 'pgbench')

        cmd = f"sudo -u postgres pgbench -i -s {scale} {database}"

        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=3600
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Schema build failed: {e}")
            return False

    def run(
        self,
        duration: int,
        clients: int,
        threads: Optional[int] = None,
        read_only: bool = False,
        **kwargs
    ) -> BenchmarkResult:
        """
        Run pgbench benchmark.

        Args:
            duration: Test duration in seconds
            clients: Number of concurrent clients
            threads: Number of threads (default: clients or vCPU)
            read_only: If True, run SELECT-only workload

        Returns:
            BenchmarkResult with TPS and latency metrics
        """
        database = self.config.get('PGBENCH_DATABASE', 'pgbench')
        threads = threads or min(clients, int(self.config.get('VCPU', 8)))

        # Build command
        cmd_parts = [
            "sudo", "-u", "postgres", "pgbench",
            "-c", str(clients),
            "-j", str(threads),
            "-T", str(duration),
            "-P", "5",  # Progress every 5 seconds
        ]

        if read_only:
            cmd_parts.append("-S")

        cmd_parts.append(database)

        cmd_str = " ".join(cmd_parts)

        try:
            result = subprocess.run(
                cmd_str,
                shell=True,
                capture_output=True,
                text=True,
                timeout=duration + 120
            )
            raw_output = result.stdout + result.stderr
            return self.parse_output(raw_output, duration, clients)

        except subprocess.TimeoutExpired:
            return BenchmarkResult(
                name=self.benchmark_type,
                primary_metric=0,
                primary_metric_unit="TPS",
                duration_seconds=duration,
                success=False,
                error_message=f"Timeout after {duration + 120}s",
                raw_output=""
            )
        except Exception as e:
            return BenchmarkResult(
                name=self.benchmark_type,
                primary_metric=0,
                primary_metric_unit="TPS",
                duration_seconds=duration,
                success=False,
                error_message=str(e),
                raw_output=""
            )

    def parse_output(
        self,
        raw_output: str,
        duration: int = 60,
        clients: int = 100
    ) -> BenchmarkResult:
        """
        Parse pgbench output into BenchmarkResult.

        Example output:
        tps = 19703.588536 (without initial connection time)
        latency average = 5.069 ms
        latency stddev = 1.271 ms
        """
        tps = 0.0
        latency_avg = 0.0
        latency_stddev = 0.0
        total_txn = 0
        failed_txn = 0

        # Parse TPS
        tps_match = re.search(r'tps = ([\d.]+)', raw_output)
        if tps_match:
            tps = float(tps_match.group(1))

        # Parse latency average
        lat_avg_match = re.search(r'latency average = ([\d.]+) ms', raw_output)
        if lat_avg_match:
            latency_avg = float(lat_avg_match.group(1))

        # Parse latency stddev
        lat_std_match = re.search(r'latency stddev = ([\d.]+) ms', raw_output)
        if lat_std_match:
            latency_stddev = float(lat_std_match.group(1))

        # Parse transaction counts
        txn_match = re.search(r'number of transactions actually processed: (\d+)', raw_output)
        if txn_match:
            total_txn = int(txn_match.group(1))

        failed_match = re.search(r'number of failed transactions: (\d+)', raw_output)
        if failed_match:
            failed_txn = int(failed_match.group(1))

        # Extract progress data for P99 estimation
        progress_latencies = []
        for line in raw_output.split('\n'):
            if 'progress:' in line and 'lat' in line:
                # progress: 5.0 s, 19058.6 tps, lat 5.203 ms stddev 1.383
                lat_match = re.search(r'lat ([\d.]+) ms', line)
                if lat_match:
                    progress_latencies.append(float(lat_match.group(1)))

        # Estimate P99 from progress data (rough: avg + 2.5*stddev)
        latency_p99 = latency_avg + (2.5 * latency_stddev) if latency_stddev > 0 else latency_avg

        return BenchmarkResult(
            name=self.benchmark_type,
            primary_metric=tps,
            primary_metric_unit="TPS",
            duration_seconds=duration,
            latency_avg_ms=latency_avg,
            latency_stddev_ms=latency_stddev,
            latency_p99_ms=latency_p99,
            total_transactions=total_txn,
            failed_transactions=failed_txn,
            extra_metrics={
                "clients": clients,
                "scale": self.config.get('PGBENCH_SCALE', 'unknown'),
            },
            raw_output=raw_output,
            success=tps > 0
        )

    def warmup(self, duration: int = 30) -> bool:
        """Run warmup with SELECT-only workload"""
        print(f"  Running warmup ({duration}s)...")
        result = self.run(duration=duration, clients=16, read_only=True)
        return result.success
