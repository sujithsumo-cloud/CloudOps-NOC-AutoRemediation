#!/bin/bash

set -e

echo "================================================"
echo " CloudOps NOC V2.0 - System Information"
echo "================================================"

echo
echo "===== HOST INFORMATION ====="
hostnamectl 2>/dev/null || hostname
uname -a

echo
echo "===== SYSTEM UPTIME ====="
uptime

echo
echo "===== CPU INFORMATION ====="
lscpu | grep -E 'Model name|CPU\(s\)|Core|Thread|Architecture' || true

echo
echo "===== MEMORY INFORMATION ====="
free -h

echo
echo "===== DISK INFORMATION ====="
df -h

echo
echo "===== ROOT FILESYSTEM ====="
df -h /

echo
echo "===== TOP CPU PROCESSES ====="
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -11

echo
echo "===== TOP MEMORY PROCESSES ====="
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -11

echo
echo "===== HTTPD STATUS ====="
systemctl status httpd --no-pager -l || true

echo
echo "===== HTTPD PROCESSES ====="
pgrep -a httpd || echo "No httpd process found."

echo
echo "===== CLOUDWATCH AGENT STATUS ====="
systemctl status amazon-cloudwatch-agent --no-pager -l || true

echo
echo "===== SSM AGENT STATUS ====="
systemctl status amazon-ssm-agent --no-pager -l || true

echo
echo "================================================"
echo " System information collection completed."
echo "================================================"
