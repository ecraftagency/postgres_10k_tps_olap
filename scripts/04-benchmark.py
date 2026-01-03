#!/usr/bin/env python3
"""
Disk Benchmark Suite

Interactive TUI for PostgreSQL OLTP disk benchmarking.
All configuration from infra.toml and config.env - no command line flags needed.

Prerequisites:
    - Python 3.8+
    - Run 02-raid-setup.sh and 03-disk-tuning.sh first

First run:
    python3 -m pip install rich psutil pyyaml tomli
"""

import sys
import os
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent


def check_dependencies():
    """Check and install dependencies if needed"""
    missing = []

    try:
        import rich
    except ImportError:
        missing.append("rich")

    try:
        import psutil
    except ImportError:
        missing.append("psutil")

    try:
        import yaml
    except ImportError:
        missing.append("pyyaml")

    # Check for TOML parser
    try:
        import tomllib
    except ImportError:
        try:
            import tomli
        except ImportError:
            missing.append("tomli")

    if missing:
        print(f"[SETUP] Installing missing dependencies: {', '.join(missing)}")
        import subprocess
        subprocess.run([
            sys.executable, "-m", "pip", "install", "--quiet"
        ] + missing, check=True)
        print("[SETUP] Dependencies installed. Restarting...")
        os.execv(sys.executable, [sys.executable] + sys.argv)

    return True


def main():
    # Ensure we're in the script directory
    os.chdir(SCRIPT_DIR)
    sys.path.insert(0, str(SCRIPT_DIR))

    # Check/install dependencies
    check_dependencies()

    # Launch TUI
    from bench.cli import BenchmarkCLI

    cli = BenchmarkCLI()
    sys.exit(cli.run())


if __name__ == "__main__":
    main()
