#!/bin/bash

# Script to automate the installation and configuration of Prometheus on a Linux system (AMD64 architecture).
# The script prompts the user for the Prometheus version, downloads it, sets up directories, configures permissions,
# creates a systemd service, and starts the Prometheus server with a minimal configuration.

# Exit on any error to ensure robust execution
set -e

# Function to validate if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools (wget, tar, sudo)
echo "Checking for required tools..."
for cmd in wget tar sudo; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed. Please install it and rerun the script."
        exit 1
    fi
done

# Prompt user for Prometheus version
echo "Please enter the Prometheus version to install (e.g., 3.5.0):"
read -r PROMETHEUS_VERSION

# Validate version input (basic check for format like x.y.z)
if [[ ! "$PROMETHEUS_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Please use a format like x.y.z (e.g., 3.5.0)."
    exit 1
fi

# Define variables for directories and tarball
PROMETHEUS_TARBALL="prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_TARBALL}"
INSTALL_DIR="/opt/prometheus"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
LOG_DIR="/var/log/prometheus"
TEMP_DIR="$HOME/prometheus-install"

# Step 1: Create a temporary directory for downloading and extracting Prometheus
echo "Creating temporary directory at $TEMP_DIR..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || { echo "Error: Failed to change to $TEMP_DIR"; exit 1; }

# Step 2: Download Prometheus tarball
echo "Downloading Prometheus version $PROMETHEUS_VERSION..."
if ! wget "$PROMETHEUS_URL"; then
    echo "Error: Failed to download Prometheus tarball. Please check the version or your internet connection."
    exit 1
fi

# Step 3: Extract the tarball
echo "Extracting $PROMETHEUS_TARBALL..."
tar -xzf "$PROMETHEUS_TARBALL"
cd "prometheus-${PROMETHEUS_VERSION}.linux-amd64" || { echo "Error: Failed to change to extracted directory"; exit 1; }

# Step 4: Create standard directories for Prometheus
echo "Creating standard directories..."
sudo mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"

# Step 5: Move binaries and configuration files to appropriate directories
echo "Moving binaries and configuration files..."
sudo mv prometheus promtool "$INSTALL_DIR/"
sudo mv prometheus.yml "$CONFIG_DIR/"

# Optional: Move consoles and console_libraries for advanced web interface features
if [ -d "consoles" ] && [ -d "console_libraries" ]; then
    echo "Moving optional consoles and console_libraries..."
    sudo mv consoles console_libraries "$INSTALL_DIR/"
fi

# Step 6: Clean up temporary files
echo "Cleaning up temporary files..."
cd "$HOME"
rm -rf "$TEMP_DIR"

# Step 7: Create a dedicated Prometheus user
echo "Creating dedicated Prometheus user..."
if ! id prometheus >/dev/null 2>&1; then
    sudo useradd --system --no-create-home --shell /bin/false prometheus
else
    echo "Prometheus user already exists, skipping creation."
fi

# Step 8: Set ownership for directories
echo "Setting ownership for directories..."
sudo chown -R prometheus:prometheus "$INSTALL_DIR" "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"

# Step 9: Set permissions for files and directories
echo "Setting permissions..."
sudo chmod 755 "$INSTALL_DIR/prometheus" "$INSTALL_DIR/promtool"
sudo chmod 644 "$CONFIG_DIR/prometheus.yml"
sudo chmod 750 "$DATA_DIR" "$LOG_DIR"

# Step 10: Configure prometheus.yml with minimal settings
echo "Configuring prometheus.yml..."
cat <<EOF | sudo tee "$CONFIG_DIR/prometheus.yml" > /dev/null
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'demo_service'
    static_configs:
      - targets: ['demo.promlabs.com:10000', 'demo.promlabs.com:10001', 'demo.promlabs.com:10002']
EOF

# Step 11: Create systemd service file for Prometheus
echo "Creating systemd service for Prometheus..."
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service > /dev/null
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=$INSTALL_DIR/prometheus \
  --config.file=$CONFIG_DIR/prometheus.yml \
  --storage.tsdb.path=$DATA_DIR \
  --web.listen-address=:9090
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Step 12: Open firewall port 9090 (if ufw is installed)
if command_exists ufw; then
    echo "Opening port 9090 in firewall..."
    sudo ufw allow 9090/tcp
else
    echo "Note: ufw not detected. Ensure port 9090 is open if a firewall is in use."
fi

# Step 13: Enable and start Prometheus service
echo "Enabling and starting Prometheus service..."
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Step 14: Check Prometheus service status
echo "Checking Prometheus service status..."
if sudo systemctl status prometheus --no-pager | grep -q "active (running)"; then
    echo "Prometheus is running successfully!"
    echo "You can access the Prometheus web interface at http://localhost:9090"
else
    echo "Error: Prometheus service failed to start. Check logs with 'sudo systemctl status prometheus'."
    exit 1
fi
