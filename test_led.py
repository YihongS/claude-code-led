#!/usr/bin/env python3
"""一次性测试：直接发颜色到 COM3，无 Daemon"""
import sys
import time

try:
    import serial
except ImportError:
    print("ERROR: pyserial not installed"); sys.exit(1)

LED_COUNT = 65
PORT = "COM3"
BAUD = 115200

def build_packet_v1(r, g, b):
    """计划中的格式: Ada\\0 + count(65) + pixels"""
    header = bytes([0x41, 0x64, 0x61, 0x00, 0x00, 0x41])
    return header + bytes([r, g, b] * LED_COUNT)

def build_packet_v2(r, g, b):
    """标准 Adalight: Ada + count(64=n-1) + checksum + pixels"""
    count_hi, count_lo = 0x00, 0x40
    checksum = count_hi ^ count_lo ^ 0x55
    header = bytes([0x41, 0x64, 0x61, count_hi, count_lo, checksum])
    return header + bytes([r, g, b] * LED_COUNT)

try:
    s = serial.Serial(PORT, BAUD, timeout=1)
    print(f"串口 {PORT} 打开成功")
except Exception as e:
    print(f"串口打开失败: {e}")
    sys.exit(1)

print("测试 v1 格式 (紫色)...")
s.write(build_packet_v1(150, 0, 255))
time.sleep(2)

print("测试 v2 格式 (绿色)...")
s.write(build_packet_v1(0, 255, 50))
time.sleep(2)

print("关灯...")
s.write(build_packet_v1(0, 0, 0))
s.close()
print("完成")
