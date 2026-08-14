#!/bin/bash

set -e

echo "======================================"
echo " CloudOps NOC V2.0 - Stop HTTPD"
echo "======================================"

echo "[1/2] Stopping Apache HTTPD..."

systemctl stop httpd

echo "[2/2] Verifying HTTPD..."

if systemctl is-active --quiet httpd; then
    echo
    echo "ERROR: HTTPD is still running."
    systemctl status httpd --no-pager
    exit 1
else
    echo
    echo "HTTPD stopped successfully."
    echo "Service status: $(systemctl is-active httpd || true)"
fi
