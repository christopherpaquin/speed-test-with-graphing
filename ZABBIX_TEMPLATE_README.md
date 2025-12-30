# Zabbix Template for Speedtest Monitoring

This directory contains a Zabbix template for monitoring internet speed test results.

## Template File

- **File:** `zabbix_template_speedtest.xml`
- **Template Name:** Speedtest Monitoring
- **Zabbix Version:** Compatible with Zabbix 5.0+

## What's Included

### Applications (4)
1. **Speedtest - Latest Values** - Current speed test results
2. **Speedtest - 24h Averages** - 24-hour average calculations
3. **Speedtest - Statistics** - Test counts and timestamps
4. **Speedtest - Server Info** - Server information from tests

### Items (11)
1. **Download Speed (Latest)** - `speedtest.download` (Mbps)
2. **Upload Speed (Latest)** - `speedtest.upload` (Mbps)
3. **Ping/Latency (Latest)** - `speedtest.ping` (ms)
4. **Download Speed (24h Average)** - `speedtest.download_avg_24h` (Mbps)
5. **Upload Speed (24h Average)** - `speedtest.upload_avg_24h` (Mbps)
6. **Ping/Latency (24h Average)** - `speedtest.ping_avg_24h` (ms)
7. **Test Count (24h)** - `speedtest.test_count_24h` (count)
8. **Last Test Time** - `speedtest.last_test_time` (Unix timestamp)
9. **Test Server Name** - `speedtest.server_name` (text)
10. **Test Server Location** - `speedtest.server_location` (text)
11. **Test Server Country** - `speedtest.server_country` (text)

### Triggers (7)
1. **Download speed below 100 Mbps** (Warning)
2. **Upload speed below 10 Mbps** (Warning)
3. **Ping/Latency above 100ms** (Warning)
4. **Insufficient speed tests in last 24h** (Warning)
5. **Download speed critically low (<50 Mbps)** (High)
6. **Upload speed critically low (<5 Mbps)** (High)
7. **Ping/Latency critically high (>200ms)** (High)

### Graphs (4)
1. **Download Speed** - Latest download + 24h average
2. **Upload Speed** - Latest upload + 24h average
3. **Ping/Latency** - Latest ping + 24h average
4. **Speed Test Overview** - Combined view of download, upload, and ping

## Installation

### Prerequisites

1. **Zabbix Agent Setup:**
   - Run `sudo ./setup_zabbix.sh` on the monitored host
   - This installs the UserParameters and script
   - Verify metrics work: `zabbix_get -s <hostname> -k speedtest.download`

2. **Zabbix Server:**
   - Access to Zabbix web interface
   - Admin or Super Admin role

### Import Template

1. **Via Zabbix Web Interface:**
   - Log in to Zabbix web interface
   - Go to **Configuration** → **Templates**
   - Click **Import** button
   - Click **Choose File** and select `zabbix_template_speedtest.xml`
   - Click **Import**
   - Verify the template appears in the Templates list

2. **Via Zabbix API (Alternative):**
   ```bash
   # Get authentication token
   TOKEN=$(curl -X POST -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"user.login","params":{"user":"Admin","password":"zabbix"},"id":1}' \
     http://your-zabbix-server/api_jsonrpc.php | jq -r .result)
   
   # Import template
   curl -X POST -H "Content-Type: application/json" \
     -H "Authorization: Bearer $TOKEN" \
     -d @zabbix_template_speedtest.xml \
     http://your-zabbix-server/api_jsonrpc.php
   ```

### Apply Template to Host

1. Go to **Configuration** → **Hosts**
2. Select your host (or create a new one)
3. Click on the host name
4. Go to the **Templates** tab
5. Click **Select** next to "Link new templates"
6. Search for "Speedtest Monitoring"
7. Select the template and click **Add**
8. Click **Update** to save

## Configuration

### Update Intervals

