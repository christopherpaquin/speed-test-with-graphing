#!/usr/bin/env python3
"""
Zabbix speedtest data provider script
Returns speedtest metrics for Zabbix monitoring
Usage: zbx-speedtest.py <metric_name>
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Optional


class ZabbixSpeedTest:
    def __init__(self, results_file: str = "speedtest_results.json"):
        # Use absolute path for cron compatibility
        if not os.path.isabs(results_file):
            script_dir = os.path.dirname(os.path.abspath(__file__))
            # If script is in /usr/local/bin, look for JSON in project directory
            if script_dir == "/usr/local/bin":
                # Try common project locations
                project_dirs = [
                    "/opt/projects/speed-test-with-graphing",
                    os.path.expanduser("~/speed-test-with-graphing"),
                    "/opt/speed-test-with-graphing"
                ]
                for project_dir in project_dirs:
                    potential_file = os.path.join(project_dir, results_file)
                    if os.path.exists(potential_file):
                        self.results_file = potential_file
                        break
                else:
                    # Fallback to script directory if project not found
                    self.results_file = os.path.join(script_dir, results_file)
            else:
                self.results_file = os.path.join(script_dir, results_file)
        else:
            self.results_file = results_file
    
    def load_results(self) -> List[Dict]:
        """Load speed test results from JSON file"""
        if not os.path.exists(self.results_file):
            return []
        
        try:
            with open(self.results_file, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return []
    
    def get_latest(self, metric: str) -> float:
        """Get the latest value for a metric"""
        results = self.load_results()
        if not results:
            return 0.0
        
        # Get the most recent result
        latest = results[-1]
        return float(latest.get(metric, 0.0))
    
    def get_average(self, metric: str, hours: int = 24) -> float:
        """Calculate average of a metric over the last N hours"""
        results = self.load_results()
        
        if not results:
            return 0.0
        
        # Filter results from last N hours (using UTC)
        cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours)
        recent_results = []
        
        for result in results:
            try:
                # Parse timestamp - handle both timezone-aware and naive timestamps
                ts_str = result['timestamp']
                if 'Z' in ts_str or '+' in ts_str or (ts_str.count('-') > 2 and ('+' in ts_str or ts_str.endswith('Z'))):
                    # Timezone-aware timestamp (has Z or timezone offset)
                    timestamp = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
                else:
                    # Naive timestamp - assume local timezone (for backward compatibility with old data)
                    # then convert to UTC for consistent comparison
                    naive_dt = datetime.fromisoformat(ts_str)
                    # Assume naive timestamps are in local timezone, convert to UTC
                    local_tz = datetime.now().astimezone().tzinfo
                    timestamp = naive_dt.replace(tzinfo=local_tz).astimezone(timezone.utc)
                
                if timestamp >= cutoff_time:
                    recent_results.append(result.get(metric, 0))
            except (KeyError, ValueError):
                continue
        
        if not recent_results:
            return 0.0
        
        return sum(recent_results) / len(recent_results)
    
    def get_test_count(self, hours: int = 24) -> int:
        """Get count of tests in the last N hours"""
        results = self.load_results()
        
        if not results:
            return 0
        
        cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours)
        count = 0
        
        for result in results:
            try:
                # Parse timestamp - handle both timezone-aware and naive timestamps
                ts_str = result['timestamp']
                if 'Z' in ts_str or '+' in ts_str or (ts_str.count('-') > 2 and ('+' in ts_str or ts_str.endswith('Z'))):
                    # Timezone-aware timestamp (has Z or timezone offset)
                    timestamp = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
                else:
                    # Naive timestamp - assume local timezone (for backward compatibility with old data)
                    # then convert to UTC for consistent comparison
                    naive_dt = datetime.fromisoformat(ts_str)
                    # Assume naive timestamps are in local timezone, convert to UTC
                    local_tz = datetime.now().astimezone().tzinfo
                    timestamp = naive_dt.replace(tzinfo=local_tz).astimezone(timezone.utc)
                
                if timestamp >= cutoff_time:
                    count += 1
            except (KeyError, ValueError):
                continue
        
        return count
    
    def get_last_test_time(self) -> int:
        """Get Unix timestamp of last test (UTC)"""
        results = self.load_results()
        if not results:
            return 0
        
        try:
            latest = results[-1]
            # Parse timestamp - handle both timezone-aware and naive timestamps
            ts_str = latest['timestamp']
            if 'Z' in ts_str or '+' in ts_str or (ts_str.count('-') > 2 and ('+' in ts_str or ts_str.endswith('Z'))):
                # Timezone-aware timestamp (has Z or timezone offset)
                timestamp = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
            else:
                # Naive timestamp - assume local timezone (for backward compatibility with old data)
                # then convert to UTC for consistent Unix timestamp
                naive_dt = datetime.fromisoformat(ts_str)
                # Assume naive timestamps are in local timezone, convert to UTC
                local_tz = datetime.now().astimezone().tzinfo
                timestamp = naive_dt.replace(tzinfo=local_tz).astimezone(timezone.utc)
            
            # Unix timestamp is always UTC, so this is correct
            return int(timestamp.timestamp())
        except (KeyError, ValueError):
            return 0
    
    def get_server_info(self, field: str) -> str:
        """Get server information from latest test"""
        results = self.load_results()
        if not results:
            return ""
        
        try:
            latest = results[-1]
            server = latest.get('server', {})
            return str(server.get(field, ""))
        except (KeyError, ValueError):
            return ""


def main():
    if len(sys.argv) != 2:
        print("Usage: zbx-speedtest.py <metric_name>", file=sys.stderr)
        sys.exit(1)
    
    metric = sys.argv[1]
    zbx = ZabbixSpeedTest()
    
    # Map metric names to functions
    metric_map = {
        'speedtest.download': lambda: zbx.get_latest('download_mbps'),
        'speedtest.upload': lambda: zbx.get_latest('upload_mbps'),
        'speedtest.ping': lambda: zbx.get_latest('ping_ms'),
        'speedtest.download_avg_24h': lambda: zbx.get_average('download_mbps', 24),
        'speedtest.upload_avg_24h': lambda: zbx.get_average('upload_mbps', 24),
        'speedtest.ping_avg_24h': lambda: zbx.get_average('ping_ms', 24),
        'speedtest.test_count_24h': lambda: zbx.get_test_count(24),
        'speedtest.last_test_time': lambda: zbx.get_last_test_time(),
        'speedtest.server_name': lambda: zbx.get_server_info('name'),
        'speedtest.server_location': lambda: zbx.get_server_info('location'),
        'speedtest.server_country': lambda: zbx.get_server_info('country'),
    }
    
    if metric not in metric_map:
        print(f"Unknown metric: {metric}", file=sys.stderr)
        print(f"Available metrics: {', '.join(metric_map.keys())}", file=sys.stderr)
        sys.exit(1)
    
    try:
        value = metric_map[metric]()
        # For numeric values, format without decimals if integer
        if isinstance(value, float):
            if value.is_integer():
                print(int(value))
            else:
                print(f"{value:.2f}")
        else:
            print(value)
    except Exception as e:
        print(f"Error getting metric {metric}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

