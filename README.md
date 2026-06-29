# Claude Code LED Status Indicator
# Claude Code LED 状态指示灯

> Turn your LED strip into a real-time Claude Code status light.
> 让你的 LED 灯带实时反映 Claude Code 的工作状态。

![purple-working](https://img.shields.io/badge/purple-working-blueviolet) ![green-idle](https://img.shields.io/badge/green-idle-brightgreen) ![red-permission](https://img.shields.io/badge/red-permission%20needed-red)

---

## What it does / 效果

| Color / 颜色 | Meaning / 含义 |
|---|---|
| 🟣 Purple / 紫 | Claude is thinking or calling a tool / Claude 正在处理或调用工具 |
| 🟢 Green (breathing) / 绿（呼吸灯） | Waiting for your reply / 等待你的回复 |
| 🔴 Red / 红 | Permission approval needed / 需要你批准权限 |
| ⚫ Off / 灭 | Session ended / 会话已结束 |

---

## Hardware Requirements / 硬件要求

- LED strip with **Adalight protocol** support (e.g. Skydimo SK0127)
- USB-to-serial adapter with **CH340** chip
- Windows + WSL2

支持 Adalight 协议的 LED 灯带（如 Skydimo SK0127），CH340 USB 转串口适配器，Windows + WSL2 环境。

---

## Architecture / 架构

```
Claude Code hooks (WSL)
        │
        ▼
led_control.py  ──TCP 172.x.x.x:7755──▶  led_daemon.py (Windows Python)
                                                    │
                                                   COM3
                                                    │
                                              CH340 adapter
                                                    │
                                              LED strip (65 LEDs)
```

The daemon runs as a **Windows Python** process to access the COM port directly. The WSL client sends color commands over TCP using the WSL2 host IP.

Daemon 运行在 **Windows Python** 侧以直接访问 COM 口，WSL 客户端通过 TCP 发送颜色命令。

---

## Setup / 安装

### 1. Prerequisites / 前置条件

```bash
# Add user to dialout group (WSL terminal)
# 将用户加入 dialout 组（WSL 终端）
sudo usermod -a -G dialout $USER

# Restart WSL to apply group change
# 重启 WSL 让权限生效（PowerShell）
wsl --shutdown
```

### 2. Install dependencies / 安装依赖

```bash
# Windows Python (for serial port access)
# Windows Python（用于串口访问）
pip.exe install pyserial
```

### 3. Configure / 配置

Edit `led_daemon.py` to match your setup:

修改 `led_daemon.py` 以匹配你的硬件：

```python
SERIAL_PORT = "COM3"   # Your COM port / 你的串口号
LED_COUNT = 65         # Number of LEDs / LED 数量
```

Save your LED software path (optional, for auto-restart):

保存 LED 软件路径（可选，用于自动重启）：

```bash
echo "C:\Program Files\YourLEDSoftware\app.exe" > ~/led_controller/skydimo_path.txt
```

### 4. Wire up Claude Code hooks / 配置 Claude Code hooks

Add to `~/.claude/settings.json`:

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

## Usage / 使用

```bash
# Start (closes LED software, starts daemon, turns green)
# 启动（关闭 LED 软件，启动 Daemon，亮绿灯）
bash ~/led_controller/start_claude_mode.sh

# Stop (turns off, restarts LED software)
# 停止（关灯，重启 LED 软件）
bash ~/led_controller/stop_claude_mode.sh

# Manual color control / 手动控制颜色
python3 ~/led_controller/led_control.py purple
python3 ~/led_controller/led_control.py green
python3 ~/led_controller/led_control.py red
python3 ~/led_controller/led_control.py off
```

---

## Protocol / 协议

Uses the [Adalight protocol](https://github.com/adafruit/Adalight) over serial at 115200 baud.

使用 [Adalight 协议](https://github.com/adafruit/Adalight)，波特率 115200。

```
Header: 0x41 0x64 0x61 0x00 <count_hi> <count_lo>
Data:   R G B  R G B  ...  (one per LED)
Keep-alive: resent every 33ms (~30fps for smooth breathing effect)
```

---

## Security / 安全

- TCP server binds `0.0.0.0:7755` but only accepts connections from `127.0.0.1` or RFC 1918 `172.16.0.0/12` (WSL2 subnet)
- `skydimo_path.txt` is excluded from the repo via `.gitignore`
- All hook commands exit `0` even if daemon is not running — never blocks Claude Code

- TCP 服务仅接受来自 `127.0.0.1` 或 RFC 1918 `172.16.0.0/12`（WSL2 子网）的连接
- `skydimo_path.txt` 已通过 `.gitignore` 排除在仓库之外
- 所有 hook 命令在 Daemon 未运行时也会返回 exit 0，不会阻塞 Claude Code

---

## License / 许可

MIT
