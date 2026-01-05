#!/usr/bin/tclsh
# =============================================================================
# HammerDB TPC-C Schema Builder for PostgreSQL
# =============================================================================
# Usage: hammerdbcli < build_schema.tcl
#
# Creates TPC-C schema with configurable warehouse count
# =============================================================================

puts "=== HammerDB TPC-C Schema Builder ==="

# Database connection
dbset db pg
dbset bm TPC-C

# PostgreSQL connection settings
diset connection pg_host /var/run/postgresql
diset connection pg_port 5432
diset connection pg_sslmode disable

# TPC-C settings
diset tpcc pg_superuser postgres
diset tpcc pg_superuserpass postgres
diset tpcc pg_defaultdbase postgres
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc
diset tpcc pg_dbase tpcc

# Warehouse count - scales data size
# 1 warehouse = ~100MB, 10 warehouses = ~1GB
# For r8g.large (4GB shared_buffers), use 20-40 warehouses
diset tpcc pg_count_ware 20
diset tpcc pg_num_vu 2

# Partition settings
diset tpcc pg_partition false

# Build schema
puts "Building TPC-C schema with 20 warehouses..."
buildschema

puts "=== Schema Build Complete ==="
puts "Database: tpcc"
puts "User: tpcc"
puts "Warehouses: 20"
