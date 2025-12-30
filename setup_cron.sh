#!/bin/bash
#
# Idempotent script to set up cron job for speedtest
# Runs speedtest every 10 minutes
# This script can be run multiple times safely
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Load configuration from vars file if it exists
if [ -f "$PROJECT_DIR/vars" ]; then
    source "$PROJECT_DIR/vars"
fi

# Set defaults if not set in vars file
SPEEDTEST_INTERVAL="${SPEEDTEST_INTERVAL:-10}"

SPEEDTEST_SCRIPT="$PROJECT_DIR/speedtest_runner.py"
CRON_JOB="*/${SPEEDTEST_INTERVAL} * * * * cd $PROJECT_DIR && /usr/bin/python3 $SPEEDTEST_SCRIPT >> $PROJECT_DIR/speedtest_cron.log 2>&1"
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
TEMP_CRON=$(mktemp) || {
    log_error "Failed to create temporary file"
    exit 1
}
(crontab -l 2>/dev/null | grep -v "$CRON_TAG" | grep -v "speedtest_runner.py"; echo "$CRON_JOB $CRON_TAG") > "$TEMP_CRON" || {
    log_error "Failed to write to temporary file"
    rm -f "$TEMP_CRON"
    exit 1
}
crontab "$TEMP_CRON" || {
    log_error "Failed to install crontab"
    rm -f "$TEMP_CRON"
    exit 1
}
rm -f "$TEMP_CRON"

log_info "Cron job added successfully!"
log_info "Speedtest will run every $SPEEDTEST_INTERVAL minutes"
log_info "Logs will be written to: $PROJECT_DIR/speedtest_cron.log"

# Verify cron job was added
log_info "Verifying cron job was added..."
if crontab -l 2>/dev/null | grep -q "speedtest_runner.py"; then
    log_info "✓ Cron job verified successfully!"
    log_info "Current cron job:"
    crontab -l 2>/dev/null | grep "speedtest_runner.py"
else
    log_warn "Could not verify cron job - please check manually with: crontab -l"
fi

log_info "Cron setup complete!"

