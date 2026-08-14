#!/bin/bash

set -e

echo "======================================"
echo " CloudOps NOC V2.0 - SSM Agent Setup"
echo "======================================"

echo "[1/4] Checking SSM Agent..."

if command -v amazon-ssm-agent >/dev/null 2>&1; then
    echo "SSM Agent is already installed."
else
    echo "SSM Agent is not installed."

    echo "Attempting installation..."
    dnf install -y amazon-ssm-agent

    echo "SSM Agent installation completed."
fi

echo "[2/4] Enabling SSM Agent..."

systemctl enable amazon-ssm-agent

echo "[3/4] Starting SSM Agent..."

systemctl start amazon-ssm-agent

echo "[4/4] Verifying SSM Agent..."

systemctl is-active --quiet amazon-ssm-agent

echo
echo "SSM Agent installation completed successfully."
echo
echo "Service status: $(systemctl is-active amazon-ssm-agent)"
echo "Enabled status: $(systemctl is-enabled amazon-ssm-agent)"
