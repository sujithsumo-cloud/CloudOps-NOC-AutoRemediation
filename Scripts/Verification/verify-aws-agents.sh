#!/bin/bash

set -e

echo "=============================================="
echo " CloudOps NOC V2.0 - AWS Agent Verification"
echo "=============================================="

FAILED=0

AGENTS=(
    "amazon-cloudwatch-agent"
    "amazon-ssm-agent"
)

echo
echo "[1] Checking AWS agent services..."

for agent in "${AGENTS[@]}"; do
    echo
    echo "Agent: ${agent}"

    if systemctl is-active --quiet "${agent}"; then
        echo "  Status : RUNNING"
    else
        echo "  Status : NOT RUNNING"
        FAILED=1
    fi

    if systemctl is-enabled --quiet "${agent}"; then
        echo "  Enabled: YES"
    else
        echo "  Enabled: NO"
        FAILED=1
    fi
done

echo
echo "[2] Checking CloudWatch Agent executable..."

if [ -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent ]; then
    echo "CloudWatch Agent executable: FOUND"
else
    echo "CloudWatch Agent executable: NOT FOUND"
    FAILED=1
fi

echo
echo "[3] Checking SSM Agent executable..."

if command -v amazon-ssm-agent >/dev/null 2>&1; then
    echo "SSM Agent executable: FOUND"
else
    echo "SSM Agent executable: NOT FOUND"
    FAILED=1
fi

echo
echo "=============================================="

if [ "${FAILED}" -eq 0 ]; then
    echo "AWS Agent Verification: PASSED"
else
    echo "AWS Agent Verification: FAILED"
    exit 1
fi

echo "=============================================="
