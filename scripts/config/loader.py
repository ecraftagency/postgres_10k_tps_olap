#!/usr/bin/env python3
"""
Config Loader - Hierarchical Config Merge

Loads configuration from hierarchical structure:
  common/network.env  -> ALL nodes
  common/kernel.env   -> ALL nodes
  db/os.env           -> DB nodes
  db/disk.env         -> DB nodes
  db/{role}.env       -> Role-specific (primary, sync-replica, async-replica)
  proxy/os.env        -> Proxy nodes
  benchmark/client.env -> Benchmark client

Usage:
    python3 loader.py --role primary
    python3 loader.py --role sync-replica
    python3 loader.py --role proxy
    python3 loader.py --role primary --output /tmp/config.env
"""
import argparse
import os
import sys
from pathlib import Path
from typing import Dict, Optional

CONFIG_DIR = Path(__file__).parent.resolve()


def load_env(path: Path) -> Dict[str, str]:
    """Load .env file into dict"""
    config = {}
    if not path.exists():
        return config

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                config[key] = value
    return config


def calculate_dynamic(config: Dict[str, str]) -> Dict[str, str]:
    """Calculate dynamic values from hardware specs"""
    vcpu = int(config.get("VCPU", 4))
    ram_gb = int(config.get("RAM_GB", 32))
    max_conn = int(config.get("PG_MAX_CONNECTIONS", 300))

    # Memory ratios (from workload config)
    sb_ratio = float(config.get("PG_SHARED_BUFFERS_RATIO", 0.25))
    ec_ratio = float(config.get("PG_EFFECTIVE_CACHE_RATIO", 0.70))
    wm_ratio = float(config.get("PG_WORK_MEM_RATIO", 0.05))

    # Calculate PostgreSQL memory settings
    shared_buffers_gb = int(ram_gb * sb_ratio)
    effective_cache_gb = int(ram_gb * ec_ratio)
    work_mem_mb = max(4, int((ram_gb * wm_ratio * 1024) / max_conn))
    maintenance_work_mem_mb = min(2048, ram_gb * 64)
    wal_buffers_mb = min(2048, shared_buffers_gb * 8)
    max_wal_size_gb = max(4, shared_buffers_gb * 4)

    # Calculate hugepages: (shared_buffers / 2MB) * 1.07
    nr_hugepages = int((shared_buffers_gb * 1024 / 2) * 1.07)

    # Calculate worker limits
    max_parallel_workers = vcpu
    max_worker_processes = vcpu * 2
    autovacuum_workers = max(2, vcpu // 2)
    bgwriter_maxpages = 100 + (vcpu * 100)

    # Add calculated values
    calculated = {
        # PostgreSQL Memory
        "PG_SHARED_BUFFERS": f"{shared_buffers_gb}GB",
        "PG_EFFECTIVE_CACHE_SIZE": f"{effective_cache_gb}GB",
        "PG_WORK_MEM": f"{work_mem_mb}MB",
        "PG_MAINTENANCE_WORK_MEM": f"{maintenance_work_mem_mb}MB",
        "PG_WAL_BUFFERS": f"{wal_buffers_mb}MB",
        "PG_MAX_WAL_SIZE": f"{max_wal_size_gb}GB",

        # PostgreSQL Workers
        "PG_MAX_WORKER_PROCESSES": str(max_worker_processes),
        "PG_MAX_PARALLEL_WORKERS": str(max_parallel_workers),
        "PG_MAX_PARALLEL_WORKERS_PER_GATHER": str(max(1, vcpu // 2)),
        "PG_AUTOVACUUM_MAX_WORKERS": str(autovacuum_workers),
        "PG_BGWRITER_LRU_MAXPAGES": str(bgwriter_maxpages),

        # HugePages
        "VM_NR_HUGEPAGES": str(nr_hugepages),

        # Benchmark scaling
        "PGBENCH_SCALE": str(int(shared_buffers_gb * 160)),  # ~80% of shared_buffers
        "PGBENCH_CLIENTS": str(vcpu * 12),
        "PGBENCH_THREADS": str(vcpu),
    }

    return calculated


def load_config(
    role: str = "primary",
    auto_detect: bool = False,
) -> Dict[str, str]:
    """
    Load merged config from hierarchical structure.

    Priority (low to high):
    1. common/network.env (all nodes)
    2. common/kernel.env (all nodes)
    3. db/os.env or proxy/os.env (node type specific)
    4. db/disk.env (db nodes only)
    5. db/{role}.env or benchmark/client.env (role specific)
    6. Dynamic calculation
    """
    config = {}

    # Determine node type from role
    is_db_role = role in ["primary", "sync-replica", "async-replica"]

    # Layer 1: Common configs (all nodes)
    config.update(load_env(CONFIG_DIR / "common" / "network.env"))
    config.update(load_env(CONFIG_DIR / "common" / "kernel.env"))

    # Layer 2: Node-type specific OS config
    if is_db_role:
        config.update(load_env(CONFIG_DIR / "db" / "os.env"))
        config.update(load_env(CONFIG_DIR / "db" / "disk.env"))
    else:
        config.update(load_env(CONFIG_DIR / "proxy" / "os.env"))

    # Layer 3: Role-specific config
    if auto_detect:
        # Auto-detect hardware from system
        vcpu = os.cpu_count() or 4
        try:
            with open("/proc/meminfo") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        ram_kb = int(line.split()[1])
                        ram_gb = ram_kb // (1024 * 1024)
                        break
        except:
            ram_gb = 32

        config["VCPU"] = str(vcpu)
        config["RAM_GB"] = str(ram_gb)
        config["INSTANCE_TYPE"] = "auto-detected"
    else:
        if is_db_role:
            role_file = CONFIG_DIR / "db" / f"{role}.env"
        elif role == "proxy":
            # Proxy doesn't have a specific .env, uses proxy/os.env
            role_file = None
        else:
            role_file = CONFIG_DIR / "benchmark" / "client.env"

        if role_file and role_file.exists():
            config.update(load_env(role_file))
        elif role_file:
            print(f"Warning: Role config not found: {role_file}", file=sys.stderr)

    # Layer 4: Dynamic calculation (only for DB roles)
    if is_db_role:
        config.update(calculate_dynamic(config))

    return config


def export_env(config: Dict[str, str], output_path: Optional[Path] = None) -> str:
    """Export config as shell-sourceable format"""
    lines = [
        "# Generated config - DO NOT EDIT",
        f"# Role: {config.get('PG_CLUSTER_NAME', config.get('INSTANCE_TYPE', 'unknown'))}",
        "",
    ]

    # Group by category
    categories = {
        "INSTANCE": ["INSTANCE_TYPE", "VCPU", "RAM_GB"],
        "OS_MEMORY": [k for k in config if k.startswith("VM_")],
        "OS_FILE": [k for k in config if k.startswith("FS_") or k.startswith("ULIMIT_")],
        "OS_NET": [k for k in config if k.startswith("NET_")],
        "KERNEL": [k for k in config if k.startswith("KERNEL_")],
        "DISK": [k for k in config if k.startswith("DATA_") or k.startswith("WAL_") or k.startswith("MD_")],
        "POSTGRES": [k for k in config if k.startswith("PG_")],
        "BENCHMARK": [k for k in config if k.startswith("PGBENCH_") or k.startswith("FIO_") or k.startswith("SYSBENCH_")],
    }

    for cat_name, keys in categories.items():
        valid_keys = [k for k in keys if k in config]
        if valid_keys:
            lines.append(f"# === {cat_name} ===")
            for key in sorted(valid_keys):
                value = config[key]
                if " " in value:
                    lines.append(f'{key}="{value}"')
                else:
                    lines.append(f'{key}={value}')
            lines.append("")

    # Add remaining keys
    covered = set()
    for keys in categories.values():
        covered.update(keys)

    remaining = sorted(k for k in config if k not in covered)
    if remaining:
        lines.append("# === OTHER ===")
        for key in remaining:
            value = config[key]
            if " " in value:
                lines.append(f'{key}="{value}"')
            else:
                lines.append(f'{key}={value}')

    result = "\n".join(lines)

    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(result)

    return result


def main():
    parser = argparse.ArgumentParser(description="Config Loader (Hierarchical)")
    parser.add_argument("--role", "-r", default="primary",
                        help="Role (primary, sync-replica, async-replica, proxy, benchmark)")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--auto-detect", "-a", action="store_true", help="Auto-detect hardware")
    parser.add_argument("--list", "-l", action="store_true", help="List available configs")

    args = parser.parse_args()

    if args.list:
        print("Available role configs:")
        print("\nDB roles (scripts/config/db/):")
        for f in sorted((CONFIG_DIR / "db").glob("*.env")):
            if f.stem not in ["os", "disk"]:
                print(f"  - {f.stem}")
        print("\nProxy roles (scripts/config/proxy/):")
        print("  - proxy (uses proxy/os.env)")
        print("\nBenchmark (scripts/config/benchmark/):")
        for f in sorted((CONFIG_DIR / "benchmark").glob("*.env")):
            print(f"  - {f.stem}")
        return

    config = load_config(
        role=args.role,
        auto_detect=args.auto_detect,
    )

    output_path = Path(args.output) if args.output else None
    result = export_env(config, output_path)

    if output_path:
        print(f"Config written to: {output_path}")
        print(f"Source it with: source {output_path}")
    else:
        print(result)


if __name__ == "__main__":
    main()
