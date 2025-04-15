#!/bin/bash

set -e

echo "Adding NodeSource LTS repository..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

echo "Installing Node.js (LTS)..."
apt install -y nodejs

echo "Node.js version:"
node -v

echo "npm version:"
npm -v

echo "Optionally install global packages like pm2:"
echo "  npm install -g pm2"

echo
echo "Node.js LTS is now installed."
