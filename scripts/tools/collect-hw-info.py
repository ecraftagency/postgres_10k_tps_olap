#!/usr/bin/env python3
"""
Hardware Info Collector

Collects hardware and provisioning info from the current instance.
This info is used for ceiling detection and benchmark analysis.

Output: JSON with all hardware limits (ceiling values)

Usage:
    python3 collect-hw-info.py
    python3 collect-hw-info.py --output /tmp/hw-info.json
"""
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any


def run_cmd(cmd: str, timeout: int = 10) -> str:
    """Run command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip()
    except:
        return ""


def get_cpu_info() -> Dict[str, Any]:
    """Get CPU information"""
    info = {
        "vcpu": os.cpu_count() or 0,
        "arch": run_cmd("uname -m"),
        "model": "",
        "freq_ghz": 0,
    }
    
    # Try lscpu
    lscpu = run_cmd("lscpu")
    for line in lscpu.split("\n"):
        if "Model name:" in line:
            info["model"] = line.split(":", 1)[1].strip()
        elif "CPU max MHz:" in line:
            try:
                mhz = float(line.split(":", 1)[1].strip())
                info["freq_ghz"] = round(mhz / 1000, 2)
            except:
                pass
    
    return info


def get_memory_info() -> Dict[str, Any]:
    """Get memory information"""
    info = {"ram_gb": 0, "ram_bytes": 0}
    
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    ram_kb = int(line.split()[1])
                    info["ram_bytes"] = ram_kb * 1024
                    info["ram_gb"] = ram_kb // (1024 * 1024)
                    break
    except:
        pass
    
    return info


def get_instance_type() -> str:
    """Get EC2 instance type from metadata"""
    # Try IMDSv2
    token = run_cmd("curl -s -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' 2>/dev/null")
    if token:
        return run_cmd(f"curl -s -H 'X-aws-ec2-metadata-token: {token}' http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null")
    # Fallback to IMDSv1
    return run_cmd("curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null")


def get_disk_info() -> Dict[str, Any]:
    """Get disk/RAID information with provisioning"""
    info = {
        "data": {"mount": "/data", "device": "", "size_gb": 0, "total_iops": 0, "total_throughput_mbps": 0},
        "wal": {"mount": "/wal", "device": "", "size_gb": 0, "total_iops": 0, "total_throughput_mbps": 0},
    }
    
    # Check md devices
    for name, mount in [("data", "/data"), ("wal", "/wal")]:
        md_device = "md0" if name == "data" else "md1"
        
        # Get size from df
        df_out = run_cmd(f"df -BG {mount} 2>/dev/null | tail -1")
        if df_out:
            parts = df_out.split()
            if len(parts) >= 2:
                info[name]["device"] = parts[0]
                try:
                    info[name]["size_gb"] = int(parts[1].rstrip("G"))
                except:
                    pass
        
        # Count disks in RAID array
        mdstat = run_cmd(f"grep -A1 '{md_device}' /proc/mdstat 2>/dev/null")
        if mdstat:
            # Count nvme devices
            disk_count = len([x for x in mdstat.split() if "nvme" in x])
            
            # gp3 baseline: 3000 IOPS, 125 MB/s per disk
            # RAID0 aggregates linearly
            info[name]["disk_count"] = disk_count
            info[name]["total_iops"] = disk_count * 3000
            info[name]["total_throughput_mbps"] = disk_count * 125
    
    return info


def get_ebs_limits() -> Dict[str, Any]:
    """Get EBS bandwidth limits based on instance type"""
    # Known instance EBS limits
    ebs_limits = {
        "r8g.medium": {"bandwidth_mbps": 312, "baseline_iops": 4000},
        "r8g.large": {"bandwidth_mbps": 625, "baseline_iops": 8000},
        "r8g.xlarge": {"bandwidth_mbps": 1250, "baseline_iops": 40000},
        "r8g.2xlarge": {"bandwidth_mbps": 2500, "baseline_iops": 40000},
        "r8g.4xlarge": {"bandwidth_mbps": 5000, "baseline_iops": 40000},
        "c8g.medium": {"bandwidth_mbps": 312, "baseline_iops": 4000},
        "c8g.large": {"bandwidth_mbps": 625, "baseline_iops": 8000},
        "c8g.xlarge": {"bandwidth_mbps": 1250, "baseline_iops": 40000},
        "c8g.2xlarge": {"bandwidth_mbps": 2500, "baseline_iops": 40000},
        "c8g.4xlarge": {"bandwidth_mbps": 5000, "baseline_iops": 40000},
    }
    
    instance_type = get_instance_type()
    return ebs_limits.get(instance_type, {"bandwidth_mbps": 1250, "baseline_iops": 40000})


def get_network_limits() -> Dict[str, Any]:
    """Get network bandwidth limits"""
    # Known instance network limits (Gbps)
    network_limits = {
        "r8g.medium": 6.25,
        "r8g.large": 6.25,
        "r8g.xlarge": 12.5,
        "r8g.2xlarge": 12.5,
        "r8g.4xlarge": 12.5,
        "c8g.medium": 6.25,
        "c8g.large": 6.25,
        "c8g.xlarge": 12.5,
        "c8g.2xlarge": 12.5,
        "c8g.4xlarge": 12.5,
    }
    
    instance_type = get_instance_type()
    bandwidth_gbps = network_limits.get(instance_type, 12.5)
    
    return {
        "bandwidth_gbps": bandwidth_gbps,
        "bandwidth_mbps": int(bandwidth_gbps * 1000 / 8),  # Convert to MB/s
    }


def collect_all() -> Dict[str, Any]:
    """Collect all hardware info"""
    instance_type = get_instance_type()
    
    return {
        "instance_type": instance_type,
        "cpu": get_cpu_info(),
        "memory": get_memory_info(),
        "disk": get_disk_info(),
        "ebs": get_ebs_limits(),
        "network": get_network_limits(),
        "ceiling": {
            "cpu_cores": os.cpu_count() or 4,
            "ram_gb": get_memory_info()["ram_gb"],
            "ebs_iops": get_ebs_limits()["baseline_iops"],
            "ebs_throughput_mbps": get_ebs_limits()["bandwidth_mbps"],
            "network_mbps": get_network_limits()["bandwidth_mbps"],
            "data_iops": get_disk_info()["data"]["total_iops"],
            "data_throughput_mbps": get_disk_info()["data"]["total_throughput_mbps"],
            "wal_iops": get_disk_info()["wal"]["total_iops"],
            "wal_throughput_mbps": get_disk_info()["wal"]["total_throughput_mbps"],
        }
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Collect hardware info")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    args = parser.parse_args()
    
    info = collect_all()
    
    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w") as f:
            json.dump(info, f, indent=2)
        print(f"Saved to: {args.output}")
    elif args.json:
        print(json.dumps(info, indent=2))
    else:
        # Pretty print
        print("=" * 60)
        print("HARDWARE INFO")
        print("=" * 60)
        print(f"Instance Type: {info['instance_type']}")
        print(f"CPU: {info['cpu']['vcpu']} vCPU @ {info['cpu']['freq_ghz']} GHz ({info['cpu']['model']})")
        print(f"RAM: {info['memory']['ram_gb']} GB")
        print()
        print("=== CEILING LIMITS ===")
        c = info['ceiling']
        print(f"EBS: {c['ebs_iops']:,} IOPS, {c['ebs_throughput_mbps']} MB/s")
        print(f"Network: {c['network_mbps']} MB/s")
        print(f"DATA: {c['data_iops']:,} IOPS, {c['data_throughput_mbps']} MB/s")
        print(f"WAL:  {c['wal_iops']:,} IOPS, {c['wal_throughput_mbps']} MB/s")


if __name__ == "__main__":
    main()
