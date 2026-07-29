#!/bin/bash

sudo systemctl enable httpd
sudo systemctl enable amazon-ssm-agent
sudo systemctl enable amazon-cloudwatch-agent

echo "Services enabled successfully."
