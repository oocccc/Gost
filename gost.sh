#!/bin/bash
set -e

echo "Updating package lists..."
apt update
apt install git

echo "Installing sudo..."
apt install -y sudo

echo "sudo installation complete!"


# Download Go 1.23.8
echo "Downloading Go 1.23.8..."
wget https://go.dev/dl/go1.23.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Extract and install Go to /usr/local
echo "Extracting and installing Go to /usr/local..."
sudo tar -C /usr/local -xzf go1.23.8.linux-amd64.tar.gz

# Add Go's bin directory to the PATH for this session
export PATH=$PATH:/usr/local/go/bin

# Clone the gost repository and build
echo "Cloning the gost repository..."
git clone https://github.com/go-gost/gost.git

echo "Building gost..."
cd gost/cmd/gost
go build

# Install gost
echo "Installing gost to /usr/local/bin..."
sudo cp gost /usr/local/bin/gost
sudo chmod +x /usr/local/bin/gost

# Return to the initial directory (adjust if needed)
cd ../../..

# Ask for the service mode selection
echo "Please choose the service mode: 1. IN   2. OUT"
read mode

if [ "$mode" = "1" ]; then
    echo "Please enter the IP address to forward to:"
    read forward_ip
    exec_start="/usr/local/bin/gost -L \"socks5://:1080\" -F \"socks5://$forward_ip:1080\""
elif [ "$mode" = "2" ]; then
    exec_start="/usr/local/bin/gost -L \"socks5://:1080\""
else
    echo "Invalid option. Defaulting to OUT mode."
    exec_start="/usr/local/bin/gost -L \"socks5://:1080\""
fi

# Enable IPv4 forwarding
echo "Enabling IPv4 forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Create the systemd service file for gost
echo "Creating /etc/systemd/system/gost.service file..."
sudo bash -c "cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=GOST Service
After=network.target

[Service]
ExecStart=${exec_start}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd configurations, enable and start the gost service
echo "Reloading systemd configuration..."
sudo systemctl daemon-reload
echo "Enabling gost to start on boot..."
sudo systemctl enable gost
echo "Starting the gost service..."
sudo systemctl restart gost

echo "Installation, configuration, and startup of the gost service are complete!"
