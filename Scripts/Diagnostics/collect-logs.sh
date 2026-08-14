#!/bin/bash

set -e

echo "================================================"
echo " CloudOps NOC V2.0 - Collect Logs"
echo "================================================"

OUTPUT_DIR="/tmp/cloudops-noc-logs"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_DIR="${OUTPUT_DIR}/${TIMESTAMP}"

echo "[1/4] Creating diagnostic directory..."

sudo mkdir -p "${REPORT_DIR}"

echo "Report directory:"
echo "${REPORT_DIR}"

echo
echo "[2/4] Collecting HTTPD logs..."

if [ -f /var/log/httpd/error_log ]; then
    sudo tail -100 /var/log/httpd/error_log \
        > "${REPORT_DIR}/httpd-error.log"
else
    echo "HTTPD error log not found." \
        > "${REPORT_DIR}/httpd-error.log"
fi

if [ -f /var/log/httpd/access_log ]; then
    sudo tail -100 /var/log/httpd/access_log \
        > "${REPORT_DIR}/httpd-access.log"
else
    echo "HTTPD access log not found." \
        > "${REPORT_DIR}/httpd-access.log"
fi

echo
echo "[3/4] Collecting service and system logs..."

sudo journalctl -u httpd --since "30 minutes ago" --no-pager \
    > "${REPORT_DIR}/httpd-journal.log" || true

sudo journalctl -u amazon-cloudwatch-agent --since "30 minutes ago" --no-pager \
    > "${REPORT_DIR}/cloudwatch-agent-journal.log" || true

sudo journalctl -u amazon-ssm-agent --since "30 minutes ago" --no-pager \
    > "${REPORT_DIR}/ssm-agent-journal.log" || true

sudo journalctl --since "30 minutes ago" --no-pager \
    > "${REPORT_DIR}/system-journal.log" || true

echo
echo "[4/4] Collecting current service status..."

sudo systemctl status httpd --no-pager -l \
    > "${REPORT_DIR}/httpd-status.txt" || true

sudo systemctl status amazon-cloudwatch-agent --no-pager -l \
    > "${REPORT_DIR}/cloudwatch-agent-status.txt" || true

sudo systemctl status amazon-ssm-agent --no-pager -l \
    > "${REPORT_DIR}/ssm-agent-status.txt" || true

echo
echo "================================================"
echo " Log collection completed."
echo "================================================"

echo
echo "Collected files:"
sudo find "${REPORT_DIR}" -type f -printf '%f\n'

echo
echo "Report directory:"
echo "${REPORT_DIR}"
