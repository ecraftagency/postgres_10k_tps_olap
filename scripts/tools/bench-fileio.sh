#!/bin/bash
# =============================================================================
# Sysbench File I/O Benchmark - RAID10 Performance Test
# =============================================================================
# Purpose: Measure raw disk I/O throughput and IOPS
#          Proves disk is NOT the bottleneck (if CPU-bound in DB tests)
#
# Usage: ./bench-fileio.sh [test-mode] [file-size] [threads] [duration]
#
# Test modes:
#   - seqrd   : Sequential read
#   - seqwr   : Sequential write
#   - rndrd   : Random read
#   - rndwr   : Random write
#   - rndrw   : Random read/write (default, mixed workload)
#   - seqrewr : Sequential rewrite
#
# Default: rndrw mode, 32GB files, 4 threads, 60 seconds
# =============================================================================

set -e

TEST_MODE=${1:-rndrw}
FILE_SIZE=${2:-32G}
THREADS=${3:-4}
DURATION=${4:-60}

# Run in /data (md0 - DATA volume) for accurate RAID10 testing
TEST_DIR="/data/sysbench_fileio_test"

echo "============================================================"
echo "SYSBENCH FILE I/O BENCHMARK"
echo "============================================================"
echo "Test Mode:  $TEST_MODE"
echo "File Size:  $FILE_SIZE (should be > 2x RAM to bypass cache)"
echo "Threads:    $THREADS"
echo "Duration:   ${DURATION}s"
echo "Test Dir:   $TEST_DIR"
echo "============================================================"
echo

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "[1/3] Preparing test files ($FILE_SIZE)..."
echo "      This may take a few minutes..."
echo

sysbench fileio \
  --file-total-size=$FILE_SIZE \
  --file-num=16 \
  prepare

echo
echo "[2/3] Running File I/O benchmark ($TEST_MODE)..."
echo

sysbench fileio \
  --file-total-size=$FILE_SIZE \
  --file-num=16 \
  --file-test-mode=$TEST_MODE \
  --file-block-size=16K \
  --file-io-mode=async \
  --file-extra-flags=direct \
  --time=$DURATION \
  --max-requests=0 \
  --threads=$THREADS \
  run

echo
echo "[3/3] Cleaning up test files..."

sysbench fileio \
  --file-total-size=$FILE_SIZE \
  cleanup

cd /
rmdir "$TEST_DIR" 2>/dev/null || true

echo
echo "============================================================"
echo "BENCHMARK COMPLETE"
echo "============================================================"
echo
echo "Key metrics:"
echo "  - Throughput (MB/s): Raw data transfer rate"
echo "  - IOPS: I/O operations per second"
echo "  - Latency: Response time per operation"
echo
echo "Expected for RAID10 NVMe (8 drives):"
echo "  - Random Read:  ~200,000+ IOPS"
echo "  - Random Write: ~100,000+ IOPS"
echo "  - Sequential:   ~2,000+ MB/s"
echo
echo "If these numbers are high but DB TPS is low -> CPU bottleneck confirmed"
echo
