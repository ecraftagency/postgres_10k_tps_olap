#!/usr/bin/env python3
"""
Config Loader - Merges hardware and workload configurations

Usage:
    from core.config_loader import load_config
    config = load_config("r8g.2xlarge", "tpc-b")
"""
import os
import re
from pathlib import Path
from typing import Dict, Optional

SCRIPTS_DIR = Path(__file__).parent.parent.resolve()
HARDWARE_DIR = SCRIPTS_DIR / "hardware"
WORKLOADS_DIR = SCRIPTS_DIR / "workloads"


def parse_env_file(filepath: Path) -> Dict[str, str]:
    """Parse a .env file into a dictionary"""
    config = {}
    if not filepath.exists():
        raise FileNotFoundError(f"Config file not found: {filepath}")

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue
            # Parse KEY=VALUE
            match = re.match(r'^([A-Z_][A-Z0-9_]*)=(.*)$', line)
            if match:
                key = match.group(1)
                value = match.group(2)
                # Remove quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                config[key] = value

    return config


def load_config(hardware: str, workload: str) -> Dict[str, str]:
    """
    Load and merge hardware + workload configurations

    Args:
        hardware: Hardware context name (e.g., "r8g.2xlarge")
        workload: Workload context name (e.g., "tpc-b", "tpc-c", "tpc-h")

    Returns:
        Merged configuration dictionary
    """
    # Layer 1: Hardware config (base)
    hardware_env = HARDWARE_DIR / hardware / "hardware.env"
    config = parse_env_file(hardware_env)

    # Layer 2: Workload config (override)
    workload_env = WORKLOADS_DIR / workload / "tuning.env"
    workload_config = parse_env_file(workload_env)
    config.update(workload_config)

    # Layer 3: Derived calculations
    config = calculate_derived_values(config)

    # Add context metadata
    config['HARDWARE_CONTEXT'] = hardware
    config['WORKLOAD_CONTEXT'] = workload
    config['CONTEXT_ID'] = f"{hardware}--{workload}"

    return config


