#!/bin/bash
COUNTER=/tmp/claude_session_count
COUNT=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
echo $COUNT > "$COUNTER"
echo "$(date '+%H:%M:%S') SessionStart → count=$COUNT" >> /tmp/claude_session_log.txt

# 检查 Daemon 是否在跑，不在则自动启动
IS_RUNNING=$(powershell.exe -Command "netstat -ano | findstr ':7755'" 2>/dev/null)
if [ -z "$IS_RUNNING" ]; then
    echo "$(date '+%H:%M:%S') Daemon 未运行，自动启动" >> /tmp/claude_session_log.txt
    WIN_PATH=$(wslpath -w ~/led_controller/led_daemon.py)
    WIN_PATH_ESC="${WIN_PATH//\'/\'\'}"
    powershell.exe -Command "Start-Process python -ArgumentList '$WIN_PATH_ESC' -WindowStyle Hidden" 2>/dev/null
    sleep 0.8
fi

python3 /home/ssjzn/led_controller/led_control.py green 2>/dev/null; true
