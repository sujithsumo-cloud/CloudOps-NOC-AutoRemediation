#!/bin/bash

set -e

echo "=============================================="
echo " CloudOps NOC V2.0 - Enable Required Services"
echo "=============================================="

SERVICES=(
    "httpd"
    "amazon-cloudwatch-agent"
    "amazon-ssm-agent"
)

echo "[1/3] Checking required services..."

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        echo "Found: ${service}"
    else
        echo "ERROR: ${service} service was not found."
        exit 1
    fi
done

echo
echo "[2/3] Enabling services..."

for service in "${SERVICES[@]}"; do
    systemctl enable "${service}"
    echo "Enabled: ${service}"
done

echo
echo "[3/3] Starting services..."

for service in "${SERVICES[@]}"; do
    systemctl start "${service}"
    echo "Started: ${service}"
done

echo
echo "=============================================="
echo " Service Verification"
echo "=============================================="

for service in "${SERVICES[@]}"; do
    status=$(systemctl is-active "${service}")
    enabled=$(systemctl is-enabled "${service}")

    echo
    echo "Service : ${service}"
    echo "Active  : ${status}"
    echo "Enabled : ${enabled}"

    if [ "${status}" != "active" ]; then
        echo "ERROR: ${service} is not active."
        exit 1
    fi
done

echo
echo "All required CloudOps NOC V2.0 services are enabled and running."
