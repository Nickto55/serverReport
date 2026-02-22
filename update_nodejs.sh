#!/bin/bash

# Quick Node.js upgrade script from 18 to 20 LTS

echo "Upgrading Node.js 18 to Node.js 20 LTS..."
echo ""

# Remove old Node.js
echo "Removing Node.js 18..."
sudo apt-get remove -y nodejs

# Clean old repository
sudo rm -f /etc/apt/sources.list.d/nodesource.list

# Install Node.js 20 LTS repository
echo "Adding Node.js 20 LTS repository..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -

# Install Node.js 20
echo "Installing Node.js 20 LTS..."
sudo apt-get install -y nodejs

# Verify
echo ""
echo "Installation complete!"
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""
