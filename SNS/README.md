# Amazon SNS — Operational Notification and Escalation

## Overview

Amazon Simple Notification Service (Amazon SNS) is the **operational notification layer** of the CloudOps NOC Automation V2.0 project.

In the current V2.0 architecture, SNS is **not** used between CloudWatch and Lambda.

The current event path is:

```text
CloudWatch Alarm
      │
      ▼
Direct Alarm Event
      │
      ▼
Lambda
```

After Lambda processes the incident, Lambda publishes operational notifications to the SNS topic.

The current notification path is:

```text
Lambda
   │
   ▼
Amazon SNS
   │
   ▼
Configured Subscriber
   │
   ▼
Operations Engineer
```

In simple terms:

> **CloudWatch detects. Lambda decides. SSM executes. SNS communicates the result.**

---

## 1. Role in the Project

SNS is responsible for:

- Receiving incident notifications published by Lambda.
- Delivering notifications to configured subscribers.
- Reporting that a P1 incident has been detected and recovery has started.
- Reporting successful P1 recovery.
- Reporting failed P1 recovery and escalation.
- Delivering P2 high-CPU diagnostic notifications.
- Delivering the final P2 diagnostic report for engineer review.

SNS is the **notification transport**.

It is not the monitoring service, decision engine, remediation engine, or Lambda trigger in the current V2.0 design.

---

## 2. SNS Resource

### SNS Topic

```text
Topic Name   : cloudops-sns
Display Name : NOC-topic
Region       : ap-south-1
```

The Lambda function receives the SNS topic ARN through the environment variable:

```text
TOPIC_ARN
```

The Lambda code publishes notifications to this topic through Boto3.

Conceptually:

```text
Lambda
   │
   ▼
Boto3 SNS Client
   │
   ▼
sns:Publish API
   │
   ▼
cloudops-sns
```

---

## 3. Correct V2.0 Architecture

The current project architecture is:

```text
                    CloudWatch
                        │
                        │ Direct Alarm Event
                        ▼
                      Lambda
                        │
             ┌──────────┴──────────┐
             │                     │
             ▼                     ▼
            SSM                   SNS
             │                     │
             ▼                     ▼
            EC2             Operations Engineer
```

For P1:

```text
HTTPD Failure
      │
      ▼
CloudWatch Alarm
      │
      ▼
Lambda
      │
      ▼
SSM Recovery
      │
      ▼
Verification
      │
      ▼
Stability Check
      │
      ▼
SNS Notification
```

For P2:

```text
High CPU
   │
   ▼
CloudWatch Alarm
   │
   ▼
Lambda
   │
   ▼
SSM Diagnostics
   │
   ▼
SNS Diagnostic Report
   │
   ▼
Engineer Review
```

---

## 4. Important Architecture Correction

The previous project documentation described this flow:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

That is **not the current V2.0 architecture**.

The current implementation uses:

```text
CloudWatch
   │
   ▼
Lambda
   │
   ▼
SNS
```

Therefore:

- CloudWatch does not use SNS to trigger the Lambda function in the current design.
- Lambda is not treated as an SNS subscriber for the incident-processing workflow.
- Lambda receives the CloudWatch Alarm event directly.
- Lambda publishes the operational result to SNS after incident processing.

---

## 5. Lambda and SNS Integration

The Lambda function creates an SNS client using Boto3:

```python
sns = boto3.client("sns")
```

The Lambda environment contains:

```text
TOPIC_ARN
```

The notification function publishes using the SNS API:

```python
sns.publish(
    TopicArn=TOPIC_ARN,
    Subject=subject,
    Message=body,
)
```

Conceptually:

```text
Lambda Python Code
       │
       ▼
      Boto3
       │
       ▼
   SNS Publish API
       │
       ▼
   cloudops-sns
       │
       ▼
   Subscriber
```

Lambda decides **when and what to notify**.

SNS is responsible for **delivering the published message**.

---

## 6. P1 — Initial Incident Notification

When Lambda identifies an actionable P1 HTTPD incident, it first publishes an incident notification indicating that recovery has started.

Conceptually:

```text
HTTPD Failure
     │
     ▼
P1 Detected
     │
     ▼
Lambda
     │
     ▼
SNS
     │
     ▼
"HTTPD Down — Recovery Initiated"
```

The notification can include information such as:

- Incident ID
- Priority and severity
- HTTPD service
- Detection time
- Alarm state and reason
- EC2 instance details
- CloudWatch alarm details
- Recovery status

The engineer is therefore informed that the incident has been detected and that automated recovery is in progress.

---

## 7. P1 — Successful Recovery Notification

After the P1 recovery command succeeds, Lambda verifies HTTPD and performs the stability verification.

If HTTPD is confirmed active and stable:

```text
Detected
   │
   ▼
Recovered
   │
   ▼
Resolved
   │
   ▼
SNS
   │
   ▼
Success Notification
```

The final message can contain:

