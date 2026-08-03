#!/bin/bash

sudo yum install amazon-cloudwatch-agent -y
amazon-cloudwatch-agent-ctl -a status
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
sudo systemctl status amazon-cloudwatch-agent
cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
