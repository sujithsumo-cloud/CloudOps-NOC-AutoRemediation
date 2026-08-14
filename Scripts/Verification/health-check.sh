#!/bin/bash

set -e

echo "=============================================="
echo " CloudOps NOC V2.0 - EC2 Health Check"
echo "=============================================="

FAILED=0

echo
echo "[1] Hostname"
hostname

echo
echo "[2] System Uptime"
uptime

echo
echo "[3] CPU Load"
uptime | awk -F'load average:' '{print $2}'

echo
echo "[4] Memory Usage"
free -h

echo
echo "[5] Root Filesystem"
df -h /

echo
echo "[6] HTTPD Health"

if systemctl is-active --quiet httpd; then
    echo "HTTPD: HEALTHY"
else
    echo "HTTPD: FAILED"
    FAILED=1
fi

echo
echo "[7] CloudWatch Agent Health"

if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "CloudWatch Agent: HEALTHY"
else
    echo "CloudWatch Agent: FAILED"
    FAILED=1
fi

echo
echo "[8] SSM Agent Health"

if systemctl is-active --quiet amazon-ssm-agent; then
    echo "SSM Agent: HEALTHY"
else
    echo "SSM Agent: FAILED"
    FAILED=1
fi

echo
echo "=============================================="

if [ "${FAILED}" -eq 0 ]; then
    echo "Overall Health: HEALTHY"
    echo "Health Check: PASSED"
else
    echo "Overall Health: ATTENTION REQUIRED"
    echo "Health Check: FAILED"
    exit 1
fi

echo "=============================================="
