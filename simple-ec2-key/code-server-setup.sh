#!/usr/bin/env bash

set -e

IP=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)
      shift
      IP="$1"
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

# Check required argument
if [[ -z "$IP" ]]; then
  echo "Error: --ip is required"
  exit 1
fi

# Basic IPv4 validation
if [[ ! $IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Error: Invalid IP format"
  exit 1
fi

echo "IP provided: $IP"

# =========================
# CONFIG (EDIT THESE)
# =========================
DOMAIN="devbox.dev.xenonlabs.ai"
IP="$IP"
PORT="8090"
PASSWORD="Password213"

CONFIG_DIR="$HOME/.config/code-server"

echo "👉 Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

echo "👉 Creating config directory..."
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

echo "👉 Generating self-signed EC certificate (non-interactive)..."
openssl req -x509 -nodes -days 3650 \
  -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout server.key \
  -out server.crt \
  -subj "/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},IP:${IP}"

chmod 600 server.key server.crt

echo "👉 Writing config.yaml..."
cat > "$CONFIG_DIR/config.yaml" <<EOF
bind-addr: 0.0.0.0:${PORT}
auth: password
password: ${PASSWORD}
cert: ${CONFIG_DIR}/server.crt
cert-key: ${CONFIG_DIR}/server.key
EOF

chmod 600 "$CONFIG_DIR/config.yaml"

echo "👉 Ensuring user services survive logout..."
loginctl enable-linger "$USER"

echo "👉 Reloading systemd user daemon..."
systemctl --user daemon-reexec
systemctl --user daemon-reload

echo "👉 Enabling and starting code-server..."
systemctl --user enable --now code-server

echo ""
echo "✅ DONE"
echo "🌐 Access: https://${DOMAIN}:${PORT}"
echo "🔑 Password: ${PASSWORD}"

code-server --install-extension ahmadawais.shades-of-purple
code-server --install-extension chadalen.vscode-jetbrains-icon-theme

#!/bin/bash
set -euo pipefail

EXT_NAME="ardonplay.vscode-jetbrains-icon-theme"
EXT_VERSION="0.0.4"
VSIX_URL="https://open-vsx.org/api/ardonplay/vscode-jetbrains-icon-theme/0.0.4/file/ardonplay.vscode-jetbrains-icon-theme-0.0.4.vsix"

TMP_VSIX="/tmp/${EXT_NAME}-${EXT_VERSION}.vsix"

echo "📥 Downloading VSIX..."
curl -fL "$VSIX_URL" -o "$TMP_VSIX"

echo "🔍 Installing extension in code-server..."
code-server --install-extension "$TMP_VSIX" || true

echo "🧹 Cleaning up..."
rm -f "$TMP_VSIX"

echo "✅ Extension installed"
systemctl --user restart code-server