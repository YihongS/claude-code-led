#!/bin/bash
COUNTER=/tmp/claude_session_count
COUNT=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
echo $COUNT > "$COUNTER"
python3 /home/ssjzn/led_controller/led_control.py green 2>/dev/null; true
