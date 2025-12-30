#!/bin/bash
#
# Idempotent script to set up MRTG for speedtest graphing
# This script can be run multiple times safely
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Load configuration from vars file (required)
if [ ! -f "$PROJECT_DIR/vars" ]; then
    echo "Error: vars file not found!"
    echo "Please copy vars.example to vars and configure your settings:"
    echo "  cp vars.example vars"
    echo "  # Then edit vars with your IP address and settings"
    exit 1
fi

source "$PROJECT_DIR/vars"

# Validate required variables
if [ -z "$APACHE_LISTEN_IP" ] || [ "$APACHE_LISTEN_IP" = "YOUR_IP_ADDRESS" ]; then
    echo "Error: APACHE_LISTEN_IP not configured in vars file!"
    echo "Please edit vars and set APACHE_LISTEN_IP to your IP address."
    exit 1
fi

# Set defaults for optional variables
APACHE_LISTEN_PORT="${APACHE_LISTEN_PORT:-80}"

MRTG_DIR="$PROJECT_DIR/mrtg"
MRTG_CFG_DIR="$MRTG_DIR/cfg"
MRTG_HTML_DIR="$MRTG_DIR/html"
MRTG_LOG_DIR="$MRTG_DIR/logs"
MRTG_WORK_DIR="$MRTG_DIR/work"

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run as root (for Apache configuration)"
    exit 1
fi

# Check if MRTG is installed
if ! command -v mrtg &> /dev/null; then
    log_info "MRTG not found. Installing MRTG..."
    if command -v yum &> /dev/null; then
        yum install -y mrtg
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y mrtg
    else
        log_error "Cannot determine package manager. Please install MRTG manually."
        exit 1
    fi
else
    log_info "MRTG is already installed"
fi

# Create MRTG directories
log_info "Creating MRTG directories..."
mkdir -p "$MRTG_CFG_DIR"
mkdir -p "$MRTG_HTML_DIR"
mkdir -p "$MRTG_LOG_DIR"
mkdir -p "$MRTG_WORK_DIR"

# Make the Python script executable
chmod +x "$PROJECT_DIR/mrtg_speedtest.py"

# Generate MRTG configuration files
log_info "Generating MRTG configuration files..."

# Download speed configuration
cat > "$MRTG_CFG_DIR/speedtest-download.cfg" <<EOF
WorkDir: $MRTG_HTML_DIR
HtmlDir: $MRTG_HTML_DIR
ImageDir: $MRTG_HTML_DIR
LogDir: $MRTG_LOG_DIR

