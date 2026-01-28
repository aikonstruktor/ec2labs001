#!/bin/bash
set -e
sudo dnf update -y
sudo dnf install -y postgresql nodejs podman python3-pip which

ARCH=$(uname -m)

if [[ "$ARCH" == "x86_64" ]]; then
    NVIM_PKG="nvim-linux-x86_64.tar.gz"
    NVIM_DIR="nvim-linux-x86_64"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NVIM_PKG="nvim-linux-arm64.tar.gz"
    NVIM_DIR="nvim-linux-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH"
echo "Using package: $NVIM_PKG"

# Download Neovim
curl -LO "https://github.com/neovim/neovim/releases/latest/download/${NVIM_PKG}"

# Remove old install (if any) and extract
sudo rm -rf "/opt/${NVIM_DIR}"
sudo tar -C /opt -xzf "${NVIM_PKG}"

# Add to PATH only if not already present
if ! grep -q "/opt/${NVIM_DIR}/bin" ~/.bashrc; then
    echo "export PATH=\"\$PATH:/opt/${NVIM_DIR}/bin\"" >> ~/.bashrc
fi

# Cleanup
rm -f "${NVIM_PKG}"

# Reload bashrc for current session
source ~/.bashrc

# Verify
echo "Neovim installed at:"
which nvim
nvim --version




