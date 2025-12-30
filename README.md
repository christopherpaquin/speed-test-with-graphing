# Speed Test with MRTG Graphing

A Python application for testing internet speed and visualizing results using MRTG (Multi Router Traffic Grapher) with Apache.

## Features

- **Speed Testing**: Test download speed, upload speed, and ping/latency
- **Data Logging**: Save all test results to JSON for historical tracking
- **MRTG Graphing**: Generate graphs using MRTG served via Apache
- **Automated Testing**: Cron job runs speed tests every 10 minutes
- **Automated Graphing**: Cron job updates MRTG graphs every 5 minutes
- **Idempotent Setup**: All setup scripts can be run multiple times safely

## Installation

1. Install Python dependencies:
```bash
python3 -m pip install -r requirements.txt
```

2. Run the master setup script (requires root for Apache configuration):
```bash
sudo ./setup_all.sh
```

This will:
- Install MRTG and Apache (if not already installed)
- Configure MRTG for speedtest graphing
- Set up Apache to serve MRTG graphs
- Create cron jobs for automated testing and graph updates

## Individual Setup Scripts

You can also run setup scripts individually:

### Setup MRTG and Apache
```bash
sudo ./setup_mrtg.sh
```

### Setup Speedtest Cron Job (runs every 10 minutes)
```bash
./setup_cron.sh
```

### Setup MRTG Update Cron Job (updates graphs every 5 minutes)
```bash
./setup_mrtg_cron.sh
```

## Usage

### Manual Speed Test
```bash
python3 speedtest_runner.py
```

### View MRTG Graphs
After setup, graphs are available at:
- Main page: http://10.1.10.53/mrtg/
- Download speed: http://10.1.10.53/mrtg/speedtest-download.html
- Upload speed: http://10.1.10.53/mrtg/speedtest-upload.html
- Ping/Latency: http://10.1.10.53/mrtg/speedtest-ping.html

**Note:** Apache is configured to listen on IP address 10.1.10.53:80. The firewall is automatically configured to allow traffic on this IP and port.

### MRTG Data Script
The `mrtg_speedtest.py` script outputs data in MRTG format:
```bash
python3 mrtg_speedtest.py --metric download
python3 mrtg_speedtest.py --metric upload
python3 mrtg_speedtest.py --metric ping
```

## Project Structure

- `speedtest_runner.py` - Runs speed tests and saves to JSON
- `mrtg_speedtest.py` - Outputs speedtest data in MRTG format
- `setup_mrtg.sh` - Sets up MRTG and Apache (idempotent)
- `setup_cron.sh` - Sets up speedtest cron job (idempotent)
- `setup_mrtg_cron.sh` - Sets up MRTG update cron job (idempotent)
- `setup_all.sh` - Master setup script (runs all above)
- `speedtest_results.json` - JSON file containing all test results
- `mrtg/` - MRTG directory structure
  - `cfg/` - MRTG configuration files
  - `html/` - Generated HTML and graph files
  - `logs/` - MRTG log files
  - `work/` - MRTG working directory

## Data Format

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

## MRTG Configuration

MRTG graphs show:
- **Average Download Speed** (Mbps) - averaged over last 24 hours
- **Average Upload Speed** (Mbps) - averaged over last 24 hours
- **Average Ping** (ms) - averaged over last 24 hours

Graphs are updated every 5 minutes via cron job.

## Cron Jobs

The setup scripts create the following cron jobs:

1. **Speedtest** (every 10 minutes):
   ```
   */10 * * * * cd /opt/projects/speed-test-with-graphing && /usr/bin/python3 speedtest_runner.py >> speedtest_cron.log 2>&1
   ```

2. **MRTG Update** (every 5 minutes):
   ```
   */5 * * * * /usr/bin/mrtg [config files] > /dev/null 2>&1
   ```

## Idempotency

All setup scripts are idempotent, meaning they can be run multiple times safely:
- They check for existing configurations before creating new ones
- They update existing configurations if needed
- They won't create duplicate cron jobs
- They won't break if components are already installed

## Requirements

- Python 3.7+
- Internet connection
- Root/sudo access (for Apache and MRTG setup)
- Required packages (see `requirements.txt`)
- MRTG (installed by setup script)
- Apache (installed by setup script)

## Troubleshooting

### Check if cron jobs are running:
```bash
crontab -l
```

### Check speedtest logs:
```bash
tail -f speedtest_cron.log
```

### Check MRTG logs:
```bash
tail -f mrtg/logs/speedtest-*.log
```

### Test MRTG data script:
```bash
python3 mrtg_speedtest.py --metric download
```

### Restart Apache:
```bash
sudo systemctl restart httpd  # RHEL/CentOS
sudo systemctl restart apache2  # Debian/Ubuntu
```

## License

MIT
