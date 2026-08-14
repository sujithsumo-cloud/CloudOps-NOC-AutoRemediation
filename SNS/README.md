# Amazon Simple Notification Service (SNS) Configuration

## Overview

Amazon Simple Notification Service (Amazon SNS) is the messaging and event-distribution service used in the CloudOps NOC Automation project.

SNS receives notifications from Amazon CloudWatch when a configured alarm changes state and distributes those events to the appropriate subscribers.

In this project, SNS has two important responsibilities:

- **P1 – HTTPD Failure:** Distribute the CloudWatch alarm event to AWS Lambda so that Apache can be automatically recovered through Systems Manager, while also notifying the NOC engineer.
- **P2 – CPU Utilization:** Distribute the CloudWatch alarm notification to the NOC engineer for operational investigation.

SNS therefore acts as the **communication and event-distribution layer** between CloudWatch monitoring and the automation/notification components.

---

# 1. Purpose

Amazon SNS is used to:

- Receive CloudWatch alarm notifications.
- Distribute monitoring events to subscribers.
- Send email notifications to the NOC engineer.
- Invoke the Lambda automation workflow for P1 incidents.
- Decouple CloudWatch monitoring from downstream actions.
- Support multiple subscribers for the same monitoring event.
- Provide an event-driven communication mechanism.

---

# 2. SNS Resource Used

## SNS Topic

**Topic Name**

```text
cloudops-sns
```

**Display Name**

```text
NOC-topic
```

The topic acts as the central event-distribution point for the CloudOps NOC workflow.

---

# 3. Project Architecture

```text
                 Amazon CloudWatch
                        │
                        │ Alarm Event
                        ▼
                Amazon SNS Topic
                  cloudops-sns
                        │
             ┌──────────┴──────────┐
             │                     │
             ▼                     ▼
       NOC Engineer              Lambda
          Email                    │
                                   ▼
                           Systems Manager
                                   │
                                   ▼
                           Restart Apache
```

---

# 4. SNS Components

| Component | Project Purpose |
|---|---|
| SNS Topic | Receives CloudWatch alarm events |
| Email Subscription | Sends operational notifications |
| Lambda Subscription | Starts P1 auto-remediation |
| Topic Policy | Controls which services can publish/subscribe |
| Subscription Confirmation | Confirms email delivery destination |

---

# 5. SNS Topic Configuration

| Property | Value |
|---|---|
| Topic Name | `cloudops-sns` |
| Display Name | `NOC-topic` |
| Region | `ap-south-1` |
| Publisher | Amazon CloudWatch |
| Subscribers | NOC Email, AWS Lambda |

The topic is configured in the same AWS Region as the monitoring and automation resources.

---

# 6. P1 – HTTPD Auto-Remediation

The P1 workflow uses SNS as the event bridge between CloudWatch and Lambda.

### Workflow

```text
Apache httpd Failure
        ↓
CloudWatch Agent
        ↓
CloudWatch Metric
        ↓
NOC-cloudops-automate
        ↓
ALARM State
        ↓
Amazon SNS
        ↓
cloudops-sns
        ↓
┌───────┴────────┐
│                │
▼                ▼
Email          Lambda
Alert            │
                 ▼
                SSM
                 │
                 ▼
       systemctl restart httpd
```

### P1 Objective

The objective is to reduce Apache downtime by automatically starting the remediation process when the monitored `httpd` process becomes unavailable.

---

# 7. P2 – CPU Utilization Notification

The P2 CPU monitoring workflow also uses SNS for event distribution.

```text
High CPU Utilization
        ↓
CloudWatch
        ↓
cloudops-cpuutilization
        ↓
ALARM State
        ↓
Amazon SNS
        ↓
NOC Engineer Email
        ↓
Engineer Investigation
```

P2 is an operational monitoring and notification workflow. It is separate from the P1 HTTPD auto-remediation process.

---

# 8. Email Subscription

An email subscription is configured for the SNS topic.

### Purpose

The subscription provides direct operational visibility to the NOC engineer.

The email notification can contain information such as:

- Alarm name
- Alarm state
- EC2 instance
- Metric
- Threshold
- Time of incident
- Recovery status

### Subscription Process

```text
Create SNS Topic
       ↓
Create Email Subscription
       ↓
AWS sends Confirmation Email
       ↓
Administrator confirms subscription
       ↓
Subscription becomes Confirmed
```

