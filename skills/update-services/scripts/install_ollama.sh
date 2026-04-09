#!/bin/bash

echo "Checking permissions..."

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root"
   echo "Please run: sudo $0"
   exit 1
fi

if [[ ! -r /etc/systemd/system/ollama.service ]]; then
   echo "ERROR: No read access to /etc/systemd/system/ollama.service"
   exit 1
fi

if [[ ! -w /etc/systemd/system/ollama.service ]]; then
   echo "ERROR: No write access to /etc/systemd/system/ollama.service"
   echo "Please ensure you have sudo privileges"
   exit 1
fi

echo "Running Ollama installation script..."
curl -fsSL https://ollama.com/install.sh | sh

echo "Updating ollama.service configuration..."

if [[ $# -gt 0 ]]; then
    echo "Adding custom environment variables..."
    for var in "$@"; do
        if [[ $var =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            echo "  Adding: $var"
            sed -i '/\[Install\]/i Environment="'"$var"'"' /etc/systemd/system/ollama.service
        else
            echo "  WARNING: Skipping invalid variable: $var"
        fi
    done
fi

echo "Configuration updated successfully!"
echo "Reloading systemd daemon configuration..."
systemctl daemon-reload

echo "Restarting ollama service..."
systemctl restart ollama

echo "Ollama installation and configuration completed successfully!"