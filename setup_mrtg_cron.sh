#!/bin/bash
#
# Idempotent script to set up cron job for MRTG updates
# Updates MRTG graphs every 5 minutes
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
MRTG_UPDATE_INTERVAL="${MRTG_UPDATE_INTERVAL:-5}"

MRTG_DIR="$PROJECT_DIR/mrtg"
MRTG_CFG_DIR="$MRTG_DIR/cfg"
MRTG_LOG_DIR="$MRTG_DIR/logs"
CRON_JOB="*/${MRTG_UPDATE_INTERVAL} * * * * env LANG=C /usr/bin/mrtg $MRTG_CFG_DIR/speedtest-download.cfg --logging $MRTG_LOG_DIR/speedtest-download.log > /dev/null 2>&1; env LANG=C /usr/bin/mrtg $MRTG_CFG_DIR/speedtest-upload.cfg --logging $MRTG_LOG_DIR/speedtest-upload.log > /dev/null 2>&1; env LANG=C /usr/bin/mrtg $MRTG_CFG_DIR/speedtest-ping.cfg --logging $MRTG_LOG_DIR/speedtest-ping.log > /dev/null 2>&1"
CRON_TAG="# mrtg-speedtest-update"

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

# Check if MRTG config files exist
if [ ! -f "$MRTG_CFG_DIR/speedtest-download.cfg" ]; then
    log_error "MRTG configuration files not found. Please run setup_mrtg.sh first."
    exit 1
fi

# Get current user (or use root if running as root)
if [ "$EUID" -eq 0 ]; then
    CRON_USER="root"
else
    CRON_USER=$(whoami)
fi

log_info "Setting up MRTG update cron job for user: $CRON_USER"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$CRON_TAG"; then
    log_info "MRTG cron job already exists, updating..."
    
    # Remove old cron job
    crontab -l 2>/dev/null | grep -v "$CRON_TAG" | grep -v "speedtest-.*\.cfg" | crontab - 2>/dev/null || true
fi

# Add new cron job
(crontab -l 2>/dev/null | grep -v "$CRON_TAG"; echo "$CRON_JOB $CRON_TAG") | crontab -

log_info "MRTG update cron job added successfully!"
log_info "MRTG graphs will be updated every $MRTG_UPDATE_INTERVAL minutes"

# Verify cron job was added
log_info "Current cron jobs for $CRON_USER:"
crontab -l 2>/dev/null | grep -A 1 -B 1 "$CRON_TAG" || log_warn "Could not verify cron job"

log_info "MRTG cron setup complete!"

