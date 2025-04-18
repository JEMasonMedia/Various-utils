#!/bin/bash

install_if_missing() {
  for pkg in "$@"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      echo "[+] Installing missing package: $pkg"
      apt install -y "$pkg"
    else
      echo "[✓] $pkg is already installed."
    fi
  done
}

# Install gum if missing
if ! command -v gum &>/dev/null; then
  echo "[+] Installing gum from Charm APT repo..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update
  sudo apt install -y gum
fi
