#!/usr/bin/env python3
"""LED Client — sends color command via TCP to led_daemon"""

import socket
import sys

TCP_PORT = 7755

def get_windows_host_ip():
    import subprocess
    try:
        out = subprocess.check_output(["ip", "route", "show"], text=True)
        for line in out.splitlines():
            if "default" in line:
                return line.split()[2]
    except Exception:
        pass
    return "172.25.128.1"

def main():
    if len(sys.argv) < 2:
        print("Usage: led_control.py <color>", file=sys.stderr)
        sys.exit(1)

    color = sys.argv[1]
    host = get_windows_host_ip()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            s.connect((host, TCP_PORT))
            s.sendall(color.encode())
    except Exception:
        pass

if __name__ == "__main__":
    main()

