# Golden AMI Images

## Hardware (Fixed)
| Role | Instance | RAM | Purpose |
|------|----------|-----|---------|
| Primary/Replica | r8g.xlarge | 32GB | PostgreSQL |
| Proxy | c8g.xlarge | 7.6GB | pgbench client |

## AMIs (ap-southeast-1)
| Role | AMI ID | Name |
|------|--------|------|
| Database | `ami-062df3ef10cbd6ef3` | postgres-c8g-golden-20260108 |
| Proxy | `ami-094f3faa5f71b7a66` | proxy-c8g-benchmark-20260108 |

## Verified Ceiling
**11,300 TPS** on r8g.xlarge (2,815 TPS/Core)
