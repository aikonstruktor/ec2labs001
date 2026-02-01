#!/bin/bash
set -e
sudo dnf update -y
sudo dnf install -y postgresql nodejs podman python3-pip which git wget tmux epel-release ripgrep 
sudo dnf install -y htop xclip
echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc
sudo pip3 install pgadmin4
sudo mkdir -p /var/lib/pgadmin
sudo chown rocky:rocky /var/lib/pgadmin
sudo chmod 700 /var/lib/pgadmin
sudo mkdir -p /var/log/pgadmin
sudo chown rocky:rocky /var/log/pgadmin
sudo chmod 700 /var/log/pgadmin


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
git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

sudo pip3 install pgadmin4

curl -Lo eza.tar.gz https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-gnu.tar.gz
tar -xzf eza.tar.gz
sudo mv eza /usr/local/bin/
echo "alias ls='eza --color=auto --icons --git'" >> ~/.bashrc
echo "alias ls='eza --icons --group-directories-first'" >> ~/.bashrc
echo "alias ll='eza -lah --icons'" >> ~/.bashrc

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

mkdir -p ~/.config/bash
echo "[ -f ~/.config/bash/prompt.sh ] && source ~/.config/bash/prompt.sh" >> ~/.bashrc


# mkdir /opt/ocs; cd /opt/ocs; wget --content-disposition --trust-server-names "https://hpc-gridware.com/download/11546/?tmstv=1769661224"; tar xfz ocs-9.0.10-bin-lx-arm64.tar.gz; export SGE_ROOT=/opt/ocs

# sh -c 'hostnamectl set-hostname master && echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) master master" >> /etc/hosts'
# sh -c 'hostnamectl set-hostname worker1 && echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) worker1 worker1" >> /etc/hosts'
# sh -c 'hostnamectl set-hostname worker2 && echo "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) worker2 worker2" >> /etc/hosts'


