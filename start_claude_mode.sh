#!/bin/bash
# 若 skydimo_path.txt 非空则关闭 LED 软件，否则跳过
LED_SOFTWARE_PATH=$(cat ~/led_controller/skydimo_path.txt 2>/dev/null)
if [ -n "$LED_SOFTWARE_PATH" ]; then
    LED_SOFTWARE_NAME=$(powershell.exe -Command "[System.IO.Path]::GetFileNameWithoutExtension('$LED_SOFTWARE_PATH')" 2>/dev/null | tr -d '\r')
    powershell.exe -Command "Stop-Process -Name '$LED_SOFTWARE_NAME' -Force -ErrorAction SilentlyContinue" 2>/dev/null
    sleep 1
fi

# 杀掉残留 Daemon（通过 PID 文件）
powershell.exe -Command "
  \$pidFile = Join-Path \$env:LOCALAPPDATA 'led_daemon.pid'
  \$pid = Get-Content \$pidFile -ErrorAction SilentlyContinue
  if (\$pid) { Stop-Process -Id \$pid -Force -ErrorAction SilentlyContinue }
" 2>/dev/null
sleep 0.3

# 启动 Windows Python Daemon（后台，无窗口）
WIN_DAEMON_PATH=$(wslpath -w ~/led_controller/led_daemon.py)
WIN_DAEMON_PATH_ESC="${WIN_DAEMON_PATH//\'/\'\'}"
powershell.exe -Command "Start-Process python -ArgumentList '$WIN_DAEMON_PATH_ESC' -WindowStyle Hidden"
sleep 0.8

# 亮绿灯（就绪状态）
python3 ~/led_controller/led_control.py green

echo "Claude Code LED 控制器已启动。结束后运行 stop_claude_mode.sh"
