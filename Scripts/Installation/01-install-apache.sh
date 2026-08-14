#!/bin/bash

set -e

echo "======================================"
echo " CloudOps NOC V2.0 - Apache Setup"
echo "======================================"

echo "[1/4] Installing Apache HTTPD..."
dnf install -y httpd

echo "[2/4] Enabling Apache HTTPD..."
systemctl enable httpd

echo "[3/4] Starting Apache HTTPD..."
systemctl start httpd

echo "[4/4] Verifying Apache HTTPD..."
systemctl is-active --quiet httpd

echo
echo "Apache HTTPD installation completed successfully."
echo "Service status: $(systemctl is-active httpd)"
echo "Enabled status: $(systemctl is-enabled httpd)"
