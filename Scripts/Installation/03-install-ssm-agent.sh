#!/bin/bash
set -Eeuo pipefail

# CloudOps NOC V2.0
# Install/verify Amazon SSM Agent on Amazon Linux 2023.
# Most AWS Amazon Linux 2023 AMIs already include SSM Agent.
# If it is missing, install the official AWS RPM for the detected architecture.

if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: Run this script as root:"
    echo "  sudo bash $0"
    exit 1
fi

SERVICE="amazon-ssm-agent"

echo "================================================"
echo " CloudOps NOC V2.0 - Install / Verify SSM Agent"
echo "================================================"

echo "[1/5] Checking SSM Agent package..."
if rpm -q amazon-ssm-agent >/dev/null 2>&1; then
    echo "SSM Agent is already installed."
else
    ARCH="$(uname -m)"

    case "${ARCH}" in
        x86_64)
            RPM_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
            ;;
        aarch64|arm64)
            RPM_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm"
            ;;
        *)
            echo "ERROR: Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    echo "SSM Agent is not installed."
    echo "Detected architecture: ${ARCH}"
    echo "Installing official AWS SSM Agent RPM..."

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y "${RPM_URL}"
    else
        yum install -y "${RPM_URL}"
    fi
fi

echo "[2/5] Verifying service unit..."
if ! systemctl list-unit-files "${SERVICE}.service" --no-legend 2>/dev/null | grep -q "^${SERVICE}.service"; then
    echo "ERROR: ${SERVICE}.service was not found after installation."
    exit 1
fi

echo "[3/5] Enabling SSM Agent at boot..."
systemctl enable "${SERVICE}"

echo "[4/5] Starting SSM Agent..."
systemctl start "${SERVICE}"

echo "[5/5] Verifying SSM Agent..."
if systemctl is-active --quiet "${SERVICE}"; then
    echo "SUCCESS: SSM Agent is active."
else
    echo "ERROR: SSM Agent is not active."
    systemctl status "${SERVICE}" --no-pager || true
    exit 1
fi

echo
echo "IMPORTANT:"
echo "  An active agent alone does not guarantee Systems Manager connectivity."
echo "  Also verify:"
echo "  - EC2 IAM role permissions"
echo "  - outbound AWS connectivity"
echo "  - the instance appears as an SSM managed node"
