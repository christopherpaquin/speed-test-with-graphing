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
├── 📄 requirements.txt          # Python dependencies
├── 📄 vars.example              # Configuration template (committed to git)
├── 📄 vars                      # Your configuration (ignored by git)
│
├── 🔧 setup_all.sh              # Master setup script (runs all below)
├── 🔧 setup_mrtg.sh             # Sets up MRTG and Apache
├── 🔧 setup_cron.sh             # Sets up speedtest cron job
├── 🔧 setup_mrtg_cron.sh        # Sets up MRTG update cron job
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