Target[download]: \`$PROJECT_DIR/mrtg_speedtest.py --metric download --results-file $PROJECT_DIR/speedtest_results.json\`
Title[download]: Speed Test - Average Download Speed
PageTop[download]: <H1>Speed Test - Average Download Speed (Mbps)</H1>
Options[download]: gauge, nopercent, growright, unknaszero, noinfo
MaxBytes[download]: 1000
YLegend[download]: Download Speed (Mbps)
ShortLegend[download]: Mbps
LegendI[download]: Average Download:
LegendO[download]: 
Legend1[download]: Average Download Speed
Legend2[download]: 
kMG[download]: ,k,M,G,T,P
kilo[download]: 1000
Language: english
EOF

# Upload speed configuration
cat > "$MRTG_CFG_DIR/speedtest-upload.cfg" <<EOF
WorkDir: $MRTG_HTML_DIR
HtmlDir: $MRTG_HTML_DIR
ImageDir: $MRTG_HTML_DIR
LogDir: $MRTG_LOG_DIR

Target[upload]: \`$PROJECT_DIR/mrtg_speedtest.py --metric upload --results-file $PROJECT_DIR/speedtest_results.json\`
Title[upload]: Speed Test - Average Upload Speed
PageTop[upload]: <H1>Speed Test - Average Upload Speed (Mbps)</H1>
Options[upload]: gauge, nopercent, growright, unknaszero, noinfo
MaxBytes[upload]: 1000
YLegend[upload]: Upload Speed (Mbps)
ShortLegend[upload]: Mbps
LegendI[upload]: Average Upload:
LegendO[upload]: 
Legend1[upload]: Average Upload Speed
Legend2[upload]: 
kMG[upload]: ,k,M,G,T,P
kilo[upload]: 1000
Language: english
EOF

# Ping configuration
cat > "$MRTG_CFG_DIR/speedtest-ping.cfg" <<EOF
WorkDir: $MRTG_HTML_DIR
HtmlDir: $MRTG_HTML_DIR
ImageDir: $MRTG_HTML_DIR
LogDir: $MRTG_LOG_DIR

Target[ping]: \`$PROJECT_DIR/mrtg_speedtest.py --metric ping --results-file $PROJECT_DIR/speedtest_results.json\`
Title[ping]: Speed Test - Average Ping
PageTop[ping]: <H1>Speed Test - Average Ping (ms)</H1>
Options[ping]: gauge, nopercent, growright, unknaszero, noinfo
MaxBytes[ping]: 1000
YLegend[ping]: Ping (ms)
ShortLegend[ping]: ms
LegendI[ping]: Average Ping:
LegendO[ping]: 
Legend1[ping]: Average Ping
Legend2[ping]: 
kMG[ping]: ,k,M,G,T,P
kilo[ping]: 1000
Language: english
EOF

log_info "MRTG configuration files created"

# Check if Apache is installed
if ! command -v httpd &> /dev/null && ! command -v apache2 &> /dev/null; then
    log_warn "Apache not found. Installing Apache..."
    if command -v yum &> /dev/null; then
        yum install -y httpd
        APACHE_SERVICE="httpd"
        APACHE_CONF_DIR="/etc/httpd/conf.d"
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y apache2
        APACHE_SERVICE="apache2"
        APACHE_CONF_DIR="/etc/apache2/conf-available"
    else
        log_error "Cannot determine package manager. Please install Apache manually."
        exit 1
    fi
else
    if command -v httpd &> /dev/null; then
        APACHE_SERVICE="httpd"
        APACHE_CONF_DIR="/etc/httpd/conf.d"
    else
        APACHE_SERVICE="apache2"
        APACHE_CONF_DIR="/etc/apache2/conf-available"
    fi
    log_info "Apache is already installed"
fi

# Configure Apache to listen on specific IP
log_info "Configuring Apache to listen on $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT..."

if [ "$APACHE_SERVICE" = "httpd" ]; then
    # RHEL/CentOS - configure in main config or conf.d
    APACHE_MAIN_CONF="/etc/httpd/conf/httpd.conf"
    APACHE_LISTEN_CONF="$APACHE_CONF_DIR/speedtest-listen.conf"
    
    # Check if Listen directive already exists for this IP
    if ! grep -q "Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" "$APACHE_MAIN_CONF" 2>/dev/null && \
       ! grep -q "Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" "$APACHE_LISTEN_CONF" 2>/dev/null; then
        # Comment out default Listen 80 if it exists (to avoid conflicts)
        if grep -q "^Listen 80$" "$APACHE_MAIN_CONF" 2>/dev/null; then
            sed -i 's/^Listen 80$/#Listen 80  # Commented out for speedtest MRTG/' "$APACHE_MAIN_CONF"
            log_info "Commented out default Listen 80 to avoid conflicts"
        fi
        
        # Add Listen directive in conf.d (preferred method)
        cat > "$APACHE_LISTEN_CONF" <<EOF
# Speedtest MRTG - Listen on specific IP
Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT
EOF
        log_info "Added Listen directive for $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT"
    else
        log_info "Apache already configured to listen on $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT"
    fi
else
    # Debian/Ubuntu - configure in ports.conf or apache2.conf
    APACHE_PORTS_CONF="/etc/apache2/ports.conf"
    APACHE_LISTEN_CONF="/etc/apache2/conf-available/speedtest-listen.conf"
    
    # Check if Listen directive already exists
    if ! grep -q "Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" "$APACHE_PORTS_CONF" 2>/dev/null && \
       ! grep -q "Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" "$APACHE_LISTEN_CONF" 2>/dev/null; then
        # Add to ports.conf or create separate config
        if [ -f "$APACHE_PORTS_CONF" ]; then
            if ! grep -q "^Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" "$APACHE_PORTS_CONF"; then
                echo "Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" >> "$APACHE_PORTS_CONF"
                log_info "Added Listen directive to ports.conf"
            fi
        else
            cat > "$APACHE_LISTEN_CONF" <<EOF
# Speedtest MRTG - Listen on specific IP
Listen $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT
EOF
            # Enable the config
            if [ -d "/etc/apache2/conf-enabled" ]; then
                ln -sf "$APACHE_LISTEN_CONF" "/etc/apache2/conf-enabled/speedtest-listen.conf"
            fi
            log_info "Created Listen configuration file"
        fi
    else
        log_info "Apache already configured to listen on $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT"
    fi
fi

# Disable default MRTG config if it exists (it has Require local which blocks remote access)
if [ -f "$APACHE_CONF_DIR/mrtg.conf" ]; then
    log_info "Disabling default MRTG config (it restricts access to localhost only)..."
    mv "$APACHE_CONF_DIR/mrtg.conf" "$APACHE_CONF_DIR/mrtg.conf.disabled" 2>/dev/null || true
fi

# Create Apache configuration for MRTG
APACHE_CONF_FILE="$APACHE_CONF_DIR/speedtest-mrtg.conf"
log_info "Creating Apache configuration..."

if [ -f "$APACHE_CONF_FILE" ]; then
    log_info "Apache configuration already exists, updating..."
fi

cat > "$APACHE_CONF_FILE" <<EOF
# Speedtest MRTG Configuration
<VirtualHost $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT>
    ServerName $APACHE_LISTEN_IP
    Alias /mrtg "$MRTG_HTML_DIR"

    <Directory "$MRTG_HTML_DIR">
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable configuration (for Debian/Ubuntu)
if [ "$APACHE_SERVICE" = "apache2" ]; then
    if [ -d "/etc/apache2/conf-enabled" ]; then
        ln -sf "$APACHE_CONF_FILE" "/etc/apache2/conf-enabled/speedtest-mrtg.conf"
    fi
fi

# Set proper permissions
log_info "Setting permissions..."
chown -R apache:apache "$MRTG_DIR" 2>/dev/null || chown -R www-data:www-data "$MRTG_DIR" 2>/dev/null || true
chmod -R 755 "$MRTG_DIR"
# Ensure log files are writable (MRTG creates .log and .old files in WorkDir)
chmod 664 "$MRTG_HTML_DIR"/*.log "$MRTG_HTML_DIR"/*.old 2>/dev/null || true
chown apache:apache "$MRTG_HTML_DIR"/*.log "$MRTG_HTML_DIR"/*.old 2>/dev/null || chown www-data:www-data "$MRTG_HTML_DIR"/*.log "$MRTG_HTML_DIR"/*.old 2>/dev/null || true

# Set SELinux context if SELinux is enabled
if command -v getenforce &> /dev/null && [ "$(getenforce)" != "Disabled" ]; then
    log_info "Configuring SELinux context..."
    # Set httpd_sys_content_t context for the MRTG directory
    if command -v semanage &> /dev/null; then
        semanage fcontext -a -t httpd_sys_content_t "$MRTG_DIR(/.*)?" 2>/dev/null || true
        restorecon -Rv "$MRTG_DIR" 2>/dev/null || true
    elif command -v chcon &> /dev/null; then
        chcon -R -t httpd_sys_content_t "$MRTG_DIR" 2>/dev/null || true
    fi
    log_info "SELinux context configured"
fi

# Create index.html in MRTG HTML directory
# Note: MRTG generates files based on Target name, so "download" becomes "download.html"
cat > "$MRTG_HTML_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Speed Test MRTG Graphs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .graph-link { display: inline-block; margin: 10px; padding: 10px; background: #f0f0f0; border-radius: 5px; }
        .graph-link a { text-decoration: none; color: #0066cc; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Speed Test MRTG Graphs</h1>
    <div class="graph-link"><a href="download.html">Download Speed</a></div>
    <div class="graph-link"><a href="upload.html">Upload Speed</a></div>
    <div class="graph-link"><a href="ping.html">Ping/Latency</a></div>
</body>
</html>
EOF
# Set ownership and permissions for index.html
chown apache:apache "$MRTG_HTML_DIR/index.html" 2>/dev/null || chown www-data:www-data "$MRTG_HTML_DIR/index.html" 2>/dev/null || true
chmod 644 "$MRTG_HTML_DIR/index.html"

# Test Apache configuration
log_info "Testing Apache configuration..."
if "$APACHE_SERVICE" -t 2>/dev/null || apache2ctl -t 2>/dev/null; then
    log_info "Apache configuration is valid"
    
    # Restart Apache
    log_info "Restarting Apache..."
    systemctl restart "$APACHE_SERVICE" 2>/dev/null || service "$APACHE_SERVICE" restart 2>/dev/null || true
    
    # Enable Apache to start on boot
    systemctl enable "$APACHE_SERVICE" 2>/dev/null || true
else
    log_error "Apache configuration test failed!"
    exit 1
fi

# Configure firewall
log_info "Configuring firewall to allow traffic on $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT..."

# Detect firewall type
if command -v firewall-cmd &> /dev/null; then
    # firewalld (RHEL/CentOS 7+)
    log_info "Detected firewalld, configuring rules..."
    
    # Check if rule already exists
    if firewall-cmd --list-all 2>/dev/null | grep -q "$APACHE_LISTEN_IP:$APACHE_LISTEN_PORT" || \
       firewall-cmd --list-all 2>/dev/null | grep -q "http"; then
        log_info "Firewall rule may already exist, ensuring it's active..."
    fi
    
    # Add HTTP service (if not already added)
    firewall-cmd --permanent --add-service=http 2>/dev/null || true
    
    # Add rich rule for specific IP (optional, but more specific)
    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='0.0.0.0/0' port port='$APACHE_LISTEN_PORT' protocol='tcp' accept" 2>/dev/null || true
    
    # Reload firewall
    firewall-cmd --reload 2>/dev/null || true
    log_info "firewalld configured"
    
elif command -v ufw &> /dev/null; then
    # ufw (Ubuntu/Debian)
    log_info "Detected ufw, configuring rules..."
    
    # Allow HTTP
    ufw allow 80/tcp 2>/dev/null || true
    log_info "ufw configured to allow HTTP traffic"
    
elif command -v iptables &> /dev/null; then
    # iptables (older systems)
    log_info "Detected iptables, configuring rules..."
    
    # Check if rule already exists
    if ! iptables -C INPUT -p tcp --dport $APACHE_LISTEN_PORT -j ACCEPT 2>/dev/null; then
        iptables -I INPUT -p tcp --dport $APACHE_LISTEN_PORT -j ACCEPT
        log_info "Added iptables rule for port $APACHE_LISTEN_PORT"
        
        # Try to save rules (varies by distribution)
        if command -v iptables-save &> /dev/null; then
            if [ -f "/etc/sysconfig/iptables" ]; then
                iptables-save > /etc/sysconfig/iptables 2>/dev/null || true
            elif [ -d "/etc/iptables" ]; then
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
            fi
        fi
    else
        log_info "iptables rule already exists"
    fi
else
    log_warn "No firewall management tool detected (firewalld, ufw, or iptables)"
    log_warn "Please manually configure firewall to allow traffic on $APACHE_LISTEN_IP:$APACHE_LISTEN_PORT"
fi

# Run initial MRTG update to create log files
log_info "Running initial MRTG update..."
for cfg in download upload ping; do
    env LANG=C mrtg "$MRTG_CFG_DIR/speedtest-$cfg.cfg" --logging "$MRTG_LOG_DIR/speedtest-$cfg.log" 2>&1 | head -20 || true
done

log_info "MRTG setup complete!"
log_info "MRTG graphs will be available at: http://$APACHE_LISTEN_IP:$APACHE_LISTEN_PORT/mrtg/"
log_info "Individual graphs:"
log_info "  - Download: http://$APACHE_LISTEN_IP:$APACHE_LISTEN_PORT/mrtg/speedtest-download.html"
log_info "  - Upload: http://$APACHE_LISTEN_IP:$APACHE_LISTEN_PORT/mrtg/speedtest-upload.html"
log_info "  - Ping: http://$APACHE_LISTEN_IP:$APACHE_LISTEN_PORT/mrtg/speedtest-ping.html"

