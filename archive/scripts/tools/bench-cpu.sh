#!/bin/bash
# =============================================================================
# Sysbench CPU Benchmark - Graviton4 Performance Test
# =============================================================================
# Purpose: Measure raw CPU compute power (prime number calculation)
#          Establishes baseline performance independent of I/O and Database
#
# Usage: ./bench-cpu.sh [threads] [cpu-max-prime]
#
# Default: 2 threads (matching r8g.large vCPU), prime=20000
# =============================================================================

set -e

THREADS=${1:-2}
CPU_MAX_PRIME=${2:-20000}

echo "============================================================"
echo "SYSBENCH CPU BENCHMARK"
echo "============================================================"
echo "Threads:       $THREADS"
echo "CPU Max Prime: $CPU_MAX_PRIME"
echo "============================================================"
echo

echo "[1/1] Running CPU benchmark..."
echo

sysbench cpu \
  --cpu-max-prime=$CPU_MAX_PRIME \
  --threads=$THREADS \
  run

echo
echo "============================================================"
echo "BENCHMARK COMPLETE"
echo "============================================================"
echo
echo "Key metric: events per second (higher = better)"
echo
echo "Comparison guide:"
echo "  - Single thread:  ~3,000-5,000 events/sec (Graviton4)"
echo "  - Multi-thread:   scales ~linearly with cores"
echo
