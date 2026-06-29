#!/usr/bin/env python3
"""LED Daemon — Windows Python, COM3, TCP 0.0.0.0:7755 (WSL/localhost only)"""

import ipaddress
import math
import os
import socket
import threading
import time
import sys

_WSL_NET = ipaddress.ip_network("172.16.0.0/12")

SERIAL_PORT = "COM3"
BAUD_RATE = 115200
LED_COUNT = 65
KEEP_ALIVE_INTERVAL = 0.033
TCP_HOST = "0.0.0.0"
TCP_PORT = 7755
PID_FILE = os.path.join(os.environ.get("LOCALAPPDATA", r"C:\Windows\Temp"), "led_daemon.pid")

COLORS = {
    "purple": (150, 0, 255),
    "green":  (0, 255, 40),
    "red":    (255, 0, 0),
    "off":    (0, 0, 0),
}

def build_packet(r, g, b):
    header = bytes([0x41, 0x64, 0x61, 0x00,
                    (LED_COUNT >> 8) & 0xFF, LED_COUNT & 0xFF])
    pixels = bytes([r, g, b] * LED_COUNT)
    return header + pixels

class LEDDaemon:
    def __init__(self):
        self._lock = threading.Lock()
        self._current_color = (0, 0, 0)
        self._breathing = False
        self._running = True
        self._serial = None

    def _open_serial(self):
        try:
            import serial
            self._serial = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        except Exception as e:
            print(f"串口打开失败: {e}", file=sys.stderr)

    def _send_color(self, r, g, b):
        if self._serial is None:
            return
        try:
            with self._lock:
                self._serial.write(build_packet(r, g, b))
        except Exception:
            pass

    def set_color(self, name):
        self._breathing = (name == "green")
        self._current_color = COLORS.get(name, (0, 0, 0))
        if not self._breathing:
            self._send_color(*self._current_color)

    def _keep_alive(self):
        phase = 0.0
        while self._running:
            if self._breathing:
                # 亮度在 30%~100% 之间呼吸，周期约 3 秒
                brightness = 0.65 + 0.35 * math.sin(phase)
                r, g, b = self._current_color
                self._send_color(int(r * brightness), int(g * brightness), int(b * brightness))
                phase += 2 * math.pi * KEEP_ALIVE_INTERVAL / 3.0
            else:
                self._send_color(*self._current_color)
            time.sleep(KEEP_ALIVE_INTERVAL)

    def _handle_client(self, conn, addr):
        try:
            try:
                allowed = addr[0] == "127.0.0.1" or ipaddress.ip_address(addr[0]) in _WSL_NET
            except ValueError:
                allowed = False
            if not allowed:
                return
            data = conn.recv(64).decode("utf-8", errors="ignore").strip()
            if data == "stop":
                self._running = False
                self.set_color("off")
            else:
                self.set_color(data)
        except Exception:
            pass
        finally:
            conn.close()

    def run(self):
        self._open_serial()

        try:
            with open(PID_FILE, "w") as f:
                f.write(str(os.getpid()))
        except Exception:
            pass

        t = threading.Thread(target=self._keep_alive, daemon=True)
        t.start()

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
            srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            srv.bind((TCP_HOST, TCP_PORT))
            srv.listen(5)
            srv.settimeout(0.5)
            while self._running:
                try:
                    conn, addr = srv.accept()
                    threading.Thread(target=self._handle_client, args=(conn, addr), daemon=True).start()
                except socket.timeout:
                    pass
                except Exception:
                    break

        try:
            os.unlink(PID_FILE)
        except Exception:
            pass
        if self._serial:
            self._serial.close()

if __name__ == "__main__":
    LEDDaemon().run()
