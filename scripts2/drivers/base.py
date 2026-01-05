#!/usr/bin/env python3
"""
Base Driver - Abstract interface for all benchmark drivers

All drivers must implement this interface to ensure consistent
output format across different benchmark tools.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Dict, Any, Optional, List


@dataclass
class BenchmarkResult:
    """
    Unified result format for all benchmarks.

    Every driver must return results in this format to ensure
    consistent reporting across TPC-B, TPC-C, TPC-H, and disk benchmarks.
    """
    # Required fields
    name: str                        # "TPC-B", "TPC-C", "TPC-H", "FIO"
    primary_metric: float            # Main result value
    primary_metric_unit: str         # "TPS", "NOPM", "QphH", "IOPS"
    duration_seconds: int            # Test duration

    # Latency metrics
    latency_avg_ms: float = 0.0
    latency_p50_ms: float = 0.0
    latency_p95_ms: float = 0.0
    latency_p99_ms: float = 0.0
    latency_stddev_ms: float = 0.0

    # Transaction/operation counts
    total_transactions: int = 0
    failed_transactions: int = 0

    # Benchmark-specific extra metrics
    extra_metrics: Dict[str, Any] = field(default_factory=dict)
    # TPC-B: {"scale": 1250, "clients": 100}
    # TPC-C: {"warehouses": 400, "new_orders": 12345}
    # TPC-H: {"scale_factor": 40, "query_times": {...}}
    # FIO: {"iops_read": 1000, "iops_write": 500, "bandwidth_mb": 100}

    # Raw output for debugging
    raw_output: str = ""

    # Success flag
    success: bool = True
    error_message: str = ""

    def summary(self) -> str:
        """One-line summary of results"""
        if self.success:
            return f"{self.name}: {self.primary_metric:,.0f} {self.primary_metric_unit} @ {self.latency_avg_ms:.2f}ms avg latency"
        else:
            return f"{self.name}: FAILED - {self.error_message}"


@dataclass
class CommandResult:
    """Result of a single command execution (for diagnostics)"""
    name: str
    cmd_str: str
    output: str
    success: bool = True


class BaseDriver(ABC):
    """
    Abstract base class for benchmark drivers.

    Each driver (pgbench, hammerdb, fio) must implement these methods.
    """

    def __init__(self, config: Dict[str, str]):
        """
        Initialize driver with merged config.

        Args:
            config: Merged hardware + workload configuration
        """
        self.config = config

    @property
    @abstractmethod
    def name(self) -> str:
        """Driver name (e.g., 'pgbench', 'hammerdb', 'fio')"""
        pass

    @property
    @abstractmethod
    def benchmark_type(self) -> str:
        """Benchmark type (e.g., 'TPC-B', 'TPC-C', 'TPC-H', 'DISK')"""
        pass

    @abstractmethod
    def build_schema(self) -> bool:
        """
        Build/initialize the benchmark schema.

        Returns:
            True if schema was built successfully
        """
        pass

    @abstractmethod
    def run(self, duration: int, clients: int, **kwargs) -> BenchmarkResult:
        """
        Run the benchmark.

        Args:
            duration: Test duration in seconds
            clients: Number of concurrent clients
            **kwargs: Driver-specific options

        Returns:
            BenchmarkResult with standardized metrics
        """
        pass

    @abstractmethod
    def parse_output(self, raw_output: str) -> BenchmarkResult:
        """
        Parse raw command output into BenchmarkResult.

        Args:
            raw_output: Raw stdout/stderr from benchmark command

        Returns:
            Parsed BenchmarkResult
        """
        pass

    def warmup(self, duration: int = 30) -> bool:
        """
        Run warmup phase before main benchmark.

        Default implementation - can be overridden.

        Args:
            duration: Warmup duration in seconds

        Returns:
            True if warmup completed successfully
        """
        return True

    def cleanup(self) -> bool:
        """
        Cleanup after benchmark.

        Default implementation - can be overridden.

        Returns:
            True if cleanup completed successfully
        """
        return True
