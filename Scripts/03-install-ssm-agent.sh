#!/bin/bash

echo "Checking SSM Agent..."

sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

sudo systemctl status amazon-ssm-agent
