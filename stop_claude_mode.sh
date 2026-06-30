#!/bin/bash
# 关闭 Daemon
python3 ~/led_controller/led_control.py off
sleep 0.2
python3 ~/led_controller/led_control.py stop 2>/dev/null

# 等待 Daemon 进程真正退出（最多 3 秒）
for i in 1 2 3; do
    sleep 1
    STILL_RUNNING=$(powershell.exe -Command "netstat -ano | findstr ':7755'" 2>/dev/null | tr -d '\r')
    if [ -z "$STILL_RUNNING" ]; then
        break
    fi
done
# 兜底：若仍未退出则强制杀掉
if [ -n "$STILL_RUNNING" ]; then
    powershell.exe -Command "Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue" 2>/dev/null
    sleep 0.5
fi

# 重启 Skydimo（Windows 侧）
SKYDIMO_PATH=$(cat ~/led_controller/skydimo_path.txt 2>/dev/null)
if [ -n "$SKYDIMO_PATH" ]; then
    WIN_PATH=$(wslpath -w "$SKYDIMO_PATH" 2>/dev/null || echo "$SKYDIMO_PATH")
    WIN_PATH_ESC="${WIN_PATH//\'/\'\'}"
    powershell.exe -Command "Start-Process -LiteralPath '$WIN_PATH_ESC'" 2>/dev/null
    echo "Skydimo 已重启。"
else
    echo "未找到 Skydimo 路径，请手动重启 Skydimo。"
fi

echo "LED 控制器已停止，屏幕同步已恢复。"
