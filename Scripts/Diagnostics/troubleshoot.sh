#!/bin/bash

set -e

echo "================================================"
echo " CloudOps NOC V2.0 - Troubleshooting"
echo "================================================"

ISSUES=0

echo
echo "===== EC2 INFORMATION ====="
hostname
uptime

echo
echo "===== HTTPD STATUS ====="

if systemctl is-active --quiet httpd; then
    echo "PASS: HTTPD is active."
else
    echo "FAIL: HTTPD is not active."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== CLOUDWATCH AGENT STATUS ====="

if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "PASS: CloudWatch Agent is active."
else
    echo "FAIL: CloudWatch Agent is not active."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== SSM AGENT STATUS ====="

if systemctl is-active --quiet amazon-ssm-agent; then
    echo "PASS: SSM Agent is active."
else
    echo "FAIL: SSM Agent is not active."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== HTTPD PROCESS ====="

HTTPD_COUNT=$(pgrep -c httpd || true)

echo "HTTPD process count: ${HTTPD_COUNT}"

if [ "${HTTPD_COUNT}" -eq 0 ]; then
    echo "WARNING: No HTTPD process detected."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== HTTP PORT CHECK ====="

if ss -lnt | grep -q ':80'; then
    echo "PASS: Port 80 is listening."
else
    echo "WARNING: Port 80 is not listening."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== LOCAL HTTP CHECK ====="

if curl -fsS --max-time 10 http://localhost >/dev/null; then
    echo "PASS: HTTP endpoint is responding."
else
    echo "WARNING: HTTP endpoint is not responding."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== CLOUDWATCH PROCSTAT CONFIGURATION ====="

if grep -q '\[\[inputs.procstat\]\]' \
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml; then

    echo "PASS: procstat configuration detected."

    grep -A6 '\[\[inputs.procstat\]\]' \
    /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml
else
    echo "WARNING: procstat configuration missing."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== CLOUDWATCH CPU CONFIGURATION ====="

if grep -q '\[\[inputs.cpu\]\]' \
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.toml; then

    echo "PASS: CPU configuration detected."
else
    echo "WARNING: CPU configuration missing."
    ISSUES=$((ISSUES+1))
fi

echo
echo "===== RECENT CLOUDWATCH AGENT LOGS ====="

journalctl -u amazon-cloudwatch-agent \
--since "5 minutes ago" \
--no-pager | tail -20 || true

echo
echo "===== RECENT HTTPD LOGS ====="

journalctl -u httpd \
--since "5 minutes ago" \
--no-pager | tail -20 || true

echo
echo "===== TROUBLESHOOT SUMMARY ====="

if [ "${ISSUES}" -eq 0 ]; then
    echo "No issues detected."
    echo "System appears healthy."
else
    echo "Detected ${ISSUES} issue(s)."
    echo "Review the warnings above."
fi

echo
echo "================================================"
echo " Troubleshooting completed."
echo "================================================"
