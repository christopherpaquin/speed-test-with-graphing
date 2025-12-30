#!/usr/bin/env python3
"""
MRTG-compatible speedtest data output script
Outputs data in MRTG format: value1, value2, uptime, system_name
This script calculates averages from JSON results for MRTG graphing
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Optional


class MRTGSpeedTest:
    def __init__(self, results_file: str = "speedtest_results.json"):
        # Convert to absolute path
        if os.path.isabs(results_file):
            self.results_path = results_file
        else:
            self.script_dir = os.path.dirname(os.path.abspath(__file__))
            self.results_path = os.path.join(self.script_dir, results_file)
        self.results_file = results_file
        
    def load_results(self) -> List[Dict]:
        """Load speed test results from JSON file"""
        if not os.path.exists(self.results_path):
            return []
        
        try:
            with open(self.results_path, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return []
    
    def calculate_average(self, metric: str, hours: int = 24) -> float:
        """
        Calculate average of a metric over the last N hours
        metric: 'download_mbps', 'upload_mbps', or 'ping_ms'
        """
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
    
    def output_mrtg_format(self, value1: float, value2: float = 0.0, 
                           uptime: str = "", system_name: str = ""):
        """
        Output in MRTG format:
        Line 1: value1 (integer)
        Line 2: value2 (integer)
        Line 3: uptime string
        Line 4: system name
        """
        print(int(value1))
        print(int(value2))
        print(uptime)
        print(system_name)


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='MRTG speedtest data output')
    parser.add_argument('--metric', '-m', required=True,
                       choices=['download', 'upload', 'ping'],
                       help='Metric to output: download, upload, or ping')
    parser.add_argument('--hours', type=int, default=24,
                       help='Hours of data to average (default: 24)')
    parser.add_argument('--results-file', default='speedtest_results.json',
                       help='Path to results JSON file')
    
    args = parser.parse_args()
    
    # Convert results file to absolute path if relative
    results_file = args.results_file
    if not os.path.isabs(results_file):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        results_file = os.path.join(script_dir, results_file)
    
    mrtg = MRTGSpeedTest(results_file)
    
    # Map metric names
    metric_map = {
        'download': 'download_mbps',
        'upload': 'upload_mbps',
        'ping': 'ping_ms'
    }
    
    metric_key = metric_map[args.metric]
    average_value = mrtg.calculate_average(metric_key, args.hours)
    
    # MRTG format: value1, value2, uptime, system_name
    # For speed tests, we use value1 for the metric, value2 as 0
    mrtg.output_mrtg_format(
        value1=average_value,
        value2=0.0,
        uptime="",
        system_name=f"Average {args.metric.capitalize()}"
    )


if __name__ == "__main__":
    main()

