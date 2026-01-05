# =============================================================================
# Hardware Configuration: r8g.4xlarge
# =============================================================================
# Memory Optimized, Graviton4
# 16 vCPU | 128 GB RAM | 15 Gbps Network | 10 Gbps EBS
# Target: 40K TPS @ ~$580/month (on-demand) | ~$174/month (spot)
# =============================================================================

# Instance
postgres_instance_type = "r8g.4xlarge"
postgres_spot_price    = "2.50"

# Storage (RAID10: 8 disks, 4 usable)
data_disk_count      = 8
data_disk_size       = 100
data_disk_iops       = 4000
data_disk_throughput = 250

wal_disk_count      = 8
wal_disk_size       = 50
wal_disk_iops       = 4000
wal_disk_throughput = 250
