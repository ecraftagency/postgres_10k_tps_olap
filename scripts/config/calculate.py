#!/usr/bin/env python3
"""
calculate.py - Dynamic Config Calculator

Calculates OS and PostgreSQL config values based on hardware specs (vCPU, RAM).

Usage:
    python3 calculate.py --vcpu 4 --ram 32           # Show calculated values
    python3 calculate.py --vcpu 4 --ram 32 --apply   # Apply to system
    python3 calculate.py --auto                      # Auto-detect hardware
"""

import argparse
import os
import subprocess
import sys


def detect_hardware():
    """Auto-detect vCPU and RAM from system"""
    vcpu = os.cpu_count() or 4
    
    # Get RAM in GB
    try:
        with open('/proc/meminfo') as f:
            for line in f:
                if line.startswith('MemTotal:'):
                    kb = int(line.split()[1])
                    ram_gb = kb // (1024 * 1024)
                    break
    except:
        ram_gb = 32
    
    return vcpu, ram_gb


def calculate_config(vcpu: int, ram_gb: int) -> dict:
    """
    Calculate optimal config based on hardware.
    
    Based on ARCHITECTURE-V2.md formulas:
    - shared_buffers = RAM * 0.25
    - effective_cache_size = RAM * 0.70
    - work_mem = (RAM * 0.05 * 1024) / max_connections
    - max_connections = vcpu * 100 (capped at 300 for OLTP)
    - max_worker_processes = vcpu
    - max_parallel_workers = vcpu
    - max_parallel_workers_per_gather = vcpu // 2
    - autovacuum_max_workers = max(2, vcpu // 2)
    """
    
    # Connection and memory
    max_connections = min(vcpu * 100, 300)
    shared_buffers_gb = int(ram_gb * 0.25)
    effective_cache_size_gb = int(ram_gb * 0.70)
    work_mem_mb = max(4, int(ram_gb * 1024 * 0.05 / max_connections))
    maintenance_work_mem_mb = min(2048, int(ram_gb * 1024 * 0.05))
    
    # WAL
    wal_buffers_mb = min(64, shared_buffers_gb * 8)
    max_wal_size_gb = max(4, min(64, shared_buffers_gb * 4))
    min_wal_size_gb = max(1, max_wal_size_gb // 16)
    
    # Workers
    max_worker_processes = vcpu
    max_parallel_workers = vcpu
    max_parallel_workers_per_gather = max(1, vcpu // 2)
    autovacuum_max_workers = max(2, vcpu // 2)
    
    # Background writer
    bgwriter_lru_maxpages = max(100, vcpu * 100)
    
    # HugePages calculation (for Linux)
    # shared_buffers in 2MB pages + 7% overhead
    hugepages = int((shared_buffers_gb * 1024 / 2) * 1.07)
    
    return {
        # PostgreSQL
        'postgresql': {
            'shared_buffers': f"{shared_buffers_gb}GB",
            'effective_cache_size': f"{effective_cache_size_gb}GB",
            'work_mem': f"{work_mem_mb}MB",
            'maintenance_work_mem': f"{maintenance_work_mem_mb}MB",
            'max_connections': max_connections,
            'wal_buffers': f"{wal_buffers_mb}MB",
            'max_wal_size': f"{max_wal_size_gb}GB",
            'min_wal_size': f"{min_wal_size_gb}GB",
            'max_worker_processes': max_worker_processes,
            'max_parallel_workers': max_parallel_workers,
            'max_parallel_workers_per_gather': max_parallel_workers_per_gather,
            'autovacuum_max_workers': autovacuum_max_workers,
            'bgwriter_lru_maxpages': bgwriter_lru_maxpages,
            'synchronous_commit': 'on',
            'huge_pages': 'try',
            'wal_compression': 'lz4',
            'checkpoint_timeout': '15min',
            'checkpoint_completion_target': 0.9,
        },
        # OS (sysctl)
        'os': {
            'vm.nr_hugepages': hugepages,
            'vm.swappiness': 1,
            'vm.dirty_background_ratio': 1,
            'vm.dirty_ratio': 4,
        },
        # Metadata
        'hardware': {
            'vcpu': vcpu,
            'ram_gb': ram_gb,
        }
    }


def print_config(config: dict):
    """Print config in readable format"""
    print("\n=== Hardware ===")
    print(f"  vCPU: {config['hardware']['vcpu']}")
    print(f"  RAM:  {config['hardware']['ram_gb']} GB")
    
    print("\n=== PostgreSQL Config ===")
    for key, value in config['postgresql'].items():
        print(f"  {key}: {value}")
    
    print("\n=== OS Config ===")
    for key, value in config['os'].items():
        print(f"  {key}: {value}")


import json

def apply_config(config: dict):
    """Apply config to system and save intent for verification"""
    print("\n=== Applying Config ===")
    
    # Save intent JSON for verify-config.sh
    intent_file = os.path.join(os.path.dirname(__file__), "intent.json")
    print(f"Saving intent to {intent_file}...")
    with open(intent_file, 'w') as f:
        json.dump(config, f, indent=2)

    # Apply sysctl
    print("\nApplying sysctl...")
    for key, value in config['os'].items():
        # Handle hugepages if it fails (might happen if not enough memory)
        cmd = f"sysctl -w {key}={value}"
        print(f"  {cmd}")
        subprocess.run(cmd, shell=True, check=False)
    
    # Save to config file for PostgreSQL
    pg_config = config['postgresql']
    config_file = "/tmp/pg_calculated_config.conf"
    
    print(f"\nWriting PostgreSQL config to {config_file}...")
    with open(config_file, 'w') as f:
        f.write("# Auto-calculated based on hardware\n")
        f.write(f"# vCPU: {config['hardware']['vcpu']}, RAM: {config['hardware']['ram_gb']}GB\n\n")
        for key, value in pg_config.items():
            if isinstance(value, str):
                f.write(f"{key} = '{value}'\n")
            else:
                f.write(f"{key} = {value}\n")
    
    # Actually move it to conf.d if it exists
    conf_d = "/data/postgresql/conf.d"
    if os.path.exists(conf_d):
        target = os.path.join(conf_d, "00-calculated.conf")
        print(f"Moving config to {target}...")
        subprocess.run(f"cp {config_file} {target}", shell=True, check=True)
    
    print(f"\nTo reload PostgreSQL, run: sudo systemctl reload postgresql")


def main():
    parser = argparse.ArgumentParser(description='Calculate dynamic config based on hardware')
    parser.add_argument('--vcpu', type=int, help='Number of vCPUs')
    parser.add_argument('--ram', type=int, help='RAM in GB')
    parser.add_argument('--auto', action='store_true', help='Auto-detect hardware')
    parser.add_argument('--apply', action='store_true', help='Apply config to system')
    parser.add_argument('--json', action='store_true', help='Output as JSON')
    
    args = parser.parse_args()
    
    # Get hardware specs
    if args.auto:
        vcpu, ram_gb = detect_hardware()
        print(f"Auto-detected: vCPU={vcpu}, RAM={ram_gb}GB")
    elif args.vcpu and args.ram:
        vcpu, ram_gb = args.vcpu, args.ram
    else:
        parser.print_help()
        print("\nError: Provide --vcpu and --ram, or use --auto")
        sys.exit(1)
    
    # Calculate
    config = calculate_config(vcpu, ram_gb)
    
    # Output
    if args.json:
        import json
        print(json.dumps(config, indent=2))
    else:
        print_config(config)
    
    # Apply
    if args.apply:
        apply_config(config)


if __name__ == "__main__":
    main()
