# 🚀 Speed Test with MRTG Graphing

> A Python application for testing internet speed and visualizing results using MRTG (Multi Router Traffic Grapher) with Apache.

![Status](https://img.shields.io/badge/status-active-success)
![Python](https://img.shields.io/badge/python-3.7+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

- ⚡ **Speed Testing**: Test download speed, upload speed, and ping/latency
- 📊 **Data Logging**: Save all test results to JSON for historical tracking
- 📈 **MRTG Graphing**: Generate beautiful graphs using MRTG served via Apache
- 📡 **Zabbix Integration**: Export metrics to Zabbix for enterprise monitoring
- 🤖 **Automated Testing**: Cron job runs speed tests at configurable intervals
- 🔄 **Automated Graphing**: Cron job updates MRTG graphs at configurable intervals
- 🔒 **Idempotent Setup**: All setup scripts can be run multiple times safely
- 🌐 **Web Access**: View graphs from any device on your network via Apache

---

## 📋 Table of Contents

- [Configuration](#-configuration)
- [Installation](#-installation)
- [Setup Scripts](#-setup-scripts)
- [Core Scripts](#-core-scripts)
- [Zabbix Integration](#-zabbix-integration)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Data Format](#-data-format)
- [Cron Jobs](#-cron-jobs)
- [Troubleshooting](#-troubleshooting)
- [Requirements](#-requirements)

---

## ⚙️ Configuration

Before running setup, you need to configure your IP address and other settings:

### Step 1: Copy the example vars file
```bash
cp vars.example vars
```

### Step 2: Edit the `vars` file with your settings
```bash
# Apache IP address and port
APACHE_LISTEN_IP="YOUR_IP_ADDRESS"
APACHE_LISTEN_PORT="80"

# Speedtest cron interval (in minutes)
SPEEDTEST_INTERVAL="10"

# MRTG update interval (in minutes)
MRTG_UPDATE_INTERVAL="5"
```

> ⚠️ **Important:** The `vars` file is ignored by git and contains your local configuration. Do not commit it to version control.

---

## 🚀 Installation

### Quick Start

1. **Install Python dependencies:**
   ```bash
   python3 -m pip install -r requirements.txt
   ```

2. **Configure your settings** (see [Configuration](#-configuration) section above)

3. **Run the master setup script** (requires root for Apache configuration):
   ```bash
   sudo ./setup_all.sh
   ```

This will automatically:
- ✅ Install MRTG and Apache (if not already installed)
- ✅ Configure MRTG for speedtest graphing
- ✅ Set up Apache to serve MRTG graphs on your configured IP address
- ✅ Configure firewall to allow traffic
- ✅ Create cron jobs for automated testing and graph updates
- ✅ Initialize MRTG log files with initial data points
- ✅ Set up Zabbix integration (if Zabbix agent is installed)

---

## 🔧 Setup Scripts

All setup scripts are **idempotent** - they can be run multiple times safely without causing issues.

### 📦 `setup_all.sh` - Master Setup Script

**What it does:**
- 🎯 Orchestrates the complete setup process
- 📞 Calls all other setup scripts in the correct order
- 📊 Displays a summary with your configured IP address and intervals
- ✅ Validates that the `vars` file exists and is properly configured

**When to use:**
- First-time setup
- Complete system reconfiguration
- After pulling updates from git

**Usage:**
```bash
sudo ./setup_all.sh
```

**Post-setup:**
- All components are configured and ready
- Apache is running and serving graphs
- Cron jobs are active and will run automatically

---

### 🌐 `setup_mrtg.sh` - MRTG and Apache Configuration

**What it does:**
- 📥 Installs MRTG package (if not already installed)
- 🌐 Installs Apache/HTTPD (if not already installed)
- 📁 Creates MRTG directory structure (`mrtg/cfg/`, `mrtg/html/`, `mrtg/logs/`, `mrtg/work/`)
- ⚙️ Generates MRTG configuration files for download, upload, and ping metrics
- 🔧 Configures Apache to listen on your specified IP address
- 🚪 Sets up Apache VirtualHost for MRTG graphs
- 🔥 Configures firewall (firewalld, ufw, or iptables) to allow HTTP traffic
- 🔒 Sets proper file permissions and SELinux contexts
- 📄 Creates index.html landing page for easy navigation
- 🚫 Disables default MRTG config that restricts access to localhost
- 🔄 Runs initial MRTG updates to create log files

**When to use:**
- Setting up MRTG and Apache for the first time
- Reconfiguring Apache IP address
- Fixing permission or SELinux issues
- After system updates that might have reset configurations

**Usage:**
```bash
sudo ./setup_mrtg.sh
```

**Post-setup:**
- MRTG is installed and configured
- Apache is running on your specified IP:port
- MRTG configuration files are in `mrtg/cfg/`
- HTML directory is ready at `mrtg/html/`
- Graphs are accessible via web browser
- Firewall allows incoming HTTP connections

---

### ⏰ `setup_cron.sh` - Speedtest Cron Job Setup

**What it does:**
- 📝 Creates a cron job to run speed tests automatically
- ⏱️ Uses interval from `vars` file (default: every 10 minutes)
- 📋 Adds cron job with unique tag for easy identification
- 🔄 Updates existing cron job if it already exists (idempotent)
- 📊 Logs all speed test runs to `speedtest_cron.log`

**When to use:**
- Setting up automated speed testing
- Changing the speed test interval
- After manual cron job deletion
- When speed tests aren't running automatically

**Usage:**
```bash
./setup_cron.sh
```

**Post-setup:**
- Cron job is active in your crontab
- Speed tests will run automatically at the configured interval
- Results are saved to `speedtest_results.json`
- Logs are written to `speedtest_cron.log`

**Cron job format:**
```
*/10 * * * * cd /opt/projects/speed-test-with-graphing && /usr/bin/python3 speedtest_runner.py >> speedtest_cron.log 2>&1
```

---

### 📊 `setup_mrtg_cron.sh` - MRTG Graph Update Cron Job

**What it does:**
- 📝 Creates a cron job to update MRTG graphs automatically
- ⏱️ Uses interval from `vars` file (default: every 5 minutes)
- 🔄 Updates all three graphs (download, upload, ping) in sequence
- 🌍 Sets `LANG=C` to avoid MRTG UTF-8 warnings
- 📋 Uses semicolons (`;`) instead of `&&` so all graphs update even if one fails
- 🔄 Updates existing cron job if it already exists (idempotent)

**When to use:**
- Setting up automated graph updates
- Changing the graph update interval
- After manual cron job deletion
- When graphs aren't updating automatically

**Usage:**
```bash
./setup_mrtg_cron.sh
```

**Post-setup:**
- Cron job is active in your crontab
- MRTG graphs will update automatically at the configured interval
- All three graphs (download, upload, ping) are updated
- Graph files are regenerated in `mrtg/html/`

**Cron job format:**
```
*/5 * * * * env LANG=C /usr/bin/mrtg [download config]; env LANG=C /usr/bin/mrtg [upload config]; env LANG=C /usr/bin/mrtg [ping config]
```

---

### 📡 `setup_zabbix.sh` - Zabbix Integration Setup

**What it does:**
- 📝 Creates UserParameters config file in `/etc/zabbix/zabbix_agentd.conf.d/speedtest.conf`
- 📋 Defines 11 UserParameters for speedtest metrics
- 📦 Installs `zbx-speedtest.py` script to `/usr/local/bin/`
- 🔒 Sets proper file permissions and ownership
- 🔄 Restarts Zabbix agent to load new configuration
- ✅ Tests the script to ensure it works correctly

**When to use:**
- Setting up Zabbix monitoring for speedtest metrics
- After installing Zabbix agent on the system
- Reconfiguring Zabbix integration
- When Zabbix metrics are not being collected

**Usage:**
```bash
sudo ./setup_zabbix.sh
```

**Post-setup:**
- UserParameters config file is created and active
- Zabbix script is installed and executable
- Zabbix agent has been restarted (if service exists)
- All 11 metrics are available for collection
- Ready to configure items in Zabbix server

**Available UserParameters:**
- `speedtest.download` - Latest download speed
- `speedtest.upload` - Latest upload speed
- `speedtest.ping` - Latest ping/latency
- `speedtest.download_avg_24h` - 24-hour average download
- `speedtest.upload_avg_24h` - 24-hour average upload
- `speedtest.ping_avg_24h` - 24-hour average ping
- `speedtest.test_count_24h` - Number of tests in last 24h
- `speedtest.last_test_time` - Unix timestamp of last test
- `speedtest.server_name` - Name of last test server
- `speedtest.server_location` - Location of last test server
- `speedtest.server_country` - Country of last test server

---

## 🐍 Core Scripts

### 🏃 `speedtest_runner.py` - Speed Test Execution

**What it does:**
- 🌐 Connects to speedtest.net servers
- 🔍 Automatically selects the best server based on ping
- ⬇️ Tests download speed (in Mbps)
- ⬆️ Tests upload speed (in Mbps)
- 📡 Measures ping/latency (in milliseconds)
- 💾 Saves results to `speedtest_results.json` in JSON format
- 📊 Displays results to console
- 🔄 Appends to existing results (preserves history)

**When to use:**
- Manual speed test execution
- Testing the system
- Debugging speed test issues
- Called automatically by cron job

**Usage:**
```bash
python3 speedtest_runner.py
```

**Output:**
- Console output with test results
- JSON entry added to `speedtest_results.json`
- Includes timestamp, speeds, ping, and server information

**Post-execution:**
- New test result is saved to JSON file
- Data is available for MRTG graphing
- Can be viewed in JSON file or via MRTG graphs

---

### 📈 `mrtg_speedtest.py` - MRTG Data Provider

**What it does:**
- 📖 Reads speed test results from `speedtest_results.json`
- 📊 Calculates averages over the last 24 hours (configurable)
- 🔢 Outputs data in MRTG-compatible format (4 lines: value1, value2, uptime, system_name)
- 🎯 Supports three metrics: download, upload, and ping
- ⏰ Filters results by time window (default: last 24 hours)
- 🔄 Returns 0 if no data is available

**When to use:**
- Called automatically by MRTG (via cron job)
- Testing MRTG data output
- Debugging graph data issues
- Manual verification of calculated averages

**Usage:**
```bash
# Test download metric
python3 mrtg_speedtest.py --metric download

# Test upload metric
python3 mrtg_speedtest.py --metric upload

# Test ping metric
python3 mrtg_speedtest.py --metric ping

# Use custom time window (hours)
python3 mrtg_speedtest.py --metric download --hours 12
```

**Output format (MRTG standard):**
```
473          # Value 1 (average download in Mbps)
0            # Value 2 (unused, always 0)
             # Uptime (empty)
Average Download  # System name
```

**Post-execution:**
- MRTG reads this output to update graphs
- Graphs reflect the calculated averages
- Data is stored in MRTG log files

---

### 📡 `zbx-speedtest.py` - Zabbix Data Provider

**What it does:**
- 📖 Reads speed test results from `speedtest_results.json`
- 🔢 Returns individual metrics for Zabbix monitoring
- 📊 Calculates averages and statistics on demand
- ⏰ Filters results by time windows (24 hours)
- 🎯 Supports 11 different metrics for comprehensive monitoring

**When to use:**
- Called automatically by Zabbix agent (via UserParameters)
- Testing Zabbix integration
- Debugging metric collection
- Manual verification of metric values

**Usage:**
```bash
# Test individual metrics
/usr/local/bin/zbx-speedtest.py speedtest.download
/usr/local/bin/zbx-speedtest.py speedtest.upload
/usr/local/bin/zbx-speedtest.py speedtest.ping
/usr/local/bin/zbx-speedtest.py speedtest.download_avg_24h
/usr/local/bin/zbx-speedtest.py speedtest.test_count_24h
```

**Available Metrics:**
- `speedtest.download` - Latest download speed (Mbps)
- `speedtest.upload` - Latest upload speed (Mbps)
- `speedtest.ping` - Latest ping/latency (ms)
- `speedtest.download_avg_24h` - 24-hour average download (Mbps)
- `speedtest.upload_avg_24h` - 24-hour average upload (Mbps)
- `speedtest.ping_avg_24h` - 24-hour average ping (ms)
- `speedtest.test_count_24h` - Number of tests in last 24 hours
- `speedtest.last_test_time` - Unix timestamp of last test
- `speedtest.server_name` - Name of last test server
- `speedtest.server_location` - Location of last test server
- `speedtest.server_country` - Country of last test server

**Post-execution:**
- Zabbix agent reads this output to collect metrics
- Metrics are sent to Zabbix server for monitoring
- Can be used in triggers, graphs, and dashboards

---

## 📡 Zabbix Integration

This project includes full Zabbix integration for enterprise monitoring of speed test metrics.

### 🎯 Overview

The Zabbix integration provides 11 UserParameters that expose speedtest metrics to your Zabbix server. This allows you to:
- 📊 Create graphs and dashboards in Zabbix
- 🚨 Set up triggers for speed anomalies
- 📈 Track historical trends over time
- 🔔 Get alerts when speeds drop below thresholds

### 📦 Installation

#### Prerequisites

- Zabbix agent must be installed and running on the host
- Speed test data must exist (run `python3 speedtest_runner.py` at least once)
- Root/sudo access required for installation

#### Installation Methods

**Method 1: Automatic Setup (Recommended)**

The Zabbix integration is automatically configured when you run the master setup script:
```bash
sudo ./setup_all.sh
```

This will set up MRTG, Apache, cron jobs, and Zabbix integration all at once.

**Method 2: Manual Setup**

If you want to set up Zabbix integration separately or only need Zabbix:
```bash
sudo ./setup_zabbix.sh
```

#### What Gets Installed

The setup script performs the following actions:

1. **Creates UserParameters Configuration:**
   - **Location:** `/etc/zabbix/zabbix_agentd.conf.d/speedtest.conf`
   - **Contents:** 11 UserParameter definitions
   - **Permissions:** `root:root`, `644`

2. **Installs Zabbix Script:**
   - **Source:** `./zbx-speedtest.py` (project directory)
   - **Destination:** `/usr/local/bin/zbx-speedtest.py`
   - **Permissions:** `root:root`, `755` (executable)
   - **Purpose:** Provides metric data to Zabbix agent

3. **Restarts Zabbix Agent:**
   - Automatically restarts `zabbix-agent` or `zabbix-agentd` service
   - Loads new UserParameters configuration
   - Verifies agent is running

4. **Verifies Installation:**
   - Tests script execution
   - Checks file permissions
   - Validates configuration

#### Installation Locations Summary

| Component | Location | Description |
|-----------|----------|-------------|
| **UserParameters Config** | `/etc/zabbix/zabbix_agentd.conf.d/speedtest.conf` | Zabbix agent configuration file |
| **Zabbix Script** | `/usr/local/bin/zbx-speedtest.py` | Executable script for metric collection |
| **Source Script** | `/opt/projects/speed-test-with-graphing/zbx-speedtest.py` | Original script in project directory |
| **Speedtest Data** | `/opt/projects/speed-test-with-graphing/speedtest_results.json` | JSON file with test results |

### 📊 Available Metrics

| Metric | Description | Unit | Example |
|--------|-------------|------|---------|
| `speedtest.download` | Latest download speed | Mbps | `445.79` |
| `speedtest.upload` | Latest upload speed | Mbps | `55.83` |
| `speedtest.ping` | Latest ping/latency | ms | `30.2` |
| `speedtest.download_avg_24h` | 24-hour average download | Mbps | `473.5` |
| `speedtest.upload_avg_24h` | 24-hour average upload | Mbps | `49.2` |
| `speedtest.ping_avg_24h` | 24-hour average ping | ms | `28.5` |
| `speedtest.test_count_24h` | Number of tests in last 24h | count | `144` |
| `speedtest.last_test_time` | Unix timestamp of last test | timestamp | `1703941708` |
| `speedtest.server_name` | Name of last test server | string | `"Lyons, GA"` |
| `speedtest.server_location` | Location of last test server | string | `"Unknown"` |
| `speedtest.server_country` | Country of last test server | string | `"United States"` |

### 🧪 Testing the Integration

#### Test 1: Test Script from Project Directory (Before Setup)

Before running setup, test the script from the project directory:
```bash
cd /opt/projects/speed-test-with-graphing
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

> ⚠️ **Note:** If you see `0`, it means no speedtest data exists yet. Run `python3 speedtest_runner.py` first.

#### Test 2: Test All Metrics at Once

Use the provided test script to test all 11 metrics:
```bash
cd /opt/projects/speed-test-with-graphing
./test_zabbix_metrics.sh
```

This will display all metrics with their current values.

#### Test 3: Test from Installed Location (After Setup)

After running `sudo ./setup_zabbix.sh`, test from the installed location:
```bash
# Test individual metrics
/usr/local/bin/zbx-speedtest.py speedtest.download
/usr/local/bin/zbx-speedtest.py speedtest.upload
/usr/local/bin/zbx-speedtest.py speedtest.ping
/usr/local/bin/zbx-speedtest.py speedtest.download_avg_24h
/usr/local/bin/zbx-speedtest.py speedtest.upload_avg_24h
/usr/local/bin/zbx-speedtest.py speedtest.ping_avg_24h
/usr/local/bin/zbx-speedtest.py speedtest.test_count_24h
/usr/local/bin/zbx-speedtest.py speedtest.last_test_time
/usr/local/bin/zbx-speedtest.py speedtest.server_name
/usr/local/bin/zbx-speedtest.py speedtest.server_location
/usr/local/bin/zbx-speedtest.py speedtest.server_country
```

**Expected Outputs:**
- **Numeric metrics:** Decimal numbers or integers (e.g., `393.62`, `41.33`, `3`, `1767120005`)
- **Text metrics:** Strings (e.g., `"Thomasville, GA"`, `"United States"`)

#### Test 4: Test as Zabbix User (Important!)

This is critical - Zabbix agent runs as the `zabbix` user, so test with that user:
```bash
sudo -u zabbix /usr/local/bin/zbx-speedtest.py speedtest.download
```

**Expected:** Should return the same value as when run as root (e.g., `393.62`)

> ⚠️ **If this returns `0`:** The script may be outdated. Re-run `sudo ./setup_zabbix.sh` to update it.

#### Test 5: Test from Zabbix Server

From your Zabbix server, use `zabbix_get` to test the agent connection:
```bash
# Replace <hostname> with your monitored host's hostname or IP
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

#### Test 6: Verify Configuration

Check that all components are properly installed:
```bash
# Verify UserParameters config exists
cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf

# Verify script is installed
ls -l /usr/local/bin/zbx-speedtest.py

# Check Zabbix agent status
sudo systemctl status zabbix-agent

# Check Zabbix agent logs for errors
sudo journalctl -u zabbix-agent -n 50 | grep -i speedtest
```

**Expected:**
- Config file should show 11 `UserParameter=` lines
- Script should be executable (`-rwxr-xr-x`)
- Agent should be running
- No errors in logs

### 📈 Zabbix Configuration

**1. Add Items in Zabbix:**
- Go to Configuration → Hosts → Your Host → Items
- Click "Create item"
- Use the metric names (e.g., `speedtest.download`)
- Set appropriate update interval (e.g., 10 minutes to match speedtest interval)
- Configure value types (Numeric for speeds/ping, Text for server info)

**2. Create Graphs:**
- Go to Configuration → Hosts → Your Host → Graphs
- Create graphs for download, upload, and ping speeds
- Add items for latest values and 24-hour averages

**3. Set Up Triggers:**
Example triggers:
- Download speed below 100 Mbps: `{speedtest.download}<100`
- Upload speed below 10 Mbps: `{speedtest.upload}<10`
- Ping above 100ms: `{speedtest.ping}>100`
- No tests in last 2 hours: `{speedtest.test_count_24h}<12`

**4. Create Dashboards:**
- Combine graphs, latest values, and server information
- Add widgets for real-time monitoring

### 🔄 Post-Setup

After setup:
- ✅ UserParameters are active and ready to use
- ✅ Zabbix agent has been restarted (if service exists)
- ✅ Script is installed and executable
- ✅ Configuration file is in place

**Next Steps:**
1. Verify metrics are being collected in Zabbix
2. Create items for the metrics you want to monitor
3. Set up graphs and dashboards
4. Configure triggers for alerts

### 🐛 Troubleshooting

**Metric returns 0 or empty:**
- Check if speedtest data exists: `cat speedtest_results.json`
- Verify script path: `ls -l /usr/local/bin/zbx-speedtest.py`
- Test script manually: `/usr/local/bin/zbx-speedtest.py speedtest.download`

**Zabbix agent can't collect metrics:**
- Check agent logs: `sudo journalctl -u zabbix-agent -n 50`
- Verify UserParameters config: `cat /etc/zabbix/zabbix_agentd.conf.d/speedtest.conf`
- Restart agent: `sudo systemctl restart zabbix-agent`
- Check script permissions: `ls -l /usr/local/bin/zbx-speedtest.py`

**Script not found:**
- Re-run setup: `sudo ./setup_zabbix.sh`
- Verify script exists: `ls -l /usr/local/bin/zbx-speedtest.py`

---

## 📖 Usage

### 🔍 Manual Speed Test

Run a single speed test manually:

```bash
python3 speedtest_runner.py
```

**Output example:**
```
Selecting best server...
Testing download speed...
Testing upload speed...
Result saved to /opt/projects/speed-test-with-graphing/speedtest_results.json

==================================================
Speed Test Results:
==================================================
Download: 445.79 Mbps
Upload: 55.83 Mbps
Ping: 30.2 ms
Server: Lyons, GA (Unknown)
Timestamp: 2025-12-30T13:08:28.903570
==================================================
```

---

### 🌐 View MRTG Graphs

After setup, graphs are available via web browser:

- **Main page**: `http://YOUR_IP_ADDRESS/mrtg/`
- **Download speed**: `http://YOUR_IP_ADDRESS/mrtg/download.html`
- **Upload speed**: `http://YOUR_IP_ADDRESS/mrtg/upload.html`
- **Ping/Latency**: `http://YOUR_IP_ADDRESS/mrtg/ping.html`

> 💡 **Tip:** Replace `YOUR_IP_ADDRESS` with the IP address you configured in the `vars` file.

**Graph Features:**
- 📊 **Daily Graph**: 5-minute averages over 24 hours
- 📅 **Weekly Graph**: 30-minute averages over 7 days
- 📆 **Monthly Graph**: 2-hour averages over 30 days
- 📆 **Yearly Graph**: Daily averages over 1 year

**Note:** Apache is configured to listen on the IP address and port specified in your `vars` file. The firewall is automatically configured to allow traffic on that IP and port.

---

### 🧪 Test MRTG Data Script

Test the MRTG data output script:

```bash
# Test download metric
python3 mrtg_speedtest.py --metric download

# Test upload metric  
python3 mrtg_speedtest.py --metric upload

# Test ping metric
python3 mrtg_speedtest.py --metric ping
```

**Expected output:**
```
473          # Average value (varies based on your data)
0            # Always 0 (unused)
             # Empty line
Average Download  # Metric name
```

---

## 📁 Project Structure

```
speed-test-with-graphing/
├── 📄 speedtest_runner.py      # Runs speed tests and saves to JSON
├── 📄 mrtg_speedtest.py         # Outputs speedtest data in MRTG format
├── 📄 zbx-speedtest.py          # Outputs speedtest data for Zabbix
├── 📄 requirements.txt          # Python dependencies
├── 📄 vars.example              # Configuration template (committed to git)
├── 📄 vars                      # Your configuration (ignored by git)
│
├── 🔧 setup_all.sh              # Master setup script (runs all below)
├── 🔧 setup_mrtg.sh             # Sets up MRTG and Apache
├── 🔧 setup_cron.sh             # Sets up speedtest cron job
├── 🔧 setup_mrtg_cron.sh        # Sets up MRTG update cron job
├── 🔧 setup_zabbix.sh            # Sets up Zabbix integration
│
├── 📊 speedtest_results.json     # All test results (ignored by git)
├── 📋 speedtest_cron.log        # Speedtest execution logs
│
└── 📂 mrtg/                      # MRTG directory (ignored by git)
    ├── 📂 cfg/                   # MRTG configuration files
    │   ├── speedtest-download.cfg
    │   ├── speedtest-upload.cfg
    │   └── speedtest-ping.cfg
    ├── 📂 html/                  # Generated HTML and graph files
    │   ├── index.html            # Landing page
    │   ├── download.html         # Download speed graph page
    │   ├── upload.html           # Upload speed graph page
    │   ├── ping.html             # Ping graph page
    │   ├── *.png                 # Graph images (day/week/month/year)
    │   └── *.log                 # MRTG data logs
    ├── 📂 logs/                  # MRTG execution logs
    └── 📂 work/                  # MRTG working directory
```

---

## 📊 Data Format

Results are stored in JSON format with the following structure:

```json
[
  {
    "timestamp": "2024-01-15T10:30:00",
    "download_mbps": 95.42,
    "upload_mbps": 12.35,
    "ping_ms": 15.2,
    "server": {
      "name": "Server Name",
      "location": "City, Country",
      "country": "Country"
    }
  }
]
```

**Fields:**
- `timestamp`: ISO 8601 format timestamp
- `download_mbps`: Download speed in Megabits per second
- `upload_mbps`: Upload speed in Megabits per second
- `ping_ms`: Latency in milliseconds
- `server`: Information about the test server used

---

## 📈 MRTG Configuration

MRTG graphs display:

- **📥 Average Download Speed** (Mbps) - averaged over last 24 hours
- **📤 Average Upload Speed** (Mbps) - averaged over last 24 hours
- **📡 Average Ping** (ms) - averaged over last 24 hours

**Graph Types:**
- **Daily**: 5-minute averages, 24-hour view
- **Weekly**: 30-minute averages, 7-day view
- **Monthly**: 2-hour averages, 30-day view
- **Yearly**: Daily averages, 1-year view

Graphs are updated at the interval specified in your `vars` file (default: every 5 minutes).

---

## ⏰ Cron Jobs

The setup scripts create cron jobs based on your `vars` file configuration:

### 1. 📊 Speedtest Cron Job

**Default:** Every 10 minutes

**What it does:**
- Runs `speedtest_runner.py`
- Saves results to `speedtest_results.json`
- Logs output to `speedtest_cron.log`

**Cron format:**
```
*/10 * * * * cd /path/to/project && /usr/bin/python3 speedtest_runner.py >> speedtest_cron.log 2>&1
```

**Post-execution:**
- New speed test result added to JSON
- Data available for MRTG graphing
- Log entry in `speedtest_cron.log`

---

### 2. 📈 MRTG Update Cron Job

**Default:** Every 5 minutes

**What it does:**
- Updates download speed graph
- Updates upload speed graph
- Updates ping graph
- Regenerates HTML pages
- Updates PNG graph images

**Cron format:**
```
*/5 * * * * env LANG=C /usr/bin/mrtg [download config]; env LANG=C /usr/bin/mrtg [upload config]; env LANG=C /usr/bin/mrtg [ping config]
```

**Post-execution:**
- Graph images updated (PNG files)
- HTML pages regenerated
- MRTG log files updated
- Graphs reflect latest averages

---

## 🔄 Idempotency

All setup scripts are **idempotent**, meaning they can be run multiple times safely:

✅ **Safe to re-run:**
- They check for existing configurations before creating new ones
- They update existing configurations if needed
- They won't create duplicate cron jobs
- They won't break if components are already installed
- They validate and fix permissions if needed

**Benefits:**
- 🛡️ Safe to run after system updates
- 🔄 Easy to reconfigure settings
- 🐛 Can fix issues by re-running setup
- 📝 No manual cleanup required

---

## 📋 Requirements

- **Python 3.7+** - For running speed tests
- **Internet connection** - Required for speed tests
- **Root/sudo access** - For Apache and MRTG setup
- **speedtest-cli** - Python package (installed via requirements.txt)
- **MRTG** - Installed automatically by setup script
- **Apache/HTTPD** - Installed automatically by setup script

**System Support:**
- ✅ RHEL/CentOS (tested on RHEL 10)
- ✅ Debian/Ubuntu
- ✅ Other Linux distributions with yum/apt-get

---

## 🔧 Troubleshooting

### 🔍 Check if cron jobs are running:
```bash
crontab -l
```

### 📋 Check speedtest logs:
```bash
tail -f speedtest_cron.log
```

### 📊 Check MRTG logs:
```bash
tail -f mrtg/logs/speedtest-*.log
```

### 🧪 Test MRTG data script:
```bash
python3 mrtg_speedtest.py --metric download
python3 mrtg_speedtest.py --metric upload
python3 mrtg_speedtest.py --metric ping
```

### 🌐 Restart Apache:
```bash
# RHEL/CentOS
sudo systemctl restart httpd

# Debian/Ubuntu
sudo systemctl restart apache2
```

### ⚙️ Verify your configuration:
```bash
cat vars
```

### 🔒 Check Apache status:
```bash
sudo systemctl status httpd    # RHEL/CentOS
sudo systemctl status apache2  # Debian/Ubuntu
```

### 🔥 Check firewall rules:
```bash
# firewalld
sudo firewall-cmd --list-all

# ufw
sudo ufw status

# iptables
sudo iptables -L -n
```

### 📁 Check file permissions:
```bash
ls -la mrtg/html/
ls -laZ mrtg/html/  # SELinux context
```

### 🔄 Re-run setup (if needed):
```bash
sudo ./setup_all.sh
```

---

## 📝 Common Issues

### ❌ Graphs show no data
**Solution:** 
- Wait for more speed test results (need multiple data points)
- Verify `speedtest_results.json` has data: `cat speedtest_results.json`
- Check MRTG logs for errors: `tail mrtg/logs/speedtest-*.log`

### ❌ Apache "Forbidden" error
**Solution:**
- Run `sudo ./setup_mrtg.sh` to fix permissions
- Check SELinux context: `ls -laZ mrtg/html/`
- Verify firewall allows traffic

### ❌ Cron jobs not running
**Solution:**
- Verify cron service is running: `systemctl status crond`
- Check cron logs: `grep CRON /var/log/messages`
- Re-run setup: `./setup_cron.sh` or `./setup_mrtg_cron.sh`

### ❌ Speed tests failing
**Solution:**
- Check internet connectivity
- Verify speedtest-cli is installed: `pip list | grep speedtest`
- Check logs: `tail speedtest_cron.log`

---

## 📄 License

MIT License - feel free to use and modify as needed!

---

## 🤝 Contributing

Contributions are welcome! Please ensure all scripts remain idempotent and follow the existing code style.

---

**Made with ❤️ for network monitoring and speed testing**