def calculate_derived_values(config: Dict[str, str]) -> Dict[str, str]:
    """
    Calculate derived values from base config.

    IMPORTANT: Only calculates values that are NOT already set in tuning.env.
    Explicit values in tuning.env take precedence over calculated values.

    This allows:
    - Generic hardware configs to auto-calculate based on RAM/vCPU
    - Tuned workload configs to override with production-tested values
    """
    ram_gb = int(config.get('RAM_GB', 64))
    vcpu = int(config.get('VCPU', 8))
    max_conn = int(config.get('PG_MAX_CONNECTIONS', 300))

    # Get workload type for OLTP vs OLAP tuning
    workload = config.get('WORKLOAD_CONTEXT', 'tpc-b')
    is_olap = workload == 'tpc-h'

    # Helper: only set if not already defined
    def set_if_missing(key: str, value: str):
        if key not in config:
            config[key] = value

    # ==========================================================================
    # SHARED_BUFFERS: Scale with RAM (only if not explicitly set)
    # ==========================================================================
    if 'PG_SHARED_BUFFERS' not in config:
        if 'PG_SHARED_BUFFERS_RATIO' in config:
            ratio = float(config['PG_SHARED_BUFFERS_RATIO'])
        else:
            ratio = 0.25 if is_olap else 0.31
        shared_buffers_gb = int(ram_gb * ratio)
        config['PG_SHARED_BUFFERS'] = f"{shared_buffers_gb}GB"

    # Parse shared_buffers for derived calculations
    sb_match = re.match(r'^(\d+)GB$', config.get('PG_SHARED_BUFFERS', '20GB'))
    shared_buffers_gb = int(sb_match.group(1)) if sb_match else 20

    # ==========================================================================
    # WORK_MEM: Scale with RAM and connections (only if not explicitly set)
    # ==========================================================================
    if 'PG_WORK_MEM' not in config:
        if 'PG_WORK_MEM_RATIO' in config:
            ratio = float(config['PG_WORK_MEM_RATIO'])
            work_mem_mb = int((ram_gb * 1024 * ratio) / max_conn)
        elif is_olap:
            work_mem_mb = min(512, int((ram_gb * 1024 * 0.25) / max_conn))
        else:
            work_mem_mb = max(16, int((ram_gb * 1024 * 0.05) / max_conn))
        config['PG_WORK_MEM'] = f"{work_mem_mb}MB"

    # ==========================================================================
    # Other derived values (only if not explicitly set)
    # ==========================================================================
    set_if_missing('PG_EFFECTIVE_CACHE_SIZE', f"{int(ram_gb * 0.70)}GB")
    set_if_missing('PG_MAINTENANCE_WORK_MEM', f"{min(2048, max(256, int(ram_gb * 16)))}MB")
    set_if_missing('PG_WAL_BUFFERS', f"{min(256, max(64, shared_buffers_gb * 8))}MB")
    set_if_missing('PG_MAX_WAL_SIZE', f"{min(100, max(16, ram_gb * 2)) if not is_olap else 16}GB")

    # Parallel workers
    set_if_missing('PG_MAX_WORKER_PROCESSES', str(vcpu))
    set_if_missing('PG_MAX_PARALLEL_WORKERS', str(vcpu))
    if is_olap:
        set_if_missing('PG_MAX_PARALLEL_WORKERS_PER_GATHER', str(vcpu))
    else:
        set_if_missing('PG_MAX_PARALLEL_WORKERS_PER_GATHER', str(max(2, vcpu // 2)))

    # Background writer
    set_if_missing('PG_BGWRITER_LRU_MAXPAGES', str(500 if vcpu <= 4 else 1000))

    # Autovacuum
    set_if_missing('PG_AUTOVACUUM_MAX_WORKERS', str(max(2, min(4, vcpu // 2))))

    # ==========================================================================
    # HUGEPAGES: Calculate from shared_buffers (only if not explicitly set)
    # Formula: (GB * 1024 / 2MB) * 1.07 overhead
    # ==========================================================================
    if 'VM_NR_HUGEPAGES' not in config:
        hugepages = int((shared_buffers_gb * 1024 / 2) * 1.07)
        config['VM_NR_HUGEPAGES'] = str(hugepages)

    # ==========================================================================
    # PGBENCH_SCALE: Only auto-calculate if not set
    # ==========================================================================
    if 'PGBENCH_SCALE' not in config:
        pgbench_scale = int((shared_buffers_gb * 1024 * 0.8) / 16)
        config['PGBENCH_SCALE'] = str(pgbench_scale)

    # ==========================================================================
    # RESULT_DIR
    # ==========================================================================
    if 'HARDWARE_CONTEXT' in config and 'WORKLOAD_CONTEXT' in config:
        context_id = f"{config.get('HARDWARE_CONTEXT', 'unknown')}--{config.get('WORKLOAD_CONTEXT', 'unknown')}"
        config['RESULT_DIR'] = str(SCRIPTS_DIR / "results" / context_id)

    return config


def get_config_value(config: Dict[str, str], key: str, default: Optional[str] = None) -> str:
    """Get a config value with optional default"""
    return config.get(key, default)


def get_int(config: Dict[str, str], key: str, default: int = 0) -> int:
    """Get a config value as integer"""
    try:
        return int(config.get(key, str(default)))
    except ValueError:
        return default


def validate_config(config: Dict[str, str], required_keys: list) -> bool:
    """Validate that all required keys are present"""
    missing = [k for k in required_keys if k not in config]
    if missing:
        raise ValueError(f"Missing required config keys: {missing}")
    return True


# For shell script compatibility
def export_to_env(config: Dict[str, str]):
    """Export config to environment variables"""
    for key, value in config.items():
        os.environ[key] = value


if __name__ == "__main__":
    import sys
    import json

    if len(sys.argv) != 3:
        print("Usage: config_loader.py <hardware> <workload>")
        print("Example: config_loader.py r8g.2xlarge tpc-b")
        sys.exit(1)

    hardware = sys.argv[1]
    workload = sys.argv[2]

    try:
        config = load_config(hardware, workload)
        print(json.dumps(config, indent=2))
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
