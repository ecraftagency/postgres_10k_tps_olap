#!/usr/bin/env python3
"""
Sysbench Driver - OLTP benchmark implementation

Supports:
- oltp_read_only: Read-only OLTP workload
- oltp_read_write: Mixed read/write OLTP
- oltp_write_only: Write-only OLTP
- oltp_point_select: Point SELECT queries
"""
import re
import subprocess
from typing import Dict, Optional

from drivers.base import BaseDriver, BenchmarkResult


class SysbenchDriver(BaseDriver):
    """Driver for sysbench OLTP benchmarks"""

    def __init__(self, config: Dict[str, str], test_type: str = "oltp_read_only"):
        """
        Initialize sysbench driver.

        Args:
            config: Merged hardware + workload configuration
            test_type: Sysbench test type (oltp_read_only, oltp_read_write, etc.)
        """
        super().__init__(config)
        self.test_type = test_type

    @property
    def name(self) -> str:
        return "sysbench"

    @property
    def benchmark_type(self) -> str:
        type_map = {
            "oltp_read_only": "OLTP-Read",
            "oltp_read_write": "OLTP-RW",
            "oltp_write_only": "OLTP-Write",
            "oltp_point_select": "OLTP-Point",
        }
        return type_map.get(self.test_type, "OLTP")

    def _get_connection_args(self) -> list:
        """Build sysbench PostgreSQL connection arguments"""
        return [
            "--db-driver=pgsql",
            f"--pgsql-host={self.config.get('SYSBENCH_HOST', '127.0.0.1')}",
            f"--pgsql-port={self.config.get('PG_PORT', '5432')}",
            f"--pgsql-user={self.config.get('SYSBENCH_USER', 'postgres')}",
            f"--pgsql-password={self.config.get('SYSBENCH_PASSWORD', 'postgres')}",
            f"--pgsql-db={self.config.get('SYSBENCH_DATABASE', 'sysbench')}",
        ]

    def build_schema(self, tables: Optional[int] = None, table_size: Optional[int] = None) -> bool:
        """
        Initialize sysbench schema (prepare tables).

        Args:
            tables: Number of tables (default from config)
            table_size: Rows per table (default from config)

        Returns:
            True if successful
        """
        tables = tables or int(self.config.get('SYSBENCH_TABLES', 10))
        table_size = table_size or int(self.config.get('SYSBENCH_TABLE_SIZE', 1000000))
        threads = int(self.config.get('VCPU', 2))

        # Ensure database exists
        db_name = self.config.get('SYSBENCH_DATABASE', 'sysbench')
        check_cmd = f"sudo -u postgres psql -tc \"SELECT 1 FROM pg_database WHERE datname = '{db_name}'\""
        result = subprocess.run(check_cmd, shell=True, capture_output=True, text=True)

        if '1' not in result.stdout:
            create_cmd = f"sudo -u postgres createdb {db_name}"
            subprocess.run(create_cmd, shell=True)

        # Build sysbench prepare command
        cmd_parts = ["sysbench", self.test_type]
        cmd_parts.extend(self._get_connection_args())
        cmd_parts.extend([
            f"--tables={tables}",
            f"--table-size={table_size}",
            f"--threads={threads}",
            "prepare"
        ])

        cmd_str = " ".join(cmd_parts)
        print(f"  Preparing {tables} tables x {table_size:,} rows...")

        try:
            result = subprocess.run(
                cmd_str, shell=True, capture_output=True, text=True, timeout=3600
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
        **kwargs
    ) -> BenchmarkResult:
        """
        Run sysbench benchmark.

        Args:
            duration: Test duration in seconds
            clients: Number of concurrent threads
            threads: Alias for clients (sysbench uses threads)

        Returns:
            BenchmarkResult with TPS/QPS and latency metrics
        """
        tables = int(self.config.get('SYSBENCH_TABLES', 10))
        table_size = int(self.config.get('SYSBENCH_TABLE_SIZE', 1000000))
        threads = threads or clients

        # Build command
        cmd_parts = ["sysbench", self.test_type]
        cmd_parts.extend(self._get_connection_args())
        cmd_parts.extend([
            f"--tables={tables}",
            f"--table-size={table_size}",
            f"--threads={threads}",
            f"--time={duration}",
            "--report-interval=10",
            "run"
        ])

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
            return self.parse_output(raw_output, duration, threads)

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
        threads: int = 32
    ) -> BenchmarkResult:
        """
        Parse sysbench output into BenchmarkResult.

        Example output:
        SQL statistics:
            queries performed:
                read:                            1800008
                write:                           0
                other:                           257144
                total:                           2057152
            transactions:                        128572 (2141.60 per sec.)
            queries:                             2057152 (34265.66 per sec.)

        Latency (ms):
             min:                                    0.91
             avg:                                   14.93
             max:                                  135.64
             95th percentile:                       20.00
        """
        tps = 0.0
        qps = 0.0
        latency_avg = 0.0
        latency_min = 0.0
        latency_max = 0.0
        latency_p95 = 0.0
        total_txn = 0
        read_queries = 0
        write_queries = 0

        # Parse transactions per second
        tps_match = re.search(r'transactions:\s+(\d+)\s+\(([\d.]+)\s+per sec', raw_output)
        if tps_match:
            total_txn = int(tps_match.group(1))
            tps = float(tps_match.group(2))

        # Parse queries per second
        qps_match = re.search(r'queries:\s+(\d+)\s+\(([\d.]+)\s+per sec', raw_output)
        if qps_match:
            qps = float(qps_match.group(2))

        # Parse read/write queries
        read_match = re.search(r'read:\s+(\d+)', raw_output)
        if read_match:
            read_queries = int(read_match.group(1))

        write_match = re.search(r'write:\s+(\d+)', raw_output)
        if write_match:
            write_queries = int(write_match.group(1))

        # Parse latency metrics
        lat_min_match = re.search(r'min:\s+([\d.]+)', raw_output)
        if lat_min_match:
            latency_min = float(lat_min_match.group(1))

        lat_avg_match = re.search(r'avg:\s+([\d.]+)', raw_output)
        if lat_avg_match:
            latency_avg = float(lat_avg_match.group(1))

        lat_max_match = re.search(r'max:\s+([\d.]+)', raw_output)
        if lat_max_match:
            latency_max = float(lat_max_match.group(1))

        lat_p95_match = re.search(r'95th percentile:\s+([\d.]+)', raw_output)
        if lat_p95_match:
            latency_p95 = float(lat_p95_match.group(1))

        return BenchmarkResult(
            name=self.benchmark_type,
            primary_metric=tps,
            primary_metric_unit="TPS",
            duration_seconds=duration,
            latency_avg_ms=latency_avg,
            latency_p95_ms=latency_p95,
            latency_p99_ms=latency_max,  # Use max as P99 approximation
            total_transactions=total_txn,
            failed_transactions=0,
            extra_metrics={
                "threads": threads,
                "qps": qps,
                "read_queries": read_queries,
                "write_queries": write_queries,
                "tables": self.config.get('SYSBENCH_TABLES', 10),
                "table_size": self.config.get('SYSBENCH_TABLE_SIZE', 1000000),
                "test_type": self.test_type,
            },
            raw_output=raw_output,
            success=tps > 0
        )

    def warmup(self, duration: int = 30) -> bool:
        """Run warmup with point select workload"""
        print(f"  Running warmup ({duration}s)...")

        # Use point_select for warmup (lightest workload)
        cmd_parts = ["sysbench", "oltp_point_select"]
        cmd_parts.extend(self._get_connection_args())
        cmd_parts.extend([
            f"--tables={self.config.get('SYSBENCH_TABLES', 10)}",
            f"--table-size={self.config.get('SYSBENCH_TABLE_SIZE', 1000000)}",
            "--threads=8",
            f"--time={duration}",
            "run"
        ])

        cmd_str = " ".join(cmd_parts)

        try:
            result = subprocess.run(
                cmd_str, shell=True, capture_output=True, text=True, timeout=duration + 60
            )
            return result.returncode == 0
        except Exception:
            return False

    def cleanup(self) -> bool:
        """Cleanup sysbench tables"""
        cmd_parts = ["sysbench", self.test_type]
        cmd_parts.extend(self._get_connection_args())
        cmd_parts.extend([
            f"--tables={self.config.get('SYSBENCH_TABLES', 10)}",
            "cleanup"
        ])

        cmd_str = " ".join(cmd_parts)

        try:
            result = subprocess.run(
                cmd_str, shell=True, capture_output=True, text=True, timeout=300
            )
            return result.returncode == 0
        except Exception:
            return False


# Convenience classes for specific workload types
class SysbenchReadDriver(SysbenchDriver):
    """Sysbench OLTP read-only driver"""
    def __init__(self, config: Dict[str, str]):
        super().__init__(config, "oltp_read_only")


class SysbenchReadWriteDriver(SysbenchDriver):
    """Sysbench OLTP read-write driver"""
    def __init__(self, config: Dict[str, str]):
        super().__init__(config, "oltp_read_write")


class SysbenchWriteDriver(SysbenchDriver):
    """Sysbench OLTP write-only driver"""
    def __init__(self, config: Dict[str, str]):
        super().__init__(config, "oltp_write_only")


class SysbenchPointSelectDriver(SysbenchDriver):
    """Sysbench OLTP point select driver - simple PK lookups"""
    def __init__(self, config: Dict[str, str]):
        super().__init__(config, "oltp_point_select")
