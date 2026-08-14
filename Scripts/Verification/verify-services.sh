#!/bin/bash

set -e

echo "=============================================="
echo " CloudOps NOC V2.0 - Service Verification"
echo "=============================================="

SERVICES=(
    "httpd"
    "amazon-cloudwatch-agent"
    "amazon-ssm-agent"
)

FAILED=0

for service in "${SERVICES[@]}"; do
    echo
    echo "Checking: ${service}"

    if systemctl is-active --quiet "${service}"; then
        echo "  Active : YES"
    else
        echo "  Active : NO"
        FAILED=1
    fi

    if systemctl is-enabled --quiet "${service}"; then
        echo "  Enabled: YES"
    else
        echo "  Enabled: NO"
        FAILED=1
    fi
done

echo
echo "=============================================="

if [ "${FAILED}" -eq 0 ]; then
    echo "All required services are active and enabled."
    echo "Verification: PASSED"
else
    echo "One or more required services failed verification."
    echo "Verification: FAILED"
    exit 1
fi

echo "=============================================="
