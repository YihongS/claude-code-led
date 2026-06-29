# Claude Code LED Status Indicator

<p align="right"><a href="#中文说明">中文说明 ↓</a></p>

> Turn your LED strip into a real-time Claude Code status light.

![purple-working](https://img.shields.io/badge/purple-working-blueviolet) ![green-idle](https://img.shields.io/badge/green-idle-brightgreen) ![red-permission](https://img.shields.io/badge/red-permission%20needed-red)

---

## What it does

| Color | Meaning |
|---|---|
| 🟣 Purple | Claude is thinking or calling a tool |
| 🟢 Green (breathing) | Waiting for your reply |
| 🔴 Red | Permission approval needed |
| ⚫ Off | Session ended |

---

## Hardware Requirements

- LED strip with **Adalight protocol** support (e.g. Skydimo SK0127)
- The USB cable/receiver that came with your LED strip
- Windows + WSL2 (see [Mac](#mac) below for macOS)
- [Buy on AliExpress (Affiliate)] https://s.click.aliexpress.com/e/_c3wtd7Lj - Best value global shipping 

---

## Architecture

```
Claude Code hooks (WSL)
        │
        ▼
led_control.py  ──TCP 172.x.x.x:7755──▶  led_daemon.py (Windows Python)
                                                    │
                                               COM port
                                                    │
                                              USB-serial adapter
                                                    │
                                              LED strip (Adalight)
```

The daemon runs as a **Windows Python** process to access the COM port directly. The WSL client sends color commands over TCP using the WSL2 host IP.

---

## Setup

### 1. Prerequisites

```bash
# Add user to dialout group (WSL terminal)
sudo usermod -a -G dialout $USER

# Restart WSL to apply group change (PowerShell)
wsl --shutdown
```

### 2. Install dependencies

```bash
# Windows Python — needed for serial port access
pip.exe install pyserial
```

### 3. Configure

**COM port and LED count** are read from environment variables with sensible defaults.
Set them in your shell profile (`~/.bashrc` or `~/.zshrc`) if your setup differs:

```bash
export LED_SERIAL_PORT="COM5"   # your COM port
export LED_COUNT=144            # your LED count
```

**LED software integration (optional):** If you use software that controls your LED strip (e.g. Skydimo, Prismatik, Hyperion), the scripts can automatically close it before starting and reopen it when done. Set the path in `skydimo_path.txt`:

```bash
echo "C:\Program Files\YourLEDSoftware\app.exe" > ~/led_controller/skydimo_path.txt
```

Leave the file empty (or don't create it) to skip this step entirely.

### 4. Wire up Claude Code hooks

Add to `~/.claude/settings.json`:

```json
"hooks": {
  "SessionStart":     [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py green 2>/dev/null; true"}]}],
  "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "PreToolUse":       [{"matcher": ".*", "hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "PermissionRequest":[{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py red 2>/dev/null; true"}]}],
  "PostToolUse":      [{"matcher": ".*", "hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "Stop":             [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py green 2>/dev/null; true"}]}],
  "SessionEnd":       [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py off 2>/dev/null; true"}]}]
}
```

---

## Usage

```bash
# Start: closes LED software (if configured), starts daemon, turns green
bash ~/led_controller/start_claude_mode.sh

# Stop: turns off LEDs, restarts LED software (if configured)
bash ~/led_controller/stop_claude_mode.sh

# Manual color control
python3 ~/led_controller/led_control.py purple
python3 ~/led_controller/led_control.py green
python3 ~/led_controller/led_control.py red
python3 ~/led_controller/led_control.py off
```

---

## Mac

The core logic is identical on macOS — the architecture is actually simpler because there is no WSL/Windows split. Everything runs on the same machine.

### What to change

**`led_daemon.py`**
```python
# Change serial port (find yours with: ls /dev/tty.usb*)
SERIAL_PORT = os.environ.get("LED_SERIAL_PORT", "/dev/tty.usbserial-XXXX")

# Bind to localhost only — no cross-VM networking needed
TCP_HOST = "127.0.0.1"

# Use /tmp for PID file
PID_FILE = "/tmp/led_daemon.pid"
```

Also remove the IP allowlist (`_WSL_NET` check) since both processes run locally.

**`led_control.py`**
```python
# No need for get_windows_host_ip() — just use localhost
TCP_HOST = "127.0.0.1"
```

**`start_claude_mode.sh` / `stop_claude_mode.sh`**
```bash
# Replace all powershell.exe / wslpath calls with native macOS commands

# Start daemon
python3 ~/led_controller/led_daemon.py &

# Kill daemon
kill $(cat /tmp/led_daemon.pid) 2>/dev/null

# Kill/reopen LED software
pkill -x "YourLEDApp"
open "/Applications/YourLEDApp.app"
```

**Serial port permissions** on macOS:
```bash
sudo dseditgroup -o edit -a $USER -t user _dialout
```

---

## Protocol

Uses the [Adalight protocol](https://github.com/adafruit/Adalight) over serial at 115200 baud.

```
Header: 0x41 0x64 0x61 0x00 <count_hi> <count_lo>
Data:   R G B  R G B  ...  (one per LED)
Keep-alive: resent every 33ms (~30fps for smooth breathing effect)
```

---

## Security

- TCP server binds `0.0.0.0:7755` but only accepts connections from `127.0.0.1` or RFC 1918 `172.16.0.0/12` (WSL2 subnet)
- `skydimo_path.txt` is excluded from the repo via `.gitignore`
- All hook commands exit `0` even if daemon is not running — never blocks Claude Code

---

## License

MIT

---

# 中文说明

<p align="right"><a href="#claude-code-led-status-indicator">English ↑</a></p>

> 让你的 LED 灯带实时反映 Claude Code 的工作状态。

---

## 效果

| 颜色 | 含义 |
|---|---|
| 🟣 紫色 | Claude 正在处理或调用工具 |
| 🟢 绿色（呼吸灯） | 等待你的回复 |
| 🔴 红色 | 需要你批准权限 |
| ⚫ 熄灭 | 会话已结束 |

---

## 硬件要求

- 支持 Adalight 协议的 LED 灯带（如 Skydimo SK0127）
- 灯带自带的 USB 接收器
- Windows + WSL2 环境（macOS 见下方 [Mac 移植](#mac-移植) 章节）

---

## 架构

```
Claude Code hooks（WSL 侧）
        │
        ▼
led_control.py  ──TCP 172.x.x.x:7755──▶  led_daemon.py（Windows Python）
                                                    │
                                               COM 串口
                                                    │
                                              USB 接收器
                                                    │
                                            LED 灯带（Adalight）
```

Daemon 运行在 **Windows Python** 侧以直接访问 COM 口，WSL 客户端通过 TCP 发送颜色命令。

---

## 安装步骤

### 1. 前置条件

```bash
# 将用户加入 dialout 组（WSL 终端）
sudo usermod -a -G dialout $USER

# 重启 WSL 让权限生效（PowerShell）
wsl --shutdown
```

### 2. 安装依赖

```bash
# Windows Python（用于串口访问）
pip.exe install pyserial
```

### 3. 配置

**串口号和 LED 数量**通过环境变量读取，默认值为 `COM3` / `65`。
如与你的硬件不符，在 `~/.bashrc` 或 `~/.zshrc` 中设置：

```bash
export LED_SERIAL_PORT="COM5"   # 你的串口号
export LED_COUNT=144            # 你的 LED 数量
```

**LED 软件集成（可选）：** 如果你用其他软件管理灯带（如 Skydimo、Prismatik、Hyperion），脚本可以在启动时自动关闭它，结束时自动重启。在 `skydimo_path.txt` 中填入路径：

```bash
echo "C:\Program Files\YourLEDSoftware\app.exe" > ~/led_controller/skydimo_path.txt
```

留空或不创建此文件则跳过此步骤，不影响其他功能。

### 4. 配置 Claude Code hooks

将以下内容加入 `~/.claude/settings.json`：

```json
"hooks": {
  "SessionStart":     [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py green 2>/dev/null; true"}]}],
  "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "PreToolUse":       [{"matcher": ".*", "hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "PermissionRequest":[{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py red 2>/dev/null; true"}]}],
  "PostToolUse":      [{"matcher": ".*", "hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py purple 2>/dev/null; true"}]}],
  "Stop":             [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py green 2>/dev/null; true"}]}],
  "SessionEnd":       [{"hooks": [{"type": "command", "command": "python3 ~/led_controller/led_control.py off 2>/dev/null; true"}]}]
}
```

---

## 使用

```bash
# 启动：关闭 LED 软件（如已配置），启动 Daemon，亮绿灯
bash ~/led_controller/start_claude_mode.sh

# 停止：关灯，重启 LED 软件（如已配置）
bash ~/led_controller/stop_claude_mode.sh

# 手动控制颜色
python3 ~/led_controller/led_control.py purple
python3 ~/led_controller/led_control.py green
python3 ~/led_controller/led_control.py red
python3 ~/led_controller/led_control.py off
```

---

## Mac 移植

macOS 上核心逻辑完全相同，架构反而更简单——无需 WSL/Windows 分离，所有进程在同一台机器上运行。

### 需要修改的地方

**`led_daemon.py`**
```python
# 修改串口（用 ls /dev/tty.usb* 查看你的设备）
SERIAL_PORT = os.environ.get("LED_SERIAL_PORT", "/dev/tty.usbserial-XXXX")

# 仅绑定本机，无需跨 VM 通信
TCP_HOST = "127.0.0.1"

# PID 文件改用 /tmp
PID_FILE = "/tmp/led_daemon.pid"
```

同时移除 IP 白名单校验（`_WSL_NET`），因为两个进程都在本机。

**`led_control.py`**
```python
# 不需要动态获取 Windows 主机 IP，直接用本机地址
TCP_HOST = "127.0.0.1"
```

**`start_claude_mode.sh` / `stop_claude_mode.sh`**
```bash
# 将所有 powershell.exe / wslpath 调用替换为 macOS 原生命令

# 启动 Daemon
python3 ~/led_controller/led_daemon.py &

# 关闭 Daemon
kill $(cat /tmp/led_daemon.pid) 2>/dev/null

# 关闭/重启 LED 软件
pkill -x "YourLEDApp"
open "/Applications/YourLEDApp.app"
```

**macOS 串口权限：**
```bash
sudo dseditgroup -o edit -a $USER -t user _dialout
```

---

## 协议

使用 [Adalight 协议](https://github.com/adafruit/Adalight)，波特率 115200。

```
Header: 0x41 0x64 0x61 0x00 <count_hi> <count_lo>
Data:   R G B  R G B  ...（每个 LED 一组）
Keep-alive：每 33ms 重发一次（约 30fps，支持丝滑呼吸效果）
```

---

## 安全说明

- TCP 服务仅接受来自 `127.0.0.1` 或 RFC 1918 `172.16.0.0/12`（WSL2 子网）的连接
- `skydimo_path.txt` 已通过 `.gitignore` 排除在仓库之外
- 所有 hook 命令在 Daemon 未运行时也会返回 exit 0，不会阻塞 Claude Code

---

## 许可

MIT
