# =============================================================================
# Hardware Configuration: r8g.2xlarge
# =============================================================================
# Memory Optimized, Graviton4
# 8 vCPU | 64 GB RAM | 15 Gbps Network | 10 Gbps EBS
# Target: 20K TPS @ ~$290/month (on-demand) | ~$87/month (spot)
# =============================================================================

# Instance
postgres_instance_type = "r8g.2xlarge"
postgres_spot_price    = "1.50"

# Storage (RAID10: 8 disks, 4 usable)
data_disk_count      = 8
data_disk_size       = 50
data_disk_iops       = 3000
data_disk_throughput = 125

wal_disk_count      = 8
wal_disk_size       = 30
wal_disk_iops       = 3000
wal_disk_throughput = 125
