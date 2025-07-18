#!/bin/bash

# Prompt user for Node Exporter version
echo "Please enter the Node Exporter version to install (e.g., 1.8.2):"
read NODE_EXPORTER_VERSION

# Validate input
if [[ ! $NODE_EXPORTER_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Please use format X.Y.Z (e.g., 1.8.2)"
    exit 1
fi

# Set variables
ARCH="linux-amd64"
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
TARBALL="node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
EXTRACTED_DIR="node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}"

# Step 1: Download Node Exporter
echo "Downloading Node Exporter version ${NODE_EXPORTER_VERSION}..."
wget -O "$TARBALL" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Node Exporter"
    exit 1
fi

# Step 2: Extract the tarball
echo "Extracting Node Exporter..."
tar -zxvf "$TARBALL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to extract tarball"
    exit 1
fi

# Step 3: Move binary to /usr/bin
echo "Moving Node Exporter binary to /usr/bin..."
sudo mv "${EXTRACTED_DIR}/node_exporter" /usr/bin/
if [ $? -ne 0 ]; then
    echo "Error: Failed to move binary"
    exit 1
fi

# Step 4: Create dedicated user
echo "Creating node_exporter user..."
sudo useradd -rs /bin/false node_exporter
if [ $? -ne 0 ]; then
    echo "Error: Failed to create user"
    exit 1
fi

# Step 5: Set ownership
echo "Setting ownership for Node Exporter binary..."
sudo chown node_exporter:node_exporter /usr/bin/node_exporter
if [ $? -ne 0 ]; then
    echo "Error: Failed to set ownership"
    exit 1
fi

# Step 6: Create log directory
echo "Creating log directory..."
sudo mkdir -p /var/log/node_exporter
sudo chown node_exporter:node_exporter /var/log/node_exporter
if [ $? -ne 0 ]; then
    echo "Error: Failed to create or set ownership for log directory"
    exit 1
fi

# Step 7: Create systemd service file
echo "Creating systemd service file..."
sudo bash -c "cat > /etc/systemd/system/node_exporter.service" << EOL
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/bin/node_exporter \\
    --collector.filesystem.fs-types-exclude=^(tmpfs|sysfs|proc|devtmpfs)$
Restart=always

[Install]
WantedBy=multi-user.target
EOL
if [ $? -ne 0 ]; then
    echo "Error: Failed to create systemd service file"
    exit 1
fi

# Step 8: Reload systemd, start and enable service
echo "Starting Node Exporter service..."
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
if [ $? -ne 0 ]; then
    echo "Error: Failed to start or enable Node Exporter service"
    exit 1
fi

# Step 9: Check service status
echo "Checking Node Exporter service status..."
sudo systemctl status node_exporter --no-pager

# Step 10: Clean up
echo "Cleaning up downloaded files..."
rm -rf "$TARBALL" "$EXTRACTED_DIR"

echo "Node Exporter installation completed successfully!"
echo "You can verify metrics at http://localhost:9100/metrics"
