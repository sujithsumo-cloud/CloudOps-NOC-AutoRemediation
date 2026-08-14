#!/bin/bash

set -e

echo "======================================"
echo " CloudOps NOC V2.0 - Start HTTPD"
echo "======================================"

echo "[1/2] Starting Apache HTTPD..."

systemctl start httpd

echo "[2/2] Verifying HTTPD..."

if systemctl is-active --quiet httpd; then
    echo
    echo "HTTPD started successfully."
    echo "Service status: $(systemctl is-active httpd)"
else
    echo
    echo "ERROR: HTTPD failed to start."
    systemctl status httpd --no-pager
    exit 1
fi
