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
    """Calculate derived values from base config"""

    # Calculate HugePages if not explicitly set
    if 'VM_NR_HUGEPAGES' not in config and 'PG_SHARED_BUFFERS' in config:
        shared_buffers = config['PG_SHARED_BUFFERS']
        # Parse shared_buffers (e.g., "20GB" -> 20)
        match = re.match(r'^(\d+)GB$', shared_buffers)
        if match:
            gb = int(match.group(1))
            # Formula: (GB * 1024 / 2MB) * 1.07 overhead
            hugepages = int((gb * 1024 / 2) * 1.07)
            config['VM_NR_HUGEPAGES'] = str(hugepages)

    # Calculate result directory
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
