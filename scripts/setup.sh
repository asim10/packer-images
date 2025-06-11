#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print commands and their arguments as they are executed.

echo "Starting setup.sh script..."

# Update system (already done by the first provisioner, but harmless to repeat)
echo "Updating system packages in setup.sh..."
sudo dnf update -y

# Install common utilities
echo "Installing common utilities..."
# Added '|| true' to systemctl commands to prevent script failure if already enabled/started
# Ensure all dnf installs have -y
sudo dnf install -y git wget curl vim net-tools openssh-server

# Enable and start SSH service (already done in kickstart, but harmless to re-run if needed)
echo "Enabling and starting SSH service..."
sudo systemctl enable sshd || true
sudo systemctl start sshd || true

# Clean up dnf cache and temporary files
echo "Cleaning up dnf cache and temporary files..."
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo rm -rf /tmp/*

# Zero out free space to enable better compression of the Vagrant box
# echo "Zeroing out free space for compression..."
# sudo dd if=/dev/zero of=/EMPTY bs=1M || true
# sudo rm -f /EMPTY

# Remove bash history
echo "Removing bash history..."
cat /dev/null > ~/.bash_history && history -c && history -w
sudo cat /dev/null > /root/.bash_history && sudo history -c && sudo history -w

echo "Setup.sh script finished."
