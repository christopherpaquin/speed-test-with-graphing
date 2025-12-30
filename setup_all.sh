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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
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
log_info "Access your graphs at: http://10.1.10.53/mrtg/"
log_info ""
log_info "Speed tests will run every 10 minutes"
log_info "MRTG graphs will be updated every 5 minutes"