An email subscription must be confirmed before SNS can deliver notifications to that email address.

---

# 9. Lambda Subscription

AWS Lambda is configured as an SNS subscriber for the P1 automation workflow.

```text
CloudWatch
    ↓
SNS
    ↓
Lambda
    ↓
SSM Run Command
    ↓
Restart httpd
```

When SNS invokes Lambda, the Lambda function receives the SNS event and processes the alarm information.

### Lambda Function

```text
Cloudops-NOC-automate
```

The Lambda function then uses AWS Systems Manager to execute the required remediation command on the EC2 instance.

---

# 10. SNS Message Flow

The general message flow is:

```text
CloudWatch Alarm
       ↓
SNS Publish
       ↓
SNS Topic
       ↓
Message Distribution
       ├──────────────► Email
       │
       └──────────────► Lambda
```

SNS separates the monitoring layer from the consumers of the monitoring event.

This allows additional subscribers to be added without changing the CloudWatch alarm itself.

---

# 11. CloudWatch Integration

CloudWatch publishes an alarm notification to the SNS topic when the configured alarm action is executed.

For the project:

### P1 Alarm

```text
NOC-cloudops-automate
```

Purpose:

```text
HTTPD Failure → Auto Remediation
```

### P2 Alarm

```text
cloudops-cpuutilization
```

Purpose:

```text
High CPU → Operational Notification
```

Both alarms use SNS as the notification/event-distribution mechanism.

---

# 12. SNS and Lambda Integration

The P1 integration is:

```text
CloudWatch
    ↓
SNS
    ↓
Lambda
    ↓
Systems Manager
    ↓
EC2
```

Lambda receives the SNS event and extracts the required alarm information before starting the remediation workflow.

This event-driven architecture avoids continuous polling by Lambda.

---

# 13. SNS and IAM

SNS access is controlled using AWS IAM and resource-based permissions where applicable.

The project follows the principle of least privilege.

Required permissions should allow only the necessary operations, such as:

- Publishing alarm notifications.
- Invoking the Lambda subscriber.
- Managing the required SNS resources.

No permanent AWS access keys are required for the SNS workflow.

---

# 14. SNS Topic Policy

An SNS topic policy can control which AWS principals are allowed to publish messages to the topic.

Conceptually:

```text
Amazon CloudWatch
        │
        │ Publish
        ▼
   SNS Topic
cloudops-sns
```

The policy should restrict publishing access to the required AWS service and account context.

Example policy structure:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudWatchPublish",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "arn:aws:sns:ap-south-1:ACCOUNT_ID:cloudops-sns"
    }
  ]
}
```

Replace `ACCOUNT_ID` with the appropriate AWS account ID when implementing the policy.

The exact resource-based policy should be validated against the actual AWS account and service configuration before deployment.

---

# 15. SNS Security

The SNS configuration follows these security practices:

- IAM-based access control.
- Restricted topic permissions.
- Confirmed email subscriptions.
- No hardcoded AWS credentials.
- HTTPS-based AWS service communication.
- Least-privilege permissions.
- Controlled Lambda integration.

---

# 16. Notification Example

A P1 recovery notification can communicate the result of the automated remediation.

Example:

```text
NOC AUTO REMEDIATION - SUCCESS

Instance : cloudops-server

Service  : httpd

Action   : systemctl restart httpd

Result   : Apache service is ACTIVE

Status   : Incident resolved automatically
```

The actual notification content depends on the Lambda implementation and SNS message configuration.

---

# 17. SNS Verification

### Check Topic

Verify that the topic exists:

```text
cloudops-sns
```

### Check Subscriptions

Verify:

```text
Email → Confirmed
Lambda → Connected
```

### Verify Topic Region

```text
ap-south-1
```

### Verify CloudWatch Alarm Action

Confirm that the alarms reference the SNS topic.

---

# 18. Testing SNS

SNS should be tested independently before testing the complete automation workflow.

### Test Sequence

```text
CloudWatch Alarm
       ↓
SNS Topic
       ↓
Email
       ↓
Lambda
```

For P1:

```text
SNS
 ↓
Lambda
 ↓
SSM
 ↓
