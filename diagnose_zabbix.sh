#!/bin/bash
#
# Diagnostic script to check Zabbix integration setup
# Run this on the MONITORED HOST
#

set -e

# Source vars file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/vars" ]; then
    source "$SCRIPT_DIR/vars"
fi

# Default values if not set in vars
MONITORED_HOST_IP="${MONITORED_HOST_IP:-YOUR_MONITORED_HOST_IP}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Zabbix Speedtest Integration Diagnostic                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check 1: Script exists
echo "1. Checking if zbx-speedtest.py script exists..."
if [ -f "/usr/local/bin/zbx-speedtest.py" ]; then
    echo -e "${GREEN}✓${NC} Script exists: /usr/local/bin/zbx-speedtest.py"
    ls -l /usr/local/bin/zbx-speedtest.py
else
    echo -e "${RED}✗${NC} Script NOT found: /usr/local/bin/zbx-speedtest.py"
    echo "   Run: sudo ./setup_zabbix.sh"
fi
echo ""

# Check 2: Script is executable
if [ -f "/usr/local/bin/zbx-speedtest.py" ]; then
    echo "2. Checking script permissions..."
    if [ -x "/usr/local/bin/zbx-speedtest.py" ]; then
        echo -e "${GREEN}✓${NC} Script is executable"
    else
        echo -e "${RED}✗${NC} Script is NOT executable"
        echo "   Fix: sudo chmod +x /usr/local/bin/zbx-speedtest.py"
    fi
    echo ""
fi

# Check 3: Test script execution
if [ -f "/usr/local/bin/zbx-speedtest.py" ]; then
    echo "3. Testing script execution..."
    if /usr/local/bin/zbx-speedtest.py speedtest.download > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Script executes successfully"
        echo "   Output: $(/usr/local/bin/zbx-speedtest.py speedtest.download 2>/dev/null)"
    else
        echo -e "${RED}✗${NC} Script execution failed"
        echo "   Error: $(/usr/local/bin/zbx-speedtest.py speedtest.download 2>&1)"
    fi
    echo ""
fi

# Check 4: Test as zabbix user
if [ -f "/usr/local/bin/zbx-speedtest.py" ]; then
    echo "4. Testing script as zabbix user..."
    if sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Script works as zabbix user"
        echo "   Output: $(sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download 2>/dev/null)"
    else
        echo -e "${RED}✗${NC} Script fails as zabbix user"
        echo "   Error: $(sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download 2>&1)"
    fi
    echo ""
fi

# Check 5: Detect agent type
echo "5. Detecting Zabbix agent type..."
AGENT_TYPE="unknown"
if [ -d "/etc/zabbix/zabbix_agent2.conf.d" ]; then
    AGENT_TYPE="agent2"
    CONFIG_DIR="/etc/zabbix/zabbix_agent2.conf.d"
    CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
elif [ -d "/etc/zabbix/zabbix_agentd.conf.d" ]; then
    AGENT_TYPE="agent"
    CONFIG_DIR="/etc/zabbix/zabbix_agentd.conf.d"
    CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"
else
    echo -e "${YELLOW}⚠${NC} Neither agent config directory found"
    echo "   Checking for agent installation..."
    if systemctl list-unit-files | grep -q "zabbix-agent2"; then
        AGENT_TYPE="agent2"
        CONFIG_DIR="/etc/zabbix/zabbix_agent2.conf.d"
        CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
    elif systemctl list-unit-files | grep -q "zabbix-agent"; then
        AGENT_TYPE="agent"
        CONFIG_DIR="/etc/zabbix/zabbix_agentd.conf.d"
        CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"
    fi
fi

if [ "$AGENT_TYPE" != "unknown" ]; then
    echo -e "${GREEN}✓${NC} Detected: Zabbix $AGENT_TYPE"
    echo "   Config directory: $CONFIG_DIR"
    echo "   Main config: $CONFIG_FILE"
else
    echo -e "${RED}✗${NC} Could not detect agent type"
fi
echo ""

