#!/bin/bash
COUNTER=/tmp/claude_session_count
COUNT=$(( $(cat "$COUNTER" 2>/dev/null || echo 1) - 1 ))
[ $COUNT -lt 0 ] && COUNT=0
echo $COUNT > "$COUNTER"
echo "$(date '+%H:%M:%S') SessionEnd → count=$COUNT" >> /tmp/claude_session_log.txt

if [ "$COUNT" -eq 0 ]; then
    # 防抖：等 5 秒，防止 Claude Code 重连时快速 End→Start 误触发
    sleep 5
    RECHECK=$(cat "$COUNTER" 2>/dev/null || echo 0)
    echo "$(date '+%H:%M:%S') 防抖后 recheck=$RECHECK" >> /tmp/claude_session_log.txt
    if [ "$RECHECK" -eq 0 ]; then
        echo "$(date '+%H:%M:%S') → 执行 stop 脚本" >> /tmp/claude_session_log.txt
        bash /home/ssjzn/led_controller/stop_claude_mode.sh 2>/dev/null
    else
        echo "$(date '+%H:%M:%S') → 新会话已启动，跳过 stop" >> /tmp/claude_session_log.txt
    fi
fi
true