- Initial SSM command result
- Verification status
- Stability verification status
- Final HTTPD state
- Recovery status
- Resolution time
- Whether manual action is required

For successful recovery:

```text
Manual Action = Not Required
```

---

## 8. P1 — Failure and Escalation Notification

The P1 workflow uses a bounded recovery policy.

If HTTPD cannot be confirmed active after the initial attempt and the configured retry:

```text
Initial Recovery
      │
      ▼
Failed
      │
      ▼
Retry
      │
      ▼
Failed
      │
      ▼
Escalated
      │
      ▼
SNS
      │
      ▼
Engineer
```

The notification indicates that:

- Automatic remediation failed.
- HTTPD could not be confirmed active.
- Manual investigation is required.

Important distinction:

> **SNS does not perform escalation logic.**

Lambda determines that the incident must be escalated.

SNS delivers the escalation notification to the engineer.

---

## 9. P2 — Initial Diagnostic Notification

P2 is based on the alarm:

```text
cpu alert
```

Metric:

```text
CPUUtilization
```

Configured project threshold:

```text
> 50%
```

When Lambda identifies P2, it publishes an initial notification indicating that CPU diagnostics are being collected.

Conceptually:

```text
High CPU
   │
   ▼
P2 Detected
   │
   ▼
Lambda
   │
   ▼
SNS
   │
   ▼
"CPU Diagnostics In Progress"
```

P2 does not perform an automatic restart.

---

## 10. P2 — Diagnostic Report

Lambda uses Systems Manager to collect evidence such as:

```text
uptime / load
top CPU-consuming processes
memory information
```

After diagnosis:

```text
P2
 │
 ▼
SSM Diagnostics
 │
 ▼
Diagnostic Output
 │
 ▼
Lambda
 │
 ▼
SNS
 │
 ▼
Engineer Review
```

The final P2 notification indicates:

```text
Diagnosed
   ↓
No automatic fix applied
   ↓
Manual review required
```

This supports the project principle:

> **Detection does not automatically mean remediation.**

---

## 11. P1 vs P2 SNS Usage

| Incident | SNS Purpose |
|---|---|
| P1 HTTPD detected | Notify that automated recovery has started |
| P1 recovered | Report successful recovery and verification |
| P1 recovery failed | Deliver escalation notification |
| P2 high CPU detected | Notify that diagnostics are being collected |
| P2 diagnosis complete | Deliver diagnostic evidence for manual review |

SNS is therefore used for **operational communication across both incident types**.

---

## 12. Notification Content

The Lambda implementation builds detailed incident notifications.

Typical information includes:

```text
Incident ID
Priority
Severity
Environment
Service
Detection Time
Alarm State
Alarm Reason
AWS Region
EC2 Instance
Private IP
Availability Zone
Alarm Name
Metric
Threshold
SNS Topic
SSM Command ID
Verification Status
Stability Status
Recovery Status
Resolution Time
Manual Action
```

For P2, the notification can additionally include the captured diagnostic output.

This provides the engineer with operational context rather than sending only a simple alarm name.

---

## 13. SNS Email Subscription

An email subscription can be used to deliver SNS notifications to an operations engineer.

Conceptually:

```text
SNS Topic
   │
   ▼
Email Subscription
   │
   ▼
Confirmation Required
   │
   ▼
Confirmed
   │
   ▼
Notification Delivery
```

An email subscription must be confirmed before SNS can deliver messages to that address.

Verification should include:

```text
SNS Topic      : Exists
Subscription   : Confirmed
Region         : ap-south-1
```

---

## 14. SNS and IAM

Lambda must be authorized to publish to the SNS topic.

Conceptually:

```text
Lambda Execution Role
        │
        ▼
       IAM
        │
        ▼
sns:Publish allowed?
      /       \
    YES        NO
     │          │
     ▼          ▼
   Publish   AccessDenied
```

The project follows the **Principle of Least Privilege**.

Lambda should receive permission only for the SNS topic and operations required by the workflow.

A broad administrator policy is not required for SNS notification publishing.

---

## 15. Security Considerations

SNS security considerations include:

- IAM-based authorization.
- Least-privilege `sns:Publish` permission.
- Restricted access to the SNS topic.
- Confirmed subscriber endpoints.
- No hardcoded AWS access keys.
- Protection of sensitive information in notification content.
- Keeping the SNS topic ARN in configuration/environment settings rather than embedding credentials in code.

The SNS topic should be used only by identities and workflows that require notification access.

---

## 16. SNS vs Escalation

These two concepts should not be confused.

### Escalation

An operational decision:

> Automation cannot safely resolve the incident, so human investigation is required.

### SNS

The AWS service used to communicate that decision.

Conceptually:

```text
Automation Failure
       │
       ▼
Lambda Decides to Escalate
       │
       ▼
SNS Publishes Notification
       │
       ▼
Engineer Receives Message
```

Therefore:

> **Escalation is the process; SNS is the notification mechanism.**

