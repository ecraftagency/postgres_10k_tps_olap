# PostgreSQL Configuration Report

**Hardware Context**: r8g.2xlarge.15.10.8disk.raid10
**Date**: 2026-01-04
**Instance**: r8g.2xlarge (8 vCPU, 64GB RAM)

> Note: MISMATCH values indicate Scenario C optimizations applied via ALTER SYSTEM
> that differ from the base config.env template.

---

[INFO] Loading configuration from /home/ubuntu/scripts/config.env

==============================================
PostgreSQL 16 Installation
==============================================

Data Directory: /data/postgresql
WAL Directory:  /wal/pg_wal
pgbench Scale:  1250

=== Step 1: Installing PostgreSQL 16 ===
[SKIP] PostgreSQL 16 already installed

=== Step 2: Checking Cluster State ===
[SKIP] Cluster already initialized at /data/postgresql

=== Step 4: Applying Configuration ===
[SKIP] postgresql.conf already up-to-date
[SKIP] pg_hba.conf already up-to-date

=== Step 5: Configuring systemd service ===
[SKIP] systemd override already configured
[SKIP] Cluster config pointer already set

=== Step 6: Starting PostgreSQL ===
[SKIP] PostgreSQL already running, no config changes

=== Step 7: Configuration Verification ===

Setting                             Expected        Actual          Status
----------------------------------- --------------- --------------- ------
CONNECTIONS & MEMORY
  max_connections                   300             300             OK
  shared_buffers                    4GB             20GB            MISMATCH
  work_mem                          32MB            54MB            MISMATCH
  maintenance_work_mem              1GB             1GB             OK
  effective_cache_size              11GB            44GB            MISMATCH
DISK I/O
  random_page_cost                  1.1             1.1             OK
  seq_page_cost                     1.0             1               OK
  effective_io_concurrency          200             200             OK
WAL
  wal_compression                   lz4             lz4             OK
  wal_buffers                       64MB            256MB           MISMATCH
  wal_writer_delay                  10ms            10ms            OK
  wal_writer_flush_after            1MB             1MB             OK
CHECKPOINT
  max_wal_size                      48GB            100GB           MISMATCH
  min_wal_size                      4GB             4GB             OK
  checkpoint_timeout                30min           1h              MISMATCH
  checkpoint_completion_target      0.9             0.9             OK
SYNC & GROUP COMMIT
  synchronous_commit                on              on              OK
  commit_delay                      50              0               MISMATCH
  commit_siblings                   10              5               MISMATCH
BACKGROUND WRITER
  bgwriter_delay                    10ms            10ms            OK
  bgwriter_lru_maxpages             1000            1000            OK
  bgwriter_lru_multiplier           10.0            4               MISMATCH
AUTOVACUUM
  autovacuum                        on              on              OK
  autovacuum_max_workers            4               4               OK
  autovacuum_naptime                1min            1min            OK
  autovacuum_vacuum_scale_factor    0.05            0.05            OK
  autovacuum_analyze_scale_factor   0.02            0.02            OK
  autovacuum_vacuum_cost_limit      10000           10000           OK
PARALLEL QUERY
  max_worker_processes              8               8               OK
  max_parallel_workers_per_gather   4               4               OK
  max_parallel_workers              8               8               OK
LOGGING
  log_min_duration_statement        1000            1s              OK
  log_temp_files                    0               0               OK
  log_checkpoints                   on              on              OK
  log_lock_waits                    on              on              OK

[ERROR] Some configurations need review