The template uses the following update intervals:
- **Latest values:** 10 minutes (matches speedtest cron interval)
- **24h averages:** 5 minutes (matches MRTG update interval)
- **Statistics:** 5-10 minutes

You can adjust these in the template or on individual items after import.

### Trigger Thresholds

Default trigger thresholds:
- Download < 100 Mbps (Warning), < 50 Mbps (High)
- Upload < 10 Mbps (Warning), < 5 Mbps (High)
- Ping > 100ms (Warning), > 200ms (High)
- Test count < 12 in 24h (Warning)

**Adjust thresholds** based on your connection speed:
- For slower connections, lower the thresholds
- For faster connections, raise the thresholds
- Edit triggers in **Configuration** → **Templates** → **Speedtest Monitoring** → **Triggers**

### History and Trends

- **History:** 7 days (detailed data)
- **Trends:** 365 days (aggregated data)

Adjust based on your storage capacity and retention needs.

## Verification

### Check Items Are Collecting Data

1. Go to **Monitoring** → **Latest data**
2. Select your host
3. Filter by "Speedtest"
4. Verify all 11 items show data (not "No data")

### Test Individual Items

From Zabbix server:
```bash
zabbix_get -s <hostname> -k speedtest.download
zabbix_get -s <hostname> -k speedtest.upload
zabbix_get -s <hostname> -k speedtest.ping
```

### View Graphs

1. Go to **Monitoring** → **Graphs**
2. Select your host
3. View the 4 pre-configured graphs:
   - Download Speed
   - Upload Speed
   - Ping/Latency
   - Speed Test Overview

## Customization

### Adding Custom Triggers

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Triggers**
2. Click **Create trigger**
3. Use expressions like:
   - `{Speedtest Monitoring:speedtest.download.avg(1h)}<50` - Average over 1 hour
   - `{Speedtest Monitoring:speedtest.ping.last()}>150` - Latest ping value

### Creating Custom Graphs

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Graphs**
2. Click **Create graph**
3. Add items and configure display options

### Modifying Item Settings

1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Items**
2. Click on an item to edit
3. Modify update interval, history, trends, etc.

## Troubleshooting

### Items Show "Not Supported"

**Problem:** Items show "Not supported" in Latest data

**Solutions:**
1. Verify Zabbix agent is running: `sudo systemctl status zabbix-agent`
2. Check UserParameters config exists: `cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf`
3. Test script manually: `/usr/local/bin/zbx-speedtest.py speedtest.download`
4. Check agent logs: `sudo journalctl -u zabbix-agent -n 50`
5. Verify script permissions: `ls -l /usr/local/bin/zbx-speedtest.py`
6. Test as zabbix user: `sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download`

### Items Return 0

**Problem:** Items return 0 instead of actual values

**Solutions:**
1. Check if speedtest data exists: `cat /opt/projects/speed-test-with-graphing/speedtest_results.json`
2. Run a speed test: `python3 speedtest_runner.py`
3. Verify script is up to date: Re-run `sudo ./setup_zabbix.sh`

### Template Import Fails

**Problem:** Template import shows errors

**Solutions:**
1. Verify XML file is valid: Check for syntax errors
2. Check Zabbix version compatibility (requires 5.0+)
3. Ensure you have template import permissions
4. Try importing via API instead of web interface

### Triggers Not Firing

**Problem:** Triggers don't fire even when thresholds are met

**Solutions:**
1. Verify items are collecting data
2. Check trigger expressions are correct
3. Ensure trigger dependencies are met
4. Check trigger status (may be disabled)

## Support

For issues or questions:
1. Check the main README.md for setup instructions
2. Review TEST_ZABBIX.md for testing procedures
3. Verify all prerequisites are met
4. Check Zabbix agent logs for errors

## Template Version

- **Version:** 1.0
- **Created:** 2025-12-30
- **Compatible with:** Zabbix 5.0, 6.0, 6.4+
- **Last Updated:** 2025-12-30

