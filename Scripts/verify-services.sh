#!/bin/bash

echo "==============================="
echo "Apache Status"
echo "==============================="
sudo systemctl status httpd --no-pager

echo ""

echo "==============================="
echo "SSM Agent Status"
echo "==============================="
sudo systemctl status amazon-ssm-agent --no-pager

echo ""

echo "==============================="
echo "CloudWatch Agent Status"
echo "==============================="
sudo systemctl status amazon-cloudwatch-agent --no-pager
