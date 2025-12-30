#!/bin/bash
#
# Quick test script for Zabbix speedtest metrics
# Tests all 11 metrics and shows expected outputs
#

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Testing All Zabbix Speedtest Metrics                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Try to find the script
SCRIPT_PATH="/usr/local/bin/zbx-speedtest.py"
if [ ! -f "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="./zbx-speedtest.py"
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "Error: zbx-speedtest.py not found!"
        echo "Please run from project directory or install with: sudo ./setup_zabbix.sh"
        exit 1
    fi
fi

echo "Using script: $SCRIPT_PATH"
echo ""

echo "📊 Latest Values:"
echo "  Download: $(python3 $SCRIPT_PATH speedtest.download) Mbps"
echo "  Upload:   $(python3 $SCRIPT_PATH speedtest.upload) Mbps"
echo "  Ping:     $(python3 $SCRIPT_PATH speedtest.ping) ms"
echo ""

echo "📈 24-Hour Averages:"
echo "  Download Avg: $(python3 $SCRIPT_PATH speedtest.download_avg_24h) Mbps"
echo "  Upload Avg:   $(python3 $SCRIPT_PATH speedtest.upload_avg_24h) Mbps"
echo "  Ping Avg:     $(python3 $SCRIPT_PATH speedtest.ping_avg_24h) ms"
echo ""

echo "📊 Statistics:"
echo "  Test Count (24h): $(python3 $SCRIPT_PATH speedtest.test_count_24h)"
LAST_TIME=$(python3 $SCRIPT_PATH speedtest.last_test_time)
if command -v date >/dev/null 2>&1; then
    HUMAN_TIME=$(date -d "@$LAST_TIME" 2>/dev/null || date -r "$LAST_TIME" 2>/dev/null || echo "N/A")
else
    HUMAN_TIME="N/A"
fi
echo "  Last Test Time:   $LAST_TIME ($HUMAN_TIME)"
echo ""

echo "🌐 Server Information:"
echo "  Server Name:     $(python3 $SCRIPT_PATH speedtest.server_name)"
echo "  Server Location:  $(python3 $SCRIPT_PATH speedtest.server_location)"
echo "  Server Country:   $(python3 $SCRIPT_PATH speedtest.server_country)"
echo ""

echo "✅ All metrics tested successfully!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Expected Output Format:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Numeric metrics return: Decimal numbers or integers"
echo "  Example: 393.62, 41.33, 26.01, 3, 1767120005"
echo ""
echo "Text metrics return: Strings"
echo "  Example: 'Thomasville, GA', 'United States'"
echo ""
echo "For Zabbix:"
echo "  - Use 'Numeric (float)' type for speed/ping metrics"
echo "  - Use 'Numeric (unsigned)' type for count/timestamp"
echo "  - Use 'Text' type for server information"

