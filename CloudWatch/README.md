# Amazon CloudWatch

## Overview

Amazon CloudWatch is the monitoring and observability service used in this project. It continuously monitors the health and performance of the Amazon EC2 instance hosting the Apache web server.

CloudWatch collects infrastructure metrics, visualizes them through dashboards, evaluates alarm conditions, and initiates the automated remediation workflow whenever a predefined threshold is exceeded.

In this project, CloudWatch acts as the monitoring engine that detects failures and starts the recovery process.

---

# Purpose

The primary objectives of using Amazon CloudWatch are:

- Monitor the health of the EC2 instance
- Monitor Apache server performance
- Collect infrastructure metrics
- Display real-time dashboards
- Generate alarms when thresholds are exceeded
- Trigger automatic remediation
- Reduce application downtime

---

# Project Architecture

                Amazon EC2
        (Apache Web Server)
                     │
                     ▼
         CloudWatch Agent (Linux)
                     │
                     ▼
          Amazon CloudWatch
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
 Dashboard             CloudWatch Alarm
                               │
                               ▼
                           Amazon SNS
                               │
                               ▼
                          AWS Lambda
                               │
                               ▼
                     AWS Systems Manager
                               │
                               ▼
                    Restart Apache Service

---

# CloudWatch Components Used

| Component | Purpose |
|-----------|---------|
| Metrics | Monitor EC2 performance |
| Dashboard | Visualize server health |
| Alarm | Detect abnormal conditions |
| CloudWatch Agent | Collect additional OS metrics |

---

# Metrics Collected

The following metrics are monitored during this project.

### Default AWS Metrics

- CPU Utilization
- Network In
- Network Out
- Disk Read Operations
- Disk Write Operations
- Status Check Failed

### CloudWatch Agent Metrics

- Memory Utilization
- Disk Usage
- Swap Usage (optional)
- Disk I/O
- Running Processes (optional)

---

# Dashboard

The CloudWatch Dashboard provides a centralized view of the EC2 instance.

Dashboard widgets include:

- CPU Utilization
- Memory Usage
- Disk Usage
- Network Traffic
- Status Checks

This dashboard allows operators to monitor infrastructure health without logging into the server.

---

# CloudWatch Alarm

The CloudWatch Alarm continuously evaluates incoming metrics.

When the configured threshold is exceeded:

1. Alarm changes to ALARM state.
2. Amazon SNS receives the notification.
3. AWS Lambda is invoked.
4. Lambda starts AWS Systems Manager.
5. Systems Manager restarts the Apache service.
6. CloudWatch detects recovery and returns to the OK state.

---

# CloudWatch Agent

The CloudWatch Agent is installed on the Amazon EC2 instance.

Purpose:

- Collect memory metrics
- Collect disk metrics
- Collect operating system statistics
- Send custom metrics to CloudWatch

Without the CloudWatch Agent, AWS provides only the default infrastructure metrics.

---

# AWS Services Integrated

- Amazon EC2
- Amazon CloudWatch
- Amazon SNS
- AWS Lambda
- AWS Systems Manager
- AWS IAM

---

# Monitoring Workflow

EC2 Instance

↓

CloudWatch Agent

↓

CloudWatch Metrics

↓

Dashboard

↓

Alarm Evaluation

↓

Alarm Trigger

↓

SNS Notification

↓

Lambda Function

↓

Systems Manager

↓

Apache Restart

---

# Benefits

- Continuous monitoring
- Real-time visualization
- Automated alerting
- Reduced downtime
- Faster incident response
- Centralized monitoring

---

# Best Practices

- Configure meaningful alarm thresholds.
- Monitor both infrastructure and operating system metrics.
- Review dashboards regularly.
- Enable automated remediation for critical services.
- Retain monitoring data according to organizational requirements.
- Validate alarm actions periodically.

---

# Repository Files

| File | Description |
|------|-------------|
| dashboard.json | Exported CloudWatch dashboard |
| cloudwatch-agent-config.json | CloudWatch Agent configuration |
| alarm-configuration.md | Alarm configuration details |
| metrics.md | Metrics explanation |
| screenshots/ | CloudWatch console screenshots |
