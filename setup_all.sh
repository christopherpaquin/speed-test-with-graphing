#!/bin/bash
#
# Master setup script - runs all setup scripts in order
# This script is idempotent and can be run multiple times safely
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_section "Setting up Speed Test with MRTG Graphing"

# Step 1: Setup MRTG
log_section "Step 1: Setting up MRTG"
bash "$SCRIPT_DIR/setup_mrtg.sh"

# Step 2: Setup speedtest cron job
log_section "Step 2: Setting up speedtest cron job"
bash "$SCRIPT_DIR/setup_cron.sh"

# Step 3: Setup MRTG update cron job
log_section "Step 3: Setting up MRTG update cron job"
bash "$SCRIPT_DIR/setup_mrtg_cron.sh"

log_section "Setup Complete!"
log_info "All components have been set up successfully."
log_info ""

# Load vars file to show configured IP (required)
if [ ! -f "$SCRIPT_DIR/vars" ]; then
    log_error "vars file not found!"
    log_info "Please copy vars.example to vars and configure your settings:"
    log_info "  cp vars.example vars"
    log_info "  # Then edit vars with your IP address and settings"
    exit 1
fi

source "$SCRIPT_DIR/vars"

# Validate required variables
if [ -z "$APACHE_LISTEN_IP" ] || [ "$APACHE_LISTEN_IP" = "YOUR_IP_ADDRESS" ]; then
    log_error "APACHE_LISTEN_IP not configured in vars file!"
    log_info "Please edit vars and set APACHE_LISTEN_IP to your IP address."
    exit 1
fi

# Set defaults for optional variables
APACHE_LISTEN_PORT="${APACHE_LISTEN_PORT:-80}"
SPEEDTEST_INTERVAL="${SPEEDTEST_INTERVAL:-10}"
MRTG_UPDATE_INTERVAL="${MRTG_UPDATE_INTERVAL:-5}"

log_info "Access your graphs at: http://${APACHE_LISTEN_IP}:${APACHE_LISTEN_PORT}/mrtg/"
log_info ""
log_info "Speed tests will run every $SPEEDTEST_INTERVAL minutes"
log_info "MRTG graphs will be updated every $MRTG_UPDATE_INTERVAL minutes"

