#!/bin/bash

# Exit on any error
set -e

# Step 1: Update the system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Check if Nginx is already installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing Nginx..."
    sudo apt install nginx -y
else
    echo "Nginx is already installed."
fi

# Step 3: Verify Nginx directories and files
echo "Checking Nginx directories and configuration files..."
if [ ! -d "/etc/nginx" ]; then
    echo "Error: /etc/nginx directory does not exist!"
    exit 1
fi
if [ ! -f "/etc/nginx/nginx.conf" ]; then
    echo "Error: /etc/nginx/nginx.conf file does not exist!"
    exit 1
fi
echo "Nginx directories and configuration files are present."

# Step 4: Start and enable Nginx service
echo "Starting and enabling Nginx service..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Step 5: Verify Nginx service status
echo "Checking Nginx service status..."
if systemctl is-active --quiet nginx; then
    echo "Nginx is running."
else
    echo "Error: Nginx is not running!"
    exit 1
fi

# Step 6: Verify Nginx default page
echo "Checking Nginx default page..."
if curl -s http://localhost | grep -q "Welcome to nginx!"; then
    echo "Nginx default page is accessible."
else
    echo "Error: Nginx default page is not accessible!"
    exit 1
fi

# Step 7: Configure stub_status module
echo "Configuring Nginx stub_status module..."
STUB_STATUS_CONF="/etc/nginx/conf.d/stub_status.conf"
if [ ! -f "$STUB_STATUS_CONF" ]; then
    echo "Creating stub_status configuration..."
    sudo bash -c "cat > $STUB_STATUS_CONF" << 'EOF'
server {
    listen 8080;
    server_name localhost;
    location /stub_status {
        stub_status on;
        allow 127.0.0.1;
        deny all;
    }
}
EOF
else
    echo "stub_status configuration already exists."
fi

# Step 8: Test Nginx configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "Nginx configuration is valid."
else
    echo "Error: Nginx configuration test failed!"
    exit 1
fi

# Step 9: Restart Nginx to apply stub_status configuration
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Step 10: Verify stub_status endpoint
echo "Checking stub_status endpoint..."
if curl -s http://localhost:8080/stub_status | grep -q "Active connections"; then
    echo "stub_status endpoint is working."
else
    echo "Error: stub_status endpoint is not accessible!"
    exit 1
fi

# Step 11: Install Nginx Exporter
echo "Installing Nginx Prometheus Exporter..."
TEMP_DIR="/tmp/nginx_exporter_tmp"
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$TEMP_DIR"
fi
cd "$TEMP_DIR"

# Download Nginx Exporter (using the latest version as of the provided instructions)
EXPORTER_VERSION="1.2.0"
EXPORTER_FILE="nginx-prometheus-exporter_${EXPORTER_VERSION}_linux_amd64.tar.gz"
EXPORTER_URL="https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${EXPORTER_VERSION}/${EXPORTER_FILE}"

if [ ! -f "$EXPORTER_FILE" ]; then
    echo "Downloading Nginx Exporter..."
    wget "$EXPORTER_URL"
else
    echo "Nginx Exporter tarball already downloaded."
fi

# Extract the tarball
echo "Extracting Nginx Exporter..."
tar -xzf "$EXPORTER_FILE"

# Move binary to /usr/bin
if [ ! -f "/usr/bin/nginx-prometheus-exporter" ]; then
    echo "Moving Nginx Exporter binary to /usr/bin..."
    sudo mv nginx-prometheus-exporter /usr/bin/
else
    echo "Nginx Exporter binary already exists in /usr/bin."
fi

# Clean up temporary directory
cd /tmp
rm -rf "$TEMP_DIR"

# Step 12: Create Nginx Exporter user and directory
echo "Creating Nginx Exporter user and directory..."
if ! id -u nginx_exporter > /dev/null 2>&1; then
    sudo useradd -rs /bin/false nginx_exporter
else
    echo "User nginx_exporter already exists."
fi

if [ ! -d "/etc/nginx_exporter" ]; then
    sudo mkdir /etc/nginx_exporter
    sudo chown nginx_exporter:nginx_exporter /etc/nginx_exporter
else
    echo "Directory /etc/nginx_exporter already exists."
fi

# Step 13: Create systemd service for Nginx Exporter
echo "Creating systemd service for Nginx Exporter..."
SERVICE_FILE="/etc/systemd/system/nginx-exporter.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Creating Nginx Exporter service file..."
    sudo bash -c "cat > $SERVICE_FILE" << 'EOF'
[Unit]
Description=Nginx Prometheus Exporter
After=network.target

[Service]
User=nginx_exporter
Group=nginx_exporter
ExecStart=/usr/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/stub_status
Restart=always

[Install]
WantedBy=multi-user.target
EOF
else
    echo "Nginx Exporter service file already exists."
fi

# Step 14: Enable and start Nginx Exporter service
echo "Enabling and starting Nginx Exporter service..."
sudo systemctl daemon-reload
sudo systemctl enable nginx-exporter
sudo systemctl start nginx-exporter

# Step 15: Verify Nginx Exporter service
echo "Checking Nginx Exporter service status..."
if systemctl is-active --quiet nginx-exporter; then
    echo "Nginx Exporter is running."
else
    echo "Error: Nginx Exporter is not running!"
    exit 1
fi

# Step 16: Verify Nginx Exporter endpoint
echo "Checking Nginx Exporter endpoint..."
if curl -s http://127.0.0.1:9113 | grep -q "nginx_up"; then
    echo "Nginx Exporter endpoint is working."
else
    echo "Error: Nginx Exporter endpoint is not accessible!"
    exit 1
fi

# Step 17: Provide instructions for Prometheus configuration
echo "Nginx Exporter is installed and running successfully."
echo "To monitor Nginx metrics, add the following to your Prometheus configuration (/etc/prometheus/prometheus.yml):"
cat << 'EOF'
scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']
EOF
echo "Then restart Prometheus with: sudo systemctl restart prometheus"
echo "Verify the Nginx job is UP in the Prometheus UI at http://<prometheus-server>:9090"
