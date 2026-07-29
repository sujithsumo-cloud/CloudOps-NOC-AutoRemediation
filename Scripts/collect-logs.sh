#!/bin/bash

echo "Apache Logs"
sudo tail -20 /var/log/httpd/error_log

echo ""

echo "SSM Agent Logs"
sudo journalctl -u amazon-ssm-agent -n 20

echo ""

echo "CloudWatch Agent Logs"
sudo journalctl -u amazon-cloudwatch-agent -n 20
