# =============================================================================
# Hardware Configuration: r8g.large
# =============================================================================
# Memory Optimized, Graviton4
# 2 vCPU | 16 GB RAM | 12.5 Gbps Network | 10 Gbps EBS
# Target: 5K TPS @ ~$73/month (on-demand) | ~$22/month (spot)
# =============================================================================

# Instance
postgres_instance_type = "r8g.large"
postgres_spot_price    = "0.25"

# Storage (RAID10: 8 disks, 4 usable)
data_disk_count      = 8
data_disk_size       = 50
data_disk_iops       = 3000
data_disk_throughput = 125

wal_disk_count      = 8
wal_disk_size       = 30
wal_disk_iops       = 3000
wal_disk_throughput = 125