# Check 6: UserParameters config file
if [ "$AGENT_TYPE" != "unknown" ]; then
    echo "6. Checking UserParameters config file..."
    SPEEDTEST_CONF="$CONFIG_DIR/speedtest.conf"
    if [ -f "$SPEEDTEST_CONF" ]; then
        echo -e "${GREEN}✓${NC} Config file exists: $SPEEDTEST_CONF"
        echo "   Content:"
        cat "$SPEEDTEST_CONF" | head -5
        echo "   ..."
        USERPARAM_COUNT=$(grep -c "UserParameter=" "$SPEEDTEST_CONF" || echo "0")
        echo "   UserParameters found: $USERPARAM_COUNT (expected: 11)"
    else
        echo -e "${RED}✗${NC} Config file NOT found: $SPEEDTEST_CONF"
        echo "   Run: sudo ./setup_zabbix.sh"
    fi
    echo ""
fi

# Check 7: Main agent config includes .conf.d
if [ "$AGENT_TYPE" != "unknown" ] && [ -f "$CONFIG_FILE" ]; then
    echo "7. Checking if main config includes .conf.d directory..."
    if grep -q "Include.*\.conf\.d" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Main config includes .conf.d directory"
        grep "Include.*\.conf\.d" "$CONFIG_FILE"
    else
        echo -e "${RED}✗${NC} Main config does NOT include .conf.d directory"
        echo "   Add to $CONFIG_FILE:"
        if [ "$AGENT_TYPE" = "agent2" ]; then
            echo "   Include=/etc/zabbix/zabbix_agent2.conf.d/*.conf"
        else
            echo "   Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf"
        fi
    fi
    echo ""
fi

# Check 8: Agent service status
echo "8. Checking Zabbix agent service status..."
if [ "$AGENT_TYPE" = "agent2" ]; then
    if systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Zabbix agent2 is running"
        systemctl status zabbix-agent2 --no-pager | head -3
    else
        echo -e "${RED}✗${NC} Zabbix agent2 is NOT running"
        echo "   Start: sudo systemctl start zabbix-agent2"
    fi
elif [ "$AGENT_TYPE" = "agent" ]; then
    if systemctl is-active --quiet zabbix-agent 2>/dev/null || systemctl is-active --quiet zabbix-agentd 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Zabbix agent is running"
        systemctl status zabbix-agent --no-pager 2>/dev/null | head -3 || systemctl status zabbix-agentd --no-pager 2>/dev/null | head -3
    else
        echo -e "${RED}✗${NC} Zabbix agent is NOT running"
        echo "   Start: sudo systemctl start zabbix-agent"
    fi
else
    echo -e "${YELLOW}⚠${NC} Could not determine agent type"
fi
echo ""

# Check 9: Agent logs
echo "9. Checking recent agent logs for errors..."
if [ "$AGENT_TYPE" = "agent2" ]; then
    if systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
        echo "   Recent logs:"
        journalctl -u zabbix-agent2 -n 10 --no-pager | grep -i "error\|warn\|speedtest" || echo "   No relevant errors found"
    fi
elif [ "$AGENT_TYPE" = "agent" ]; then
    if systemctl is-active --quiet zabbix-agent 2>/dev/null || systemctl is-active --quiet zabbix-agentd 2>/dev/null; then
        echo "   Recent logs:"
        journalctl -u zabbix-agent -n 10 --no-pager 2>/dev/null | grep -i "error\|warn\|speedtest" || \
        journalctl -u zabbix-agentd -n 10 --no-pager 2>/dev/null | grep -i "error\|warn\|speedtest" || \
        echo "   No relevant errors found"
    fi
fi
echo ""

# Check 10: Network connectivity
echo "10. Checking if agent is listening on port 10050..."
if netstat -tln 2>/dev/null | grep -q ":10050 " || ss -tln 2>/dev/null | grep -q ":10050 "; then
    echo -e "${GREEN}✓${NC} Agent is listening on port 10050"
else
    echo -e "${RED}✗${NC} Agent is NOT listening on port 10050"
    echo "   Agent may not be running or configured correctly"
fi
echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Diagnostic Summary                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "To fix issues, run on this host:"
echo "  cd /opt/projects/speed-test-with-graphing"
echo "  sudo ./setup_zabbix.sh"
echo ""
echo "Then restart the agent:"
if [ "$AGENT_TYPE" = "agent2" ]; then
    echo "  sudo systemctl restart zabbix-agent2"
else
    echo "  sudo systemctl restart zabbix-agent"
fi
echo ""
echo "After fixing, test from Zabbix server:"
echo "  podman exec -it zabbix-server-pgsql zabbix_get -s ${MONITORED_HOST_IP} -k speedtest.download"
echo ""

