#!/bin/bash
COUNTER=/tmp/claude_session_count
COUNT=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
echo $COUNT > "$COUNTER"
echo "$(date '+%H:%M:%S') SessionStart → count=$COUNT" >> /tmp/claude_session_log.txt

# 检查 Daemon 是否在跑
IS_RUNNING=$(powershell.exe -Command "netstat -ano | findstr ':7755'" 2>/dev/null | tr -d '\r')
echo "$(date '+%H:%M:%S') IS_RUNNING='$IS_RUNNING'" >> /tmp/claude_session_log.txt

if [ -z "$IS_RUNNING" ]; then
    echo "$(date '+%H:%M:%S') Daemon 未运行，关 Skydimo 后启动 Daemon" >> /tmp/claude_session_log.txt
    # 先关 Skydimo，避免争抢 COM3
    LED_SOFTWARE_PATH=$(cat ~/led_controller/skydimo_path.txt 2>/dev/null)
    if [ -n "$LED_SOFTWARE_PATH" ]; then
        LED_SOFTWARE_NAME=$(powershell.exe -Command "[System.IO.Path]::GetFileNameWithoutExtension('$LED_SOFTWARE_PATH')" 2>/dev/null | tr -d '\r')
        powershell.exe -Command "Stop-Process -Name '$LED_SOFTWARE_NAME' -Force -ErrorAction SilentlyContinue" 2>/dev/null
        sleep 0.5
    fi
    # 启动 Daemon，等待就绪
    WIN_PATH=$(wslpath -w ~/led_controller/led_daemon.py)
    WIN_PATH_ESC="${WIN_PATH//\'/\'\'}"
    powershell.exe -Command "Start-Process python -ArgumentList '$WIN_PATH_ESC' -WindowStyle Hidden" 2>/dev/null
    for i in 1 2 3 4 5; do
        sleep 1
        READY=$(powershell.exe -Command "netstat -ano | findstr ':7755'" 2>/dev/null | tr -d '\r')
        if [ -n "$READY" ]; then
            echo "$(date '+%H:%M:%S') Daemon 就绪（等了 ${i}s）" >> /tmp/claude_session_log.txt
            break
        fi
    done
else
    echo "$(date '+%H:%M:%S') Daemon 已在运行" >> /tmp/claude_session_log.txt
    # Daemon 在跑但 Skydimo 可能也在跑（争 COM3），确保 Skydimo 关闭
    IS_SKYDIMO=$(powershell.exe -Command "Get-Process Skydimo -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id" 2>/dev/null | tr -d '\r')
    if [ -n "$IS_SKYDIMO" ]; then
        echo "$(date '+%H:%M:%S') Skydimo 仍在运行，强制关闭" >> /tmp/claude_session_log.txt
        powershell.exe -Command "Stop-Process -Name Skydimo -Force -ErrorAction SilentlyContinue" 2>/dev/null
        sleep 0.5
    fi
fi

python3 /home/ssjzn/led_controller/led_control.py green 2>/dev/null
echo "$(date '+%H:%M:%S') 绿灯命令已发" >> /tmp/claude_session_log.txt
true