---

## 17. SNS vs CloudWatch

CloudWatch and SNS have different responsibilities.

```text
CloudWatch
= Detect and evaluate

SNS
= Deliver notifications
```

CloudWatch answers:

> **Has the monitored condition crossed the configured threshold?**

SNS answers:

> **Who needs to receive the resulting operational message?**

---

## 18. SNS vs Lambda

Lambda and SNS also have different responsibilities.

```text
Lambda
= Decide and orchestrate

SNS
= Deliver the message
```

Lambda determines:

- Is the alarm actionable?
- Is it P1 or P2?
- Should recovery or diagnosis run?
- Did recovery succeed?
- Is escalation required?

SNS does not make these decisions.

---

## 19. Testing SNS

SNS can be tested as a notification component independently from the full incident workflow.

### Basic SNS verification

```text
Lambda / Authorized Publisher
          │
          ▼
       SNS Topic
          │
          ▼
   Confirmed Subscriber
          │
          ▼
  Notification Received
```

### Full P1 verification

```text
CloudWatch
   │
   ▼
Lambda
   │
   ▼
SSM
   │
   ▼
HTTPD Recovery
   │
   ▼
SNS
   │
   ▼
P1 Notification
```

Expected result:

- Lambda publishes the notification.
- SNS receives the publication.
- The configured subscriber receives the message.
- The notification contains the expected incident status.

---

## 20. Troubleshooting

### Notification Not Received

Check:

1. `cloudops-sns` exists.
2. `TOPIC_ARN` in Lambda points to the correct topic.
3. Lambda has `sns:Publish` permission.
4. The subscription is confirmed.
5. The subscriber endpoint is correct.
6. Lambda logs show whether `sns.publish()` succeeded or failed.
7. Check the email spam/junk folder where applicable.

### Lambda Works but SNS Fails

Check:

```text
Lambda
   │
   ▼
TOPIC_ARN
   │
   ▼
IAM Permission
   │
   ▼
sns:Publish
   │
   ▼
SNS Topic
```

### Important

Do not troubleshoot Lambda invocation through an SNS subscription for the current V2.0 design.

Lambda is triggered directly by the CloudWatch Alarm event.

---

## 21. Integration with the Seven AWS Services

| Service | Relationship with SNS |
|---|---|
| IAM | Authorizes Lambda to publish |
| EC2 | Hosts the workload described in notifications |
| VPC | Provides the network environment for EC2 |
| CloudWatch | Detects the incident before Lambda processing |
| Lambda | Builds and publishes SNS notifications |
| Systems Manager | Performs P1 remediation and P2 diagnostics |
| SNS | Delivers operational results to subscribers |

The current architecture is:

```text
EC2
 │
 ▼
CloudWatch
 │
 ▼
Lambda
 ├──────────► SSM ──────────► EC2
 │
 └──────────► SNS ──────────► Engineer
```

IAM authorizes the AWS API interactions, and VPC provides the EC2 network foundation.

---

## 22. Three-Level Interview Answer

### Level 1

> **SNS is the operational notification layer of the project.**

### Level 2

> **Lambda publishes P1 recovery results, P1 escalation messages, and P2 diagnostic reports to SNS, and SNS delivers those notifications to the configured subscribers.**

### Level 3

> **The Lambda Python function creates a Boto3 SNS client and calls `sns.publish()` using the SNS topic ARN stored in `TOPIC_ARN`. SNS is downstream of Lambda in the current V2.0 architecture; it does not trigger Lambda. Lambda decides the incident outcome, while SNS provides the notification delivery mechanism.**

---

## 23. Operational Summary

SNS can be remembered as:

```text
RECEIVE FROM LAMBDA
        │
        ▼
      PUBLISH
        │
        ▼
      DELIVER
        │
        ▼
     NOTIFY HUMAN
```

The service does not:

- Detect HTTPD failure.
- Evaluate CloudWatch alarms.
- Parse alarm events.
- Decide P1 or P2.
- Restart HTTPD.
- Execute SSM commands.

Those responsibilities belong to other layers of the architecture.

---

## 24. Final Summary

Amazon SNS provides the **operational communication layer** of CloudOps NOC Automation V2.0.

The correct current flow is:

```text
CloudWatch
     │
     ▼
Lambda
     │
     ├────────────► SSM
     │                │
     │                ▼
     │               EC2
     │
     ▼
    SNS
     │
     ▼
Operations Engineer
```

SNS is used to deliver:

- P1 incident detection/recovery-in-progress notifications.
- P1 successful recovery notifications.
- P1 failed-recovery escalation notifications.
- P2 diagnostic-in-progress notifications.
- P2 final diagnostic reports requiring engineer review.

---

## Key Design Statement

> **SNS does not trigger Lambda in the current V2.0 architecture. CloudWatch sends the alarm event directly to Lambda; Lambda processes the incident and then publishes the operational result to SNS for delivery to the engineer.**
