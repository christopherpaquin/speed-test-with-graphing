#!/bin/bash
#
# Idempotent script to set up cron job for speedtest
# Runs speedtest every 10 minutes
# This script can be run multiple times safely
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
SPEEDTEST_SCRIPT="$PROJECT_DIR/speedtest_runner.py"
CRON_JOB="*/10 * * * * cd $PROJECT_DIR && /usr/bin/python3 $SPEEDTEST_SCRIPT >> $PROJECT_DIR/speedtest_cron.log 2>&1"
CRON_TAG="# speedtest-with-graphing"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if speedtest script exists
if [ ! -f "$SPEEDTEST_SCRIPT" ]; then
    log_error "Speedtest script not found: $SPEEDTEST_SCRIPT"
    exit 1
fi

# Make script executable
chmod +x "$SPEEDTEST_SCRIPT"

# Get current user (or use root if running as root)
if [ "$EUID" -eq 0 ]; then
    CRON_USER="root"
    CRON_FILE="/var/spool/cron/root"
else
    CRON_USER=$(whoami)
    CRON_FILE="/var/spool/cron/$CRON_USER"
fi

log_info "Setting up cron job for user: $CRON_USER"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$CRON_TAG"; then
    log_info "Cron job already exists, updating..."
    
    # Remove old cron job
    crontab -l 2>/dev/null | grep -v "$CRON_TAG" | grep -v "$PROJECT_DIR/speedtest_runner.py" | crontab - 2>/dev/null || true
fi

# Add new cron job
(crontab -l 2>/dev/null | grep -v "$CRON_TAG"; echo "$CRON_JOB $CRON_TAG") | crontab -

log_info "Cron job added successfully!"
log_info "Speedtest will run every 10 minutes"
log_info "Logs will be written to: $PROJECT_DIR/speedtest_cron.log"

# Verify cron job was added
log_info "Current cron jobs for $CRON_USER:"
crontab -l 2>/dev/null | grep -A 1 -B 1 "$CRON_TAG" || log_warn "Could not verify cron job"

log_info "Cron setup complete!"

