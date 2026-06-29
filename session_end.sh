#!/bin/bash
COUNTER=/tmp/claude_session_count
COUNT=$(( $(cat "$COUNTER" 2>/dev/null || echo 1) - 1 ))
[ $COUNT -lt 0 ] && COUNT=0
echo $COUNT > "$COUNTER"
if [ "$COUNT" -eq 0 ]; then
    bash /home/ssjzn/led_controller/stop_claude_mode.sh 2>/dev/null
fi
true
