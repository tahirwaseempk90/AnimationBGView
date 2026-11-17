#!/usr/bin/env python3
"""Prints the UDID of an available simulator, by name.

An exact name match wins; otherwise the first device whose name starts with the text is used.
Simulator names change with each Xcode release, so scripts and CI look one up instead of
hard-coding an identifier.

usage: first-simulator.py "iPhone 17"
"""
import json
import subprocess
import sys


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    name = sys.argv[1]
    devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "devices", "available"]))["devices"]
    # Runtime identifiers sort oldest first, so the newest runtime is checked first.
    candidates = [device for runtime in sorted(devices, reverse=True) for device in devices[runtime]]
    for device in candidates:
        if device["name"] == name:
            print(device["udid"])
            return
    for device in candidates:
        if device["name"].startswith(name):
            print(device["udid"])
            return
    sys.exit(f"No available simulator named {name}")


if __name__ == "__main__":
    main()
