#!/bin/bash
# 关闭 Daemon
python3 ~/led_controller/led_control.py off
sleep 0.2
python3 ~/led_controller/led_control.py stop 2>/dev/null
sleep 0.3

# 重启 Skydimo（Windows 侧）
SKYDIMO_PATH=$(cat ~/led_controller/skydimo_path.txt 2>/dev/null)
if [ -n "$SKYDIMO_PATH" ]; then
    WIN_PATH=$(wslpath -w "$SKYDIMO_PATH" 2>/dev/null || echo "$SKYDIMO_PATH")
    # 转义单引号防止 PowerShell 命令注入
    WIN_PATH_ESC="${WIN_PATH//\'/\'\'}"
    powershell.exe -Command "Start-Process -LiteralPath '$WIN_PATH_ESC'" 2>/dev/null
    echo "Skydimo 已重启。"
else
    echo "未找到 Skydimo 路径，请手动重启 Skydimo。"
fi

echo "LED 控制器已停止，屏幕同步已恢复。"
