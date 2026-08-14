#!/bin/bash

set -e

echo "======================================"
echo " CloudOps NOC V2.0 - Restart HTTPD"
echo "======================================"

echo "[1/3] Checking current HTTPD status..."

systemctl is-active httpd || true

echo
echo "[2/3] Restarting Apache HTTPD..."

systemctl restart httpd

echo
echo "[3/3] Verifying HTTPD..."

if systemctl is-active --quiet httpd; then
    echo "HTTPD restart successful."
    echo "Service status: $(systemctl is-active httpd)"
else
    echo "ERROR: HTTPD failed to start after restart."
    systemctl status httpd --no-pager
    exit 1
fi

echo
echo "HTTPD operation completed successfully."
