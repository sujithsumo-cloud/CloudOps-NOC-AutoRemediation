# Low-Level Design (LLD)

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda and Systems Manager

---

# Document Information

| Item | Details |
|------|----------|
| Document Name | Low-Level Design (LLD) |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Smart Sujith |
| Date | July 2026 |
| Environment | AWS Cloud |

---

# 1. Introduction

This document provides the detailed technical implementation of the CloudOps NOC Automation solution. It explains the configuration of each AWS resource, the interaction between services, monitoring configuration, automation workflow, IAM permissions, and EC2 setup.

The objective is to provide all technical details required for deployment, maintenance, and troubleshooting.

---

# 2. AWS Environment

| Component | Value |
|------------|-------|
| AWS Account | 257074875139 |
| Region | ap-south-1 |
| Operating System | Amazon Linux 2023 |
| Instance Type | t2.micro |
| Architecture | x86_64 |
| Availability Zone | ap-south-1 |

---

# 3. VPC Configuration

## VPC

| Property | Value |
|----------|-------|
| Name | cloudops-vpc |
| CIDR Block | 10.0.0.0/16 |

---

## Subnet

| Property | Value |
|----------|-------|
| Name | cloudops-subnet |
| CIDR | 10.0.1.0/24 |
| Public | Yes |

---

## Route Table

| Destination | Target |
|-------------|--------|
| 0.0.0.0/0 | Internet Gateway |

---

## Internet Gateway

Name

cloudops-igw

---

# 4. EC2 Configuration

| Property | Value |
|-----------|-------|
| Instance Name | cloudops-server |
| Instance ID | i-0b7d483631875bb1c |
| AMI | Amazon Linux 2023 |
| Public IP | 13.206.186.175 |
| IAM Role | cloudops-EC2-inline-role |

---

# 5. Security Group Configuration

Security Group

cloudops-sg

Inbound Rules

| Protocol | Port | Source |
|-----------|------|--------|
| SSH | 22 | My IP |
| HTTP | 80 | 0.0.0.0/0 |

Outbound Rules

Allow All Traffic

---

# 6. IAM Role Configuration

Role Name

cloudops-EC2-inline-role

Purpose

Provides permissions for:

- Amazon CloudWatch Agent
- Systems Manager Agent
- SNS Integration
- CloudWatch Metrics
- CloudWatch Logs

Attached Permission

Custom Inline Policy

---

# 7. CloudWatch Agent Configuration

Agent Version

1.300067.1

Configuration File : /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_file_amazon-cloudwatch-agent.json


Collected Metrics

• CPU Utilization

• Memory Utilization

• Disk Usage

• Disk I/O

• Network Bytes Received

• Network Bytes Sent

• Network Packets Received

• Network Packets Sent

• Apache Process Count

Network Interface : ens5


Collection Interval

60 Seconds

---

# 8. CloudWatch Dashboard

Dashboard Name

cloudops-NOC-dashboard

Widgets

- CPU Utilization
- Memory Utilization
- Disk Utilization
- Network Traffic
- Apache Process Count

---

# 9. CloudWatch Alarm Configuration

## Alarm 1

Name

cloudops-cpuutilization

Metric

CPUUtilization

Threshold

80%

Action

Send notification to SNS

---

## Alarm 2

Name

NOC-cloudops-automate

Metric

Apache Process Count

Condition

Process Count = 0

Action

SNS Notification

---

# 10. SNS Configuration

Topic Name

cloudops-sns

Display Name

NOC-topic

Subscription

Email

Notification Receiver

System Administrator

Purpose

Trigger Lambda function and notify engineers.

---

# 11. Lambda Configuration

Function Name

Cloudops-NOC-automate

Runtime

Python 3.x

Trigger

Amazon SNS

Environment Variables

INSTANCE_ID : i-0b7d483631875bb1c

TOPIC_ARN : arn:aws:sns:ap-south-1:257074875139:cloudops-sns

Function Responsibilities

- Receive SNS notification
- Connect using AWS Systems Manager
- Execute command : systemctl restart httpd

- Verify Apache status
- Publish success or failure notification

---

# 12. Systems Manager Configuration

Managed Node

cloudops-server

Platform

Amazon Linux 2023

Agent Version

3.3.4624.0

Status

Online

Capabilities

- Run Command
- Session Manager
- Automation

---

# 13. Monitoring Flow

CloudWatch Agent

↓

Publishes Metrics

↓

CloudWatch

↓

Alarm Triggered

↓

SNS Topic

↓

Lambda Function

↓

SSM Run Command

↓

Restart Apache

↓

Verification

↓

SNS Success Notification

---

# 14. Apache Monitoring

Process

httpd

Collection Method

procstat

Condition

PID Count = 0

Action

Restart Service Automatically

---

# 15. Logging

CloudWatch Logs

Stores

- Agent Logs
- Lambda Logs

System Logs : /var/log/messages

CloudWatch Agent Logs : /opt/aws/amazon-cloudwatch-agent/logs/

SSM Logs : /var/log/amazon/ssm/

---

# 16. Error Handling

If Apache Restart Fails

- Lambda captures the error
- Failure notification is sent
- Manual investigation is required

If CloudWatch Agent Stops

- Metrics stop publishing
- Alarm remains inactive
- Agent service must be restarted

If SSM Agent Stops

- Lambda cannot execute commands
- Auto-remediation fails
- Failure notification generated

---

# 17. Performance Considerations

Metric Collection Interval

60 seconds

Monitoring Overhead

Very Low

Lambda Timeout

30 seconds

Expected Recovery Time

Less than 1 minute

---

# 18. Security Considerations

- Least privilege IAM policy
- Systems Manager instead of SSH
- CloudWatch Logs for auditing
- IAM Role authentication
- No hardcoded AWS credentials
- Secure communication over HTTPS

---

# 19. Technical Summary

| Component | Purpose |
|-----------|---------|
| EC2 | Hosts Apache Server |
| CloudWatch Agent | Publishes system metrics |
| CloudWatch | Monitoring and Alarms |
| SNS | Notification Service |
| Lambda | Automation Logic |
| Systems Manager | Remote Command Execution |
| IAM Role | Secure AWS Access |

---

# Conclusion

The Low-Level Design provides the complete technical implementation of the CloudOps NOC Automation solution. Each AWS service is configured with defined responsibilities, enabling automated monitoring, alerting, and recovery of the Apache web server. The implementation follows AWS best practices and supports secure, reliable, and maintainable operations.
