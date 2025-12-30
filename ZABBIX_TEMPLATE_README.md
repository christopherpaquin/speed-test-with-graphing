# 📡 Zabbix Template for Speedtest Monitoring

> A comprehensive Zabbix template for monitoring internet speed test results with 11 metrics, 7 triggers, and 4 graphs.

![Zabbix](https://img.shields.io/badge/zabbix-5.0+-blue)
![Template](https://img.shields.io/badge/template-ready-success)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Table of Contents

- [Template Overview](#-template-overview)
- [What's Included](#-whats-included)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Verification](#-verification)
- [Customization](#-customization)
- [Troubleshooting](#-troubleshooting)
- [Support](#-support)

---

## 🎯 Template Overview

This Zabbix template provides enterprise-grade monitoring for internet speed test results collected via the speedtest-cli integration.

**Template Details:**
- **Template Name:** Speedtest Monitoring
- **File:** `zabbix_template_speedtest.xml`
- **Zabbix Version:** Compatible with Zabbix 5.0+
- **Total Items:** 11 metrics
- **Total Triggers:** 7 alerts
- **Total Graphs:** 4 visualizations

---

## 📦 What's Included

### 📊 Applications (4)

Organized into logical groups for easy navigation:

1. **Speedtest - Latest Values** - Current speed test results
2. **Speedtest - 24h Averages** - 24-hour average calculations
3. **Speedtest - Statistics** - Test counts and timestamps
4. **Speedtest - Server Info** - Server information from tests

---

### 📈 Items (11)

All speedtest metrics are included:

| # | Item Name | Key | Type | Unit | Description |
|---|-----------|-----|------|------|-------------|
| 1 | Download Speed (Latest) | `speedtest.download` | Float | Mbps | Latest download speed |
| 2 | Upload Speed (Latest) | `speedtest.upload` | Float | Mbps | Latest upload speed |
| 3 | Ping/Latency (Latest) | `speedtest.ping` | Float | ms | Latest ping/latency |
| 4 | Download Speed (24h Average) | `speedtest.download_avg_24h` | Float | Mbps | 24-hour average download |
| 5 | Upload Speed (24h Average) | `speedtest.upload_avg_24h` | Float | Mbps | 24-hour average upload |
| 6 | Ping/Latency (24h Average) | `speedtest.ping_avg_24h` | Float | ms | 24-hour average ping |
| 7 | Test Count (24h) | `speedtest.test_count_24h` | Unsigned | tests | Number of tests in last 24h |
| 8 | Last Test Time | `speedtest.last_test_time` | Unsigned | unixtime | Unix timestamp of last test |
| 9 | Test Server Name | `speedtest.server_name` | Text | - | Name of last test server |
| 10 | Test Server Location | `speedtest.server_location` | Text | - | Location of last test server |
| 11 | Test Server Country | `speedtest.server_country` | Text | - | Country of last test server |

---

### 🚨 Triggers (7)

Pre-configured alerts for speed anomalies:

| Priority | Trigger Name | Condition | Description |
|----------|--------------|-----------|-------------|
| ⚠️ Warning | Download speed below 100 Mbps | `{speedtest.download}<100` | Download speed dropped below 100 Mbps |
| ⚠️ Warning | Upload speed below 10 Mbps | `{speedtest.upload}<10` | Upload speed dropped below 10 Mbps |
| ⚠️ Warning | Ping/Latency above 100ms | `{speedtest.ping}>100` | Ping exceeded 100ms |
| ⚠️ Warning | Insufficient speed tests in last 24h | `{speedtest.test_count_24h}<12` | Less than 12 tests in 24h |
| 🔴 High | Download speed critically low (<50 Mbps) | `{speedtest.download}<50` | Download critically below 50 Mbps |
| 🔴 High | Upload speed critically low (<5 Mbps) | `{speedtest.upload}<5` | Upload critically below 5 Mbps |
| 🔴 High | Ping/Latency critically high (>200ms) | `{speedtest.ping}>200` | Ping exceeded 200ms |

> 💡 **Tip:** Adjust trigger thresholds based on your connection speed. Edit triggers in **Configuration → Templates → Speedtest Monitoring → Triggers**.

---

### 📊 Graphs (4)

Beautiful visualizations for monitoring:

1. **📥 Download Speed**
   - Latest download speed (green line)
   - 24-hour average (red line)
   - Dual-axis display

2. **📤 Upload Speed**
   - Latest upload speed (green line)
   - 24-hour average (red line)
   - Dual-axis display

3. **📡 Ping/Latency**
   - Latest ping (red line)
   - 24-hour average (red dashed line)
   - Single-axis display

4. **🌐 Speed Test Overview**
   - Combined view of download, upload, and ping
   - Multi-line graph
   - Comprehensive overview

---

## 🚀 Installation

### Prerequisites

1. **Zabbix Agent Setup:**
   - Run `sudo ./setup_zabbix.sh` on the monitored host
   - This installs the UserParameters and script
   - Verify metrics work: `zabbix_get -s <hostname> -k speedtest.download`

2. **Zabbix Server:**
   - Access to Zabbix web interface
   - Admin or Super Admin role
   - Zabbix version 5.0 or higher

### Import Template

**Method 1: Via Zabbix Web Interface (Recommended)**

1. Log in to Zabbix web interface
2. Go to **Configuration** → **Templates**
3. Click **Import** button
4. Click **Choose File** and select `zabbix_template_speedtest.xml`
5. Click **Import**
6. Verify the template appears in the Templates list

**Method 2: Via Zabbix API (Alternative)**

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

> 📖 **Detailed Instructions:** See [ZABBIX_TEMPLATE_INSTALLATION.md](ZABBIX_TEMPLATE_INSTALLATION.md) for complete step-by-step guide.

---

## ⚙️ Configuration

### Update Intervals

The template uses the following update intervals:
- **Latest values:** 10 minutes (matches speedtest cron interval)
- **24h averages:** 5 minutes (matches MRTG update interval)
- **Statistics:** 5-10 minutes

**To adjust:**
1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Items**
2. Click on an item to edit
3. Modify **Update interval** as needed
4. Click **Update**

### Trigger Thresholds

Default trigger thresholds:
- Download < 100 Mbps (Warning), < 50 Mbps (High)
- Upload < 10 Mbps (Warning), < 5 Mbps (High)
- Ping > 100ms (Warning), > 200ms (High)
- Test count < 12 in 24h (Warning)

**To adjust:**
1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Triggers**
2. Click on a trigger to edit
3. Modify the expression (e.g., change `<100` to `<50`)
4. Click **Update**

> ⚠️ **Note:** Adjust thresholds based on your connection speed. For slower connections, lower the thresholds. For faster connections, raise them.

### History and Trends

- **History:** 7 days (detailed data)
- **Trends:** 365 days (aggregated data)

**To adjust:**
1. Go to **Configuration** → **Templates** → **Speedtest Monitoring** → **Items**
2. Click on an item to edit
3. Modify **History storage period** and **Trend storage period**
4. Click **Update**

---

## ✅ Verification

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
zabbix_get -s <hostname> -k speedtest.download_avg_24h
```

**Expected Output:**
```
393.62
41.33
26.01
446.83
```

### View Graphs

1. Go to **Monitoring** → **Graphs**
2. Select your host from the dropdown
3. You should see 4 graphs:
   - **Download Speed**
   - **Upload Speed**
   - **Ping/Latency**
   - **Speed Test Overview**

4. Click on any graph to view it in detail

### Test Triggers (Optional)

1. Go to **Monitoring** → **Problems**
2. If any triggers fire (based on your thresholds), they will appear here
3. You can test triggers by temporarily lowering thresholds in the template

---

## 🎨 Customization

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

---

## 🐛 Troubleshooting

### Items Show "Not Supported"

**Problem:** Items show "Not supported" in Latest data

**Solutions:**
1. Verify Zabbix agent is running: `sudo systemctl status zabbix-agent`
2. Check UserParameters config exists: `cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf`
3. Test script manually: `/usr/local/bin/zbx-speedtest.py speedtest.download`
4. Check agent logs: `sudo journalctl -u zabbix-agent -n 50`
5. Verify script permissions: `ls -l /usr/local/bin/zbx-speedtest.py`
6. Restart agent: `sudo systemctl restart zabbix-agent`

### Items Return 0

**Problem:** Items return 0 instead of actual values

**Solutions:**
1. Check if speedtest data exists: `cat speedtest_results.json`
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

---

## 📚 Support

For issues or questions:

1. **Check Documentation:**
   - Main [README.md](README.md) for setup instructions
   - [ZABBIX_TEMPLATE_INSTALLATION.md](ZABBIX_TEMPLATE_INSTALLATION.md) for installation guide
   - [TEST_ZABBIX.md](TEST_ZABBIX.md) for testing procedures

2. **Verify Prerequisites:**
   - Host has Zabbix agent running
   - Speedtest integration is set up
   - UserParameters are working

3. **Test Components:**
   - Test script: `/usr/local/bin/zbx-speedtest.py speedtest.download`
   - Test agent: `zabbix_get -s <host> -k speedtest.download`
   - Test data: `cat speedtest_results.json`

---

## 📝 Template Version

- **Version:** 1.0
- **Created:** 2025-12-30
- **Compatible with:** Zabbix 5.0, 6.0, 6.4+
- **Last Updated:** 2025-12-30

---

## 📄 License

MIT License - feel free to use and modify as needed!

---

**Made with ❤️ for network monitoring and speed testing**
