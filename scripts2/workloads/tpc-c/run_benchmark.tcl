#!/usr/bin/tclsh
# =============================================================================
# HammerDB TPC-C Benchmark Runner for PostgreSQL
# =============================================================================
# Usage: hammerdbcli < run_benchmark.tcl
#
# Runs TPC-C benchmark with configurable virtual users
# =============================================================================

puts "=== HammerDB TPC-C Benchmark ==="

# Database connection
dbset db pg
dbset bm TPC-C

# PostgreSQL connection settings
diset connection pg_host /var/run/postgresql
diset connection pg_port 5432
diset connection pg_sslmode disable

# TPC-C driver settings
diset tpcc pg_driver timed
diset tpcc pg_rampup 1
diset tpcc pg_duration 2
diset tpcc pg_vacuum false
diset tpcc pg_dbase tpcc
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc

# Keying and thinking time (set to false for max throughput)
diset tpcc pg_keyandthink false

# Prepared statements (critical for performance)
diset tpcc pg_prepared true

# Virtual users - adjust based on vCPU
# For r8g.large (2 vCPU), use 8-16 VU
diset tpcc pg_allwarehouse true
diset tpcc pg_timeprofile true

# Load driver
loadscript

puts "Configuring virtual users..."
vuset vu 8
vuset logtotemp 1
vuset showoutput 1

puts "Creating virtual users..."
vucreate

puts "Starting benchmark..."
puts "Ramp-up: 1 min, Duration: 2 min"
vurun

puts "Waiting for completion..."
runtimer 200

puts "=== Benchmark Complete ==="
vudestroy
