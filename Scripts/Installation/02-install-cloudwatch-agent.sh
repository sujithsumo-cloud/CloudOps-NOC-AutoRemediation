#!/bin/bash

set -e

echo "=========================================="
echo " CloudOps NOC V2.0 - CloudWatch Agent"
echo "=========================================="

echo "[1/3] Checking CloudWatch Agent..."

if command -v amazon-cloudwatch-agent-ctl >/dev/null 2>&1; then
    echo "CloudWatch Agent is already installed."
else
    echo "Installing CloudWatch Agent..."

    dnf install -y amazon-cloudwatch-agent

    echo "CloudWatch Agent installation completed."
fi

echo "[2/3] Verifying installation..."

if [ -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then
    echo "CloudWatch Agent executable found."
else
    echo "ERROR: CloudWatch Agent installation could not be verified."
    exit 1
fi

echo "[3/3] Checking service..."

systemctl is-enabled amazon-cloudwatch-agent >/dev/null 2>&1 || true

echo
echo "CloudWatch Agent installation verification completed."
echo
echo "Agent path:"
echo "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl"
