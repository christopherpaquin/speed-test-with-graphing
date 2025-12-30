# Testing Zabbix Integration - CLI Guide

This guide shows you how to test the Zabbix speedtest integration from the command line and what outputs to expect.

## Quick Start

### 1. Test the Script Directly (Before Setup)

From the project directory:

```bash
# Test individual metrics
python3 zbx-speedtest.py speedtest.download
python3 zbx-speedtest.py speedtest.upload
python3 zbx-speedtest.py speedtest.ping
```

**Expected Output:**
```
393.62    # Download speed in Mbps
41.33     # Upload speed in Mbps
26.01     # Ping in milliseconds
```

### 2. Test All Metrics

```bash
# Test all 11 metrics at once
for metric in speedtest.download speedtest.upload speedtest.ping \
              speedtest.download_avg_24h speedtest.upload_avg_24h speedtest.ping_avg_24h \
              speedtest.test_count_24h speedtest.last_test_time \
              speedtest.server_name speedtest.server_location speedtest.server_country; do
    echo -n "$metric: "
    python3 zbx-speedtest.py "$metric"
done
```

### 3. Test After Zabbix Setup

After running `sudo ./setup_zabbix.sh`, test from the installed location:

```bash
# Test from installed location
/usr/local/bin/zbx-speedtest.py speedtest.download
/usr/local/bin/zbx-speedtest.py speedtest.upload
/usr/local/bin/zbx-speedtest.py speedtest.ping
```

### 4. Test from Zabbix Server

From your Zabbix server, use `zabbix_get`:

```bash
# Replace <hostname> with your monitored host
zabbix_get -s <hostname> -k speedtest.download
zabbix_get -s <hostname> -k speedtest.upload
zabbix_get -s <hostname> -k speedtest.ping
zabbix_get -s <hostname> -k speedtest.download_avg_24h
```

**Expected Output:**
```
393.62
41.33
26.01
446.83
```

## Expected Outputs by Metric Type

### Numeric Metrics (for Zabbix Numeric items)

These return decimal numbers or integers:

| Metric | Example Output | Format | Unit |
|--------|---------------|--------|------|
| `speedtest.download` | `393.62` | Decimal | Mbps |
| `speedtest.upload` | `41.33` | Decimal | Mbps |
| `speedtest.ping` | `26.01` | Decimal | ms |
| `speedtest.download_avg_24h` | `446.83` | Decimal | Mbps |
| `speedtest.upload_avg_24h` | `46.50` | Decimal | Mbps |
| `speedtest.ping_avg_24h` | `27.06` | Decimal | ms |
| `speedtest.test_count_24h` | `3` | Integer | count |
| `speedtest.last_test_time` | `1767120005` | Integer | Unix timestamp |

### Text Metrics (for Zabbix Text items)

These return strings:

| Metric | Example Output | Format |
|--------|---------------|--------|
| `speedtest.server_name` | `"Thomasville, GA"` | String |
| `speedtest.server_location` | `"Unknown"` | String |
| `speedtest.server_location` | `"United States"` | String |

## Verification Commands

### Check Zabbix Configuration

```bash
# Check if UserParameters config exists
cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf

# Expected: Should show 11 UserParameter lines
```

### Check Script Installation

```bash
# Check if script is installed
ls -l /usr/local/bin/zbx-speedtest.py

# Expected: Should show executable Python script
# -rwxr-xr-x 1 root root 5.2K ... /usr/local/bin/zbx-speedtest.py
```

### Check Zabbix Agent Status

```bash
# Check agent status
sudo systemctl status zabbix-agent

# Check agent logs for errors
sudo journalctl -u zabbix-agent -n 50 | grep -i speedtest
```

### Test as Zabbix User

```bash
# Test if Zabbix agent can execute the script (important!)
sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download

# Expected: Should return a number (e.g., 393.62)
# If this fails, check permissions
```

## Complete Test Script

Save this as `test_zabbix_metrics.sh`:

```bash
#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Testing All Zabbix Speedtest Metrics                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_PATH="/usr/local/bin/zbx-speedtest.py"
if [ ! -f "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="./zbx-speedtest.py"
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
echo "  Last Test Time:   $LAST_TIME ($(date -d @$LAST_TIME 2>/dev/null || date -r $LAST_TIME 2>/dev/null || echo 'N/A'))"
echo ""

echo "🌐 Server Information:"
echo "  Server Name:     $(python3 $SCRIPT_PATH speedtest.server_name)"
echo "  Server Location:  $(python3 $SCRIPT_PATH speedtest.server_location)"
echo "  Server Country:   $(python3 $SCRIPT_PATH speedtest.server_country)"
echo ""

echo "✅ All metrics tested successfully!"
```

Make it executable and run:
```bash
chmod +x test_zabbix_metrics.sh
./test_zabbix_metrics.sh
```

## Troubleshooting

### Script Returns 0 or Empty

**Problem:** Metric returns `0` or empty string

**Solutions:**
1. Check if speedtest data exists:
   ```bash
   cat speedtest_results.json
   ```

2. Verify script can read the file:
   ```bash
   python3 zbx-speedtest.py speedtest.download
   ```

3. Check file permissions:
   ```bash
   ls -l speedtest_results.json
   ```

### Zabbix Agent Can't Collect Metrics

**Problem:** Zabbix shows "Not supported" or "No data"

**Solutions:**
1. Verify UserParameters config:
   ```bash
   cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf
   ```

2. Test script as zabbix user:
   ```bash
   sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
   ```

3. Check Zabbix agent logs:
   ```bash
   sudo journalctl -u zabbix-agent -n 100 | grep speedtest
   ```

4. Restart Zabbix agent:
   ```bash
   sudo systemctl restart zabbix-agent
   ```

### Invalid Metric Error

**Problem:** Script returns "Unknown metric: X"

**Solution:** Use one of the 11 valid metrics:
- `speedtest.download`
- `speedtest.upload`
- `speedtest.ping`
- `speedtest.download_avg_24h`
- `speedtest.upload_avg_24h`
- `speedtest.ping_avg_24h`
- `speedtest.test_count_24h`
- `speedtest.last_test_time`
- `speedtest.server_name`
- `speedtest.server_location`
- `speedtest.server_country`

## Example: Full Test Session

```bash
# 1. Test from project directory
cd /opt/projects/speed-test-with-graphing
python3 zbx-speedtest.py speedtest.download
# Output: 393.62

# 2. Run setup
sudo ./setup_zabbix.sh

# 3. Test from installed location
/usr/local/bin/zbx-speedtest.py speedtest.download
# Output: 393.62

# 4. Test as zabbix user (important!)
sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
# Output: 393.62

# 5. Verify config
cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf | grep speedtest.download
# Output: UserParameter=speedtest.download,/usr/local/bin/zbx-speedtest.py speedtest.download

# 6. Test from Zabbix server (if available)
zabbix_get -s your-hostname -k speedtest.download
# Output: 393.62
```

## Success Criteria

✅ Script returns numeric values for numeric metrics  
✅ Script returns text strings for text metrics  
✅ Script handles invalid metrics gracefully  
✅ Script works when called from `/usr/local/bin/`  
✅ Script works when run as `zabbix` user  
✅ Zabbix agent can collect metrics via `zabbix_get`  
✅ All 11 metrics return valid data

If all these pass, your Zabbix integration is working correctly! 🎉

