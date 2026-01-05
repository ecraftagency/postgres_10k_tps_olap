# =============================================================================
# Hardware Configuration: c8g.2xlarge
# =============================================================================
# Compute Optimized, Graviton4
# 8 vCPU | 16 GB RAM | 15 Gbps Network | 10 Gbps EBS
# Best for: CPU-bound workloads, connection poolers, analytics
# =============================================================================

# Instance
postgres_instance_type = "c8g.2xlarge"
postgres_spot_price    = "1.00"

# Storage (smaller for compute-focused workloads)
data_disk_count      = 4
data_disk_size       = 50
data_disk_iops       = 3000
data_disk_throughput = 125

wal_disk_count      = 4
wal_disk_size       = 30
wal_disk_iops       = 3000
wal_disk_throughput = 125
