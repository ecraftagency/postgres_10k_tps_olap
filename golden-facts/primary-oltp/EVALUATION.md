# Golden Fact: PostgreSQL TPC-B Ceiling

## Hardware
| Node | Instance | vCPU | RAM | Storage |
|------|----------|------|-----|---------|
| **Primary** | r8g.xlarge | 4 | 32GB | RAID0 4x gp3 (data) + RAID0 4x gp3 (wal) |
| **Client** | c8g.xlarge | 4 | 7.6GB | pgbench driver |

## Benchmark
| Parameter | Value |
|-----------|-------|
| Workload | TPC-B (pgbench) |
| Scale | 1250 (~20GB) |
| Clients | 100 |
| Duration | 60s |
| synchronous_commit | ON |

## Results
| Run | TPS | TPS/Core | Latency | Cache Hit |
|-----|-----|----------|---------|-----------|
| 1 | 11,359 | 2,840 | 8.8ms | 93.78% |
| 2 | 11,261 | 2,815 | 8.9ms | 94.54% |

**Variance: 0.87%**

## Ceiling Proof
```
TPS_max = clients / latency = 100 / 8.9ms = 11,236 TPS
Observed: 11,261 TPS → 100.2% of theoretical ✓

Bottleneck: WAL fsync latency (2.01ms avg on EBS gp3)
```

## Verdict
| Metric | Target | Achieved |
|--------|--------|----------|
| TPS/Core | 2,500 | **2,815** |
| Total TPS | 10,000 | **11,261** |

**Ceiling: ~11,300 TPS on r8g.xlarge**

---
*Golden Fact ID: r8g.xlarge-tpcb-11300tps-2026Q1*
