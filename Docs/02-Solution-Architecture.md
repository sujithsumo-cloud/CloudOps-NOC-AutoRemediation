# Solution Architecture

## Project Title

CloudOps NOC Automation using AWS CloudWatch, SNS, Lambda, and Systems Manager

---

# 1. Overview

The CloudOps NOC Automation solution is designed to continuously monitor the health of an Apache web server running on an Amazon EC2 instance. The architecture follows an event-driven approach where AWS managed services work together to detect service failures, automatically recover the service, and notify the operations team.

The solution minimizes manual intervention, reduces service downtime, and demonstrates an automated Network Operations Center (NOC) workflow using AWS native services.

---

# 2. Architecture Objective

The objective of this architecture is to:

- Monitor Apache service availability
- Detect service failures automatically
- Trigger an automated recovery process
- Restart the failed Apache service
- Notify the operations team after remediation
- Maintain monitoring dashboards and logs for operational visibility

---

# 3. AWS Services Used

| AWS Service | Purpose |
|------------|---------|
| Amazon EC2 | Hosts the Apache web server |
| Amazon CloudWatch | Monitors server metrics and generates alarms |
| Amazon CloudWatch Agent | Publishes system-level metrics to CloudWatch |
| Amazon SNS | Sends notifications and triggers Lambda |
| AWS Lambda | Executes automation logic |
| AWS Systems Manager (SSM) | Executes remote commands on EC2 |
| IAM | Provides secure permissions between AWS services |

---

# 4. Architecture Components

## Amazon EC2

The EC2 instance hosts the Apache HTTP server and runs both the CloudWatch Agent and Systems Manager Agent.

### Instance Details

- Operating System: Amazon Linux 2023
- Instance ID: i-0b7d483631875bb1c
- IAM Role: cloudops-EC2-inline-role
- Apache Service: httpd

---

## CloudWatch Agent

The CloudWatch Agent collects operating system metrics from the EC2 instance.

Collected metrics include:

- CPU Utilization
- Memory Utilization
- Disk Usage
- Network Traffic (ens5)
- Apache Process Status

The metrics are published to the CloudWatch namespace:

CWAgent

---

## Amazon CloudWatch

CloudWatch receives all metrics from the CloudWatch Agent.

Responsibilities include:

- Monitoring EC2 health
- Monitoring Apache process
- Displaying metrics in dashboards
- Triggering alarms
- Recording metric history

Configured Resources

Dashboard

cloudops-NOC-dashboard

Alarms

- NOC-cloudops-automate
- cloudops-cpuutilization

---

## Amazon SNS

Amazon SNS acts as the messaging service.

When CloudWatch detects a service failure, the alarm publishes a message to the SNS topic.

SNS Topic

cloudops-sns

Display Name

NOC-topic

Subscribers

- Email Notification
- AWS Lambda Function

---

## AWS Lambda

Lambda acts as the automation engine.

Once triggered by SNS, Lambda performs the following actions:

1. Reads the event
2. Identifies the target EC2 instance
3. Calls AWS Systems Manager Run Command
4. Restarts Apache service
5. Checks command execution result
6. Sends success notification through SNS

Lambda Function

Cloudops-NOC-automate

Runtime

Python

---

## AWS Systems Manager

Systems Manager securely executes commands on the EC2 instance without requiring SSH access.

The Lambda function sends the following command:

systemctl restart httpd

The SSM Agent running on EC2 receives the command and executes it.

---

## IAM

IAM controls secure communication between all AWS services.

The EC2 instance uses an Inline IAM Policy that provides permissions for:

- CloudWatch Metrics
- CloudWatch Logs
- Systems Manager
- Session Manager
- Parameter Store

Lambda uses its own execution role to access:

- SSM
- SNS
- CloudWatch Logs

---

# 5. End-to-End Workflow

The solution follows the sequence below.

Step 1

Apache service stops unexpectedly.

↓

Step 2

CloudWatch Agent detects that the Apache process is unavailable.

↓

Step 3

CloudWatch Alarm changes to the ALARM state.

↓

Step 4

CloudWatch publishes an event to the SNS topic.

↓

Step 5

SNS performs two actions:

- Sends an email notification
- Invokes the Lambda function

↓

Step 6

Lambda starts execution.

↓

Step 7

Lambda calls Systems Manager Run Command.

↓

Step 8

Systems Manager sends the restart command to the EC2 instance.

↓

Step 9

SSM Agent executes:

systemctl restart httpd

↓

Step 10

Apache service becomes active.

↓

Step 11

Lambda verifies successful execution.

↓

Step 12

SNS sends a success notification to the operations team.

---

# 6. Solution Benefits

The architecture provides several operational benefits.

- Automatic incident recovery
- Reduced service downtime
- Faster response to failures
- Improved operational efficiency
- Reduced manual intervention
- Centralized monitoring
- Secure remote administration
- Event-driven automation
- Easily scalable for multiple EC2 instances

---

# 7. Architecture Summary

The solution integrates Amazon EC2, CloudWatch, SNS, Lambda, and Systems Manager into a fully automated monitoring and remediation workflow.

CloudWatch continuously monitors the server health and detects failures. Amazon SNS distributes alerts, while AWS Lambda coordinates the recovery process. AWS Systems Manager securely executes the required commands on the EC2 instance, restoring the Apache service automatically. The architecture ensures continuous service availability while providing monitoring, logging, and notification capabilities required for a Network Operations Center (NOC) environment.
