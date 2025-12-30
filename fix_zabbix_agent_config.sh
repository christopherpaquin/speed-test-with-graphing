#!/bin/bash
#
# Quick fix script for Zabbix agent config issues
# Run this on the monitored host if agent fails to start
#

# Don't use set -e, we'll handle errors explicitly

MAIN_CONFIG="/etc/zabbix/zabbix_agentd.conf"
BACKUP_FILE="${MAIN_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Fixing Zabbix Agent Configuration                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Create backup
if [ -f "$MAIN_CONFIG" ]; then
    echo "Creating backup: $BACKUP_FILE"
    cp "$MAIN_CONFIG" "$BACKUP_FILE"
    echo "✓ Backup created"
    echo ""
fi

# Test current config
echo "Testing current config syntax..."
# Use -p to print config (validates syntax) or just run without -t
TEST_OUTPUT=$(zabbix_agentd -p -c "$MAIN_CONFIG" 2>&1)
if [ $? -eq 0 ]; then
    echo "✓ Config syntax is OK"
    echo ""
else
    echo "✗ Config has syntax errors. Fixing..."
    echo "Error details:"
    echo "$TEST_OUTPUT" | head -5
    echo ""
    
    # Fix Include directive - remove ALL Include lines, then add one correct one
    INCLUDE_DIRECTIVE="Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf"
    
    # Simple approach: remove all Include lines (both commented and uncommented)
    # that match our patterns, then add one correct one
    sed -i '/^[[:space:]]*Include.*conf\.d/d' "$MAIN_CONFIG"
    sed -i '/^[[:space:]]*#.*Include.*conf\.d/d' "$MAIN_CONFIG"
    
    # Also remove the default Include line if it exists
    sed -i '/^[[:space:]]*Include.*zabbix_agentd\.d/d' "$MAIN_CONFIG"
    
    # Now add one correct Include directive at the end
    if ! grep -q "^${INCLUDE_DIRECTIVE}$" "$MAIN_CONFIG"; then
        echo "" >> "$MAIN_CONFIG"
        echo "# UserParameters directory (fixed by fix_zabbix_agent_config.sh)" >> "$MAIN_CONFIG"
        echo "$INCLUDE_DIRECTIVE" >> "$MAIN_CONFIG"
    fi
    
    echo "✓ Fixed Include directive"
    echo ""
fi

# Test config again
echo "Testing fixed config..."
if zabbix_agentd -p -c "$MAIN_CONFIG" > /tmp/zabbix_test.log 2>&1; then
    echo "✓ Config syntax is now OK"
    echo ""
    
    # Try to start agent
    echo "Attempting to start Zabbix agent..."
    if systemctl start zabbix-agent 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet zabbix-agent; then
            echo "✓ Zabbix agent started successfully!"
        else
            echo "✗ Agent started but may have issues. Check status:"
            echo "  systemctl status zabbix-agent"
        fi
    else
        echo "✗ Failed to start agent. Check logs:"
        echo "  journalctl -u zabbix-agent -n 50"
    fi
else
    echo "✗ Config still has errors:"
    cat /tmp/zabbix_test.log
    echo ""
    echo "Restoring from backup..."
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$MAIN_CONFIG"
        echo "✓ Restored from backup"
    fi
    exit 1
fi

echo ""
echo "If agent is running, test from Zabbix server:"
echo "  podman exec -it zabbix-server-pgsql zabbix_get -s 10.1.10.53 -k speedtest.download"