Apache Restart
```

Expected results:

- SNS receives the CloudWatch event.
- Email notification is delivered.
- Lambda is invoked for the P1 workflow.
- Lambda starts the SSM command.
- Apache recovery is performed.
- Recovery status is recorded.

---

# 19. Troubleshooting

## Email Not Received

Check:

1. SNS topic exists.
2. Email subscription exists.
3. Subscription status is `Confirmed`.
4. Correct email address is configured.
5. Check the email spam/junk folder.
6. Verify the SNS topic is receiving messages.

---

## Lambda Not Invoked

Check:

1. Lambda function exists.
2. SNS subscription exists.
3. SNS subscription is confirmed/active.
4. Lambda has the appropriate invocation permission.
5. CloudWatch alarm is publishing to the correct SNS topic.
6. Check Lambda CloudWatch Logs.

---

## CloudWatch Alarm Does Not Send SNS Notification

Check:

1. Alarm action is configured.
2. Correct SNS topic ARN is configured.
3. Alarm entered the expected state.
4. SNS topic exists in the correct Region.
5. CloudWatch alarm history.

---

## SNS Topic Exists but No Event Arrives

Check the complete chain:

```text
CloudWatch Alarm
       ↓
Alarm Action
       ↓
SNS Topic ARN
       ↓
SNS Topic
       ↓
Subscription
```

An error at any stage can prevent the notification from reaching the final subscriber.

---

# 20. Operational Best Practices

- Use descriptive SNS topic names.
- Keep P1 and P2 workflows clearly documented.
- Confirm email subscriptions.
- Use least-privilege permissions.
- Restrict SNS topic publishing permissions.
- Monitor Lambda invocation failures.
- Test notification delivery periodically.
- Keep SNS configuration under version control.
- Avoid sending unnecessary high-volume notifications.
- Document all production subscribers.

---

# 21. Repository Structure

Recommended SNS repository structure:

```text
sns/
│
├── README.md
│
├── topic/
│   ├── topic-configuration.md
│   └── topic-policy.json
│
├── subscriptions/
│   ├── email-subscription.md
│   └── lambda-subscription.md
│
├── messages/
│   ├── p1-httpd-success.md
│   ├── p1-httpd-failure.md
│   └── p2-cpu-alert.md
│
├── testing/
│   └── sns-test-procedure.md
│
└── troubleshooting/
    └── sns-troubleshooting.md
```

---

# 22. Integration With the Seven Project Services

SNS is one component of the finalized seven-service AWS architecture.

| Service | Relationship With SNS |
|---|---|
| IAM | Controls permissions |
| EC2 | Hosts the monitored Apache service |
| VPC | Provides the EC2 network environment |
| CloudWatch | Publishes alarm events |
| SNS | Distributes monitoring events |
| Systems Manager | Performs EC2 command execution |
| Lambda | Performs P1 automation |

Complete architecture:

```text
IAM
 │
 ├── EC2
 │     │
 │     └── CloudWatch Agent
 │
 ├── CloudWatch
 │     │
 │     └── Alarms
 │
 ├── SNS
 │     ├── Email
 │     └── Lambda
 │             │
 │             ▼
 │          SSM
 │             │
 │             ▼
 │            EC2
 │
 └── VPC
```

---

# 23. Project Role Summary

Amazon SNS is the **event-distribution and notification layer** of the CloudOps NOC Automation project.

Its role can be summarized as:

```text
RECEIVE
   ↓
DISTRIBUTE
   ↓
NOTIFY
   ↓
TRIGGER
```

For P1:

```text
HTTPD Failure
     ↓
CloudWatch
     ↓
SNS
     ↓
Lambda
     ↓
SSM
     ↓
Apache Restart
```

For P2:

```text
High CPU
     ↓
CloudWatch
     ↓
SNS
     ↓
NOC Notification
```

---

# 24. Final Summary

Amazon SNS provides the communication layer required to connect CloudWatch monitoring with the project's notification and automation workflows.

When the **P1 HTTPD alarm** detects an Apache failure, CloudWatch publishes the event to the `cloudops-sns` topic. SNS distributes the event to the configured subscribers, including Lambda and the NOC engineer notification channel. Lambda then coordinates the Systems Manager remediation process.

For **P2 CPU utilization**, SNS distributes the CloudWatch alarm notification to the NOC engineer for investigation.

This design provides a loosely coupled, event-driven architecture in which monitoring, notification, and remediation components can operate independently while working together as a complete CloudOps NOC workflow.
