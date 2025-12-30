#!/usr/bin/env python3
"""
Speed Test Runner - Performs internet speed tests and logs results
"""

import speedtest
import json
import os
from datetime import datetime, timezone
from typing import Dict, Optional


class SpeedTestRunner:
    def __init__(self, results_file: str = "speedtest_results.json"):
        # Use absolute path for cron compatibility
        if not os.path.isabs(results_file):
            script_dir = os.path.dirname(os.path.abspath(__file__))
            self.results_file = os.path.join(script_dir, results_file)
        else:
            self.results_file = results_file
        self.st = speedtest.Speedtest()
        
    def run_test(self) -> Dict:
        """Run a speed test and return results"""
        print("Selecting best server...")
        self.st.get_best_server()
        
        print("Testing download speed...")
        download_speed = self.st.download() / 1_000_000  # Convert to Mbps
        
        print("Testing upload speed...")
        upload_speed = self.st.upload() / 1_000_000  # Convert to Mbps
        
        results = self.st.results.dict()
        
        test_result = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "download_mbps": round(download_speed, 2),
            "upload_mbps": round(upload_speed, 2),
            "ping_ms": round(results.get("ping", 0), 2),
            "server": {
                "name": results.get("server", {}).get("name", "Unknown"),
                "location": results.get("server", {}).get("location", "Unknown"),
                "country": results.get("server", {}).get("country", "Unknown")
            }
        }
        
        return test_result
    
    def save_result(self, result: Dict) -> None:
        """Save test result to JSON file"""
        results = []
        
        # Load existing results if file exists
        if os.path.exists(self.results_file):
            with open(self.results_file, 'r') as f:
                results = json.load(f)
        
        # Append new result
        results.append(result)
        
        # Save updated results
        with open(self.results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"Result saved to {self.results_file}")
    
    def run_and_save(self) -> Dict:
        """Run test and save result"""
        result = self.run_test()
        self.save_result(result)
        return result


if __name__ == "__main__":
    import sys
    
    runner = SpeedTestRunner()
    
    try:
        result = runner.run_and_save()
        
        print("\n" + "="*50)
        print("Speed Test Results:")
        print("="*50)
        print(f"Download: {result['download_mbps']} Mbps")
        print(f"Upload: {result['upload_mbps']} Mbps")
        print(f"Ping: {result['ping_ms']} ms")
        print(f"Server: {result['server']['name']} ({result['server']['location']})")
        print(f"Timestamp: {result['timestamp']}")
        print("="*50)
        
    except Exception as e:
        print(f"Error running speed test: {e}", file=sys.stderr)
        sys.exit(1)

