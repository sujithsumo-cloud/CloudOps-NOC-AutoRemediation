#!/bin/bash

echo "========== Apache =========="
sudo systemctl status httpd --no-pager

echo ""
echo "========== SSM Agent =========="
sudo systemctl status amazon-ssm-agent --no-pager

echo ""
echo "========== CloudWatch Agent =========="
sudo systemctl status amazon-cloudwatch-agent --no-pager

echo ""
echo "========== HTTP =========="
curl http://localhost

echo ""
echo "========== HTTPS =========="
curl -k https://localhost

echo ""
echo "========== Disk =========="
df -h

echo ""
echo "========== Memory =========="
free -h
