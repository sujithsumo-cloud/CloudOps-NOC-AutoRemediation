# Amazon Simple Notification Service (SNS)

## Overview

Amazon Simple Notification Service (Amazon SNS) is a fully managed messaging service that enables reliable communication between AWS services and subscribers.

In this project, Amazon SNS acts as the notification and event distribution service. When the CloudWatch Alarm enters the **ALARM** state, it publishes a notification to an SNS Topic. The topic then sends an email notification to the administrator and invokes the AWS Lambda function to start the automated remediation process.

---

# Purpose

Amazon SNS is used to:

- Receive notifications from CloudWatch Alarms
- Send email alerts to the NOC Engineer
- Trigger AWS Lambda automatically
- Decouple monitoring from remediation
- Enable multiple subscribers for a single event

---

# Project Architecture

CloudWatch Alarm
        │
        ▼
   Amazon SNS Topic
      ┌──────────┐
      ▼          ▼
 Email Alert   AWS Lambda
                  │
                  ▼
        AWS Systems Manager
                  │
                  ▼
      Restart Apache Service

---

# Components Used

| Component | Purpose |
|-----------|---------|
| SNS Topic | Receives alarm notifications |
| Email Subscription | Sends alert email |
| Lambda Subscription | Invokes Lambda for auto-remediation |

---

# Notification Workflow

1. Apache service becomes unavailable.
2. CloudWatch detects the issue.
3. CloudWatch Alarm enters the ALARM state.
4. CloudWatch publishes a message to the SNS Topic.
5. SNS sends an email notification to the administrator.
6. SNS invokes the AWS Lambda function.
7. Lambda starts AWS Systems Manager.
8. Systems Manager restarts the Apache service.

---

# Benefits

- Real-time notifications
- Automatic event distribution
- Supports multiple subscribers
- Reliable message delivery
- Decouples AWS services
- Simplifies automation workflows

---

# AWS Services Integrated

- Amazon CloudWatch
- Amazon SNS
- AWS Lambda
- AWS Systems Manager
- Amazon EC2

---

# Best Practices

- Confirm email subscriptions after creation.
- Use meaningful topic names.
- Apply least-privilege IAM permissions.
- Monitor failed deliveries.
- Test notifications regularly.

---

# Repository Files

| File | Description |
|------|-------------|
| topic.md | SNS Topic configuration |
| email-subscription.md | Email subscription details |
| screenshots/ | SNS console and email screenshots |
