#!/bin/bash
# Script to check Zabbix agent status and provide info about last checks

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Zabbix Agent Status & Last Check Information            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check agent status
echo "📊 Zabbix Agent Status:"
if systemctl is-active --quiet zabbix-agent 2>/dev/null || systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
    echo "  ✓ Agent is running"
    systemctl status zabbix-agent 2>/dev/null | grep -E "Active:|since" | head -2 || \
    systemctl status zabbix-agent2 2>/dev/null | grep -E "Active:|since" | head -2
else
    echo "  ✗ Agent is NOT running"
fi
echo ""

# Check log file
echo "📝 Agent Log Information:"
LOG_FILE="/var/log/zabbix/zabbix_agentd.log"
if [ -f "$LOG_FILE" ]; then
    echo "  Log file: $LOG_FILE"
    echo "  Last modified: $(stat -c %y "$LOG_FILE" 2>/dev/null | cut -d. -f1)"
    echo "  Size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1)"
    
    # Check for recent activity
    echo ""
    echo "  Recent log entries (last 5 lines):"
    tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/    /'
else
    echo "  ✗ Log file not found"
fi
echo ""

# Check for active checks
echo "🔍 Active Checks Status:"
if grep -q "active checks" "$LOG_FILE" 2>/dev/null; then
    LAST_ACTIVE=$(grep "active checks" "$LOG_FILE" 2>/dev/null | tail -1 | grep -oE "[0-9]{8}:[0-9]{6}" | head -1)
    if [ -n "$LAST_ACTIVE" ]; then
        echo "  Last active check entry: $LAST_ACTIVE"
        # Convert to readable format (YYYYMMDD:HHMMSS)
        YEAR=${LAST_ACTIVE:0:4}
        MONTH=${LAST_ACTIVE:4:2}
        DAY=${LAST_ACTIVE:6:2}
        HOUR=${LAST_ACTIVE:9:2}
        MIN=${LAST_ACTIVE:11:2}
        SEC=${LAST_ACTIVE:13:2}
        echo "  Formatted: $YEAR-$MONTH-$DAY $HOUR:$MIN:$SEC"
    fi
else
    echo "  No active check entries found in log"
fi
echo ""

# Check for errors
echo "⚠️  Recent Errors/Warnings:"
ERRORS=$(grep -iE "(error|warning|failed|cannot)" "$LOG_FILE" 2>/dev/null | tail -3)
if [ -n "$ERRORS" ]; then
    echo "$ERRORS" | sed 's/^/    /'
else
    echo "  No recent errors found"
fi
echo ""

# Instructions
echo "📋 To see when Zabbix SERVER last collected data:"
echo ""
echo "  1. Check Zabbix Web UI:"
echo "     - Go to: Monitoring → Latest data"
echo "     - Select your host"
echo "     - Look at 'Last check' column for each item"
echo ""
echo "  2. Check Zabbix Server logs (on Zabbix server):"
echo "     Standard: tail -100 /var/log/zabbix/zabbix_server.log | grep $(hostname)"
echo "     Podman:   podman logs <zabbix-server-container> | grep $(hostname) | tail -20"
echo "     Docker:   docker logs <zabbix-server-container> | grep $(hostname) | tail -20"
echo ""
echo "  3. Test agent response:"
echo "     From Zabbix server: zabbix_get -s $(hostname) -k agent.version"
echo ""

