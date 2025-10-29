#!/bin/bash
# ==========================================================
# Script: deploy_squid.sh
# Purpose: Install and configure Squid Proxy Server
# Author: Your Name
# Usage: bash deploy_squid.sh
# ==========================================================

set -e  # Exit immediately on error

# ---- Detect OS and install Squid ----
echo "[INFO] Detecting operating system..."
if command -v apt-get &>/dev/null; then
    echo "[INFO] Installing Squid on Ubuntu/Debian..."
    sudo apt-get update -y
    sudo apt-get install -y squid
elif command -v yum &>/dev/null; then
    echo "[INFO] Installing Squid on Amazon Linux/CentOS..."
    sudo yum update -y
    sudo yum install -y squid
else
    echo "[ERROR] Unsupported OS. Exiting..."
    exit 1
fi

# ---- Enable and start Squid ----
echo "[INFO] Enabling and starting Squid service..."
sudo systemctl enable squid
sudo systemctl start squid

# ---- Basic configuration ----
SQUID_CONF="/etc/squid/squid.conf"

echo "[INFO] Backing up default configuration..."
sudo cp $SQUID_CONF ${SQUID_CONF}.backup.$(date +%F-%H%M%S)

echo "[INFO] Applying basic configuration..."
sudo bash -c "cat > $SQUID_CONF" <<'EOF'
# =========================================
# Custom Squid Proxy Configuration
# =========================================

# Listen on default port
http_port 3128

# Allow local network (adjust as needed)
acl localnet src 10.0.0.0/8     # Internal network
acl localnet src 172.16.0.0/12  # Internal network
acl localnet src 192.168.0.0/16 # Internal network

# Allow localhost
acl localhost src 127.0.0.1/32 ::1

# Safe HTTP access control
http_access allow localhost
http_access allow localnet

# Deny all other access
http_access deny all

# Logging
access_log /var/log/squid/access.log

# Performance tuning
cache_mem 256 MB
maximum_object_size_in_memory 1 MB
maximum_object_size 1024 MB
cache_dir ufs /var/spool/squid 10000 16 256

# Header privacy
via off
forwarded_for off
EOF

# ---- Restart service ----
echo "[INFO] Restarting Squid with new configuration..."
sudo systemctl restart squid

# ---- Verify service ----
echo "[INFO] Checking Squid service status..."
sudo systemctl status squid --no-pager

# ---- Display proxy info ----
echo "=========================================================="
echo "[SUCCESS] Squid Proxy Server deployed successfully!"
echo "Proxy listening on: http://$(curl -s ifconfig.me):3128"
echo "Configuration file: $SQUID_CONF"
echo "=========================================================="
