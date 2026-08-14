# Document 2 – Solution Architecture

**Project Title:** CloudOps NOC Automation using AWS CloudWatch, Lambda, Amazon SNS, and AWS Systems Manager (SSM)

| Document Information | Details |
| -------------------- | ------- |
| Document Name | Solution Architecture |
| Version | 2.0 |
| Project Type | AWS Cloud Infrastructure Automation |
| Prepared By | Sujith |
| Date | August 2026 |
| Status | Final |

---

# 1. Overview

The CloudOps NOC Automation solution is designed to monitor important conditions within an Amazon EC2 environment and automatically respond to defined incidents.

The architecture follows an event-driven NOC model. Monitoring conditions are evaluated by Amazon CloudWatch. When an actionable alarm enters the ALARM state, the event is processed by AWS Lambda. Based on the incident priority, Lambda either performs controlled automatic recovery or collects diagnostic information and escalates the incident for manual review.

The finalized solution contains two operational paths:

- **P1 – Critical:** Apache HTTP Server (httpd) failure with automatic recovery and stability verification.
- **P2 – High:** EC2 CPU utilization above the defined threshold with diagnostic collection and manual escalation.

Unknown or unsupported alarm names are intentionally ignored so that test or unrelated events cannot initiate remediation or notifications.

---

# 2. Architecture Objective

The objectives of the solution architecture are to:

- Continuously monitor important EC2 and application conditions.
- Detect Apache HTTP Server failures automatically.
- Automatically recover Apache when a P1 incident occurs.
- Verify that the recovered service remains stable.
- Detect high CPU utilization as a P2 incident.
- Collect useful diagnostic information for P2 incidents.
- Avoid unsafe automatic remediation for CPU incidents.
- Escalate incidents that require human investigation.
- Provide structured operational notifications.
- Maintain visibility into monitoring and automation activity.

---

# 3. AWS Services Used

| AWS Service | Purpose |
| ----------- | ------- |
| Amazon EC2 | Hosts the monitored operating environment and Apache HTTP Server. |
| Amazon CloudWatch | Collects and evaluates monitoring data and generates alarms. |
| Amazon CloudWatch Agent | Publishes operating-system and application-related metrics. |
| Amazon SNS | Delivers operational notifications and connects alarm events to the automation workflow. |
| AWS Lambda | Classifies incidents and coordinates P1 recovery or P2 diagnosis. |
| AWS Systems Manager (SSM) | Executes approved commands and diagnostic commands on the EC2 instance. |
| AWS IAM | Controls permissions required by AWS services and the monitored environment. |
| Amazon CloudWatch Logs | Provides operational logs for Lambda execution and automation troubleshooting. |

---

# 4. Architecture Components

## 4.1 Amazon EC2

The EC2 environment hosts the Apache HTTP Server and the agents required for monitoring and remote management.

The monitored environment provides:

- Apache HTTP Server (`httpd`).
- CloudWatch Agent for metric collection.
- Systems Manager Agent for remote command execution.
- Operating-system information used during P2 CPU diagnosis.

The EC2 environment is the target of both incident monitoring and approved automated actions.

---

## 4.2 CloudWatch Agent

The CloudWatch Agent collects relevant operating-system and application metrics from the EC2 environment.

The monitoring data supports conditions such as:

- CPU utilization.
- Memory utilization.
- Disk-related metrics.
- Network-related metrics.
- Apache process availability.

The collected data is made available to Amazon CloudWatch for monitoring, visualization, and alarm evaluation.

---

## 4.3 Amazon CloudWatch

Amazon CloudWatch is responsible for monitoring the environment and determining when defined incident conditions occur.

CloudWatch provides:

- Metric collection and evaluation.
- Alarm state management.
- Monitoring dashboards.
- Historical monitoring visibility.
- Event generation when actionable conditions enter the ALARM state.

The finalized solution uses CloudWatch alarms for the two approved incident paths:

- **P1:** Apache HTTP Server availability failure.
- **P2:** CPU utilization above 50%.

---

## 4.4 Amazon SNS

Amazon SNS provides the notification layer for the NOC solution.

SNS is used to:

- Deliver incident detection notifications.
- Deliver P1 recovery/resolution notifications.
- Deliver P1 escalation notifications when automatic recovery fails.
- Deliver P2 diagnostic reports requiring manual review.
- Forward actionable alarm events into the automation workflow.

The notification content provides structured incident information such as incident ID, priority, severity, detection information, AWS environment information, affected instance information, alarm details, automation status, and recovery or diagnostic results.

---

## 4.5 AWS Lambda

AWS Lambda acts as the central incident-processing and automation component.

When an actionable CloudWatch alarm event is received, Lambda:

1. Parses the CloudWatch alarm event.
2. Validates the alarm state.
3. Identifies whether the alarm belongs to the approved P1 or P2 scope.
4. Ignores unknown or unsupported alarms.
5. Creates an incident identifier for actionable incidents.
6. Retrieves the relevant EC2 instance information.
7. Executes the appropriate incident workflow.
8. Sends structured notifications through Amazon SNS.
9. Records execution details in CloudWatch Logs.

Lambda therefore provides a single controlled entry point for the NOC automation workflow.

---

## 4.6 AWS Systems Manager

AWS Systems Manager provides secure remote command execution on the EC2 environment.

For P1 incidents, Systems Manager is used to:

- Perform the approved Apache recovery action.
- Verify that Apache is active.
- Perform a stability verification after recovery.

For P2 incidents, Systems Manager is used to collect diagnostic information, including:

- System uptime and load.
- Top CPU-consuming processes.
- Memory utilization.

The P2 workflow does not automatically restart processes or perform destructive remediation.

---

## 4.7 AWS IAM

IAM provides controlled access between the AWS services involved in the automation workflow.

Permissions are separated according to the responsibilities of the EC2 environment and Lambda automation.

The architecture follows the principle of least privilege so that:

- EC2 receives only the permissions required for monitoring and Systems Manager operation.
- Lambda receives the permissions required to process incidents, execute approved Systems Manager actions, retrieve required information, and publish notifications.
- AWS services can communicate without requiring unnecessary administrative access.

---

## 4.8 Amazon CloudWatch Logs

CloudWatch Logs provides operational visibility into Lambda execution.

The logs support troubleshooting by recording events such as:

- CloudWatch alarm parsing.
- Incident classification.
- Incident ID creation.
- Notification activity.
- Systems Manager command IDs.
- Command execution status.
- Recovery verification.
- Stability verification.
- P2 diagnostic execution.
- Unknown alarm handling.

This provides an operational audit trail for the automation workflow.

---

# 5. Incident Architecture

The solution separates incident handling into two controlled paths.

## 5.1 P1 – Critical Apache Recovery

P1 represents a critical Apache HTTP Server availability failure.

The P1 workflow is:

```text
Apache service failure
        ↓
CloudWatch detects failed Apache condition
        ↓
CloudWatch Alarm → ALARM
        ↓
Event delivered to NOC automation
        ↓
Lambda classifies incident as P1
        ↓
Incident ID created
        ↓
Detection notification sent
        ↓
SSM Run Command
        ↓
Apache recovery action
        ↓
Initial service verification
        ↓
15-second stability verification
        ↓
 ┌───────────────┴───────────────┐
 ↓                               ↓
Verified                         Failed
 ↓                               ↓
P1 Resolved                      P1 Escalated
Notification                     Notification
```

The P1 path is intentionally limited to controlled Apache recovery. The service must be verified before the incident is considered resolved.

---

## 5.2 P2 – CPU Diagnosis and Escalation

P2 represents high EC2 CPU utilization above the defined threshold.

The P2 workflow is:

```text
CPU utilization > 50%
        ↓
CloudWatch Alarm → ALARM
        ↓
Event delivered to NOC automation
        ↓
Lambda classifies incident as P2
        ↓
Incident ID created
        ↓
Detection notification sent
        ↓
SSM diagnostic commands
        ↓
CPU / load / process / memory information collected
        ↓
Diagnostic report generated
        ↓
P2 Escalation
        ↓
Manual operational review
```

P2 is deliberately diagnostic-only.

No automatic:

- Service restart.
- Process termination.
- Destructive remediation.
- CPU optimization action.

is performed by the automation.

---

# 6. Alarm Classification and Control

The Lambda automation uses a controlled alarm-classification approach.

Only the approved incident conditions are actionable:

| Priority | Incident Type | Automated Response |
| -------- | ------------- | ------------------ |
| P1 | Apache HTTP Server failure | Automatic recovery and verification |
| P2 | CPU utilization above 50% | Diagnosis and manual escalation |

Unknown or unsupported alarm names are ignored.

This design prevents unrelated alarms, parser tests, or unsupported services from accidentally initiating recovery actions or sending operational notifications.

---

# 7. Notification Architecture

The notification workflow provides different communication stages depending on the incident.

## P1 Notifications

A P1 incident can generate:

1. **Detection notification**
   - Incident detected.
   - Apache recovery initiated.

2. **Resolution notification**
   - Apache successfully recovered.
   - Initial verification passed.
   - Stability verification passed.

3. **Escalation notification**
   - Automatic recovery failed.
   - Manual investigation required.

## P2 Notifications

A P2 incident can generate:

1. **Detection notification**
   - High CPU condition detected.
   - Diagnostics initiated.

2. **Diagnostic and escalation notification**
   - Diagnostic command result.
   - System load information.
   - Top CPU-consuming processes.
   - Memory information.
   - Manual review required.

---

# 8. Incident Information Flow

Operational notifications provide sufficient information for incident handling.

The information includes, where applicable:

- Incident ID.
- Priority.
- Severity.
- Environment.
- Service.
- Detection time.
- Alarm state.
- Alarm reason.
- AWS account information.
- AWS Region.
- EC2 instance name.
- EC2 instance ID.
- Private IP address.
- Availability Zone.
- Alarm name.
- Alarm ARN.
- Detection source.
- Detection metric.
- Threshold.
- SNS topic information.
- Incident pipeline.
- Systems Manager command information.
- Initial verification result.
- Stability verification result.
- Final service state.
- Recovery status.
- Resolution time.
- Manual action requirement.
- P2 diagnostic output.

This provides operations personnel with the information required to understand the incident without relying solely on raw Lambda logs.

---

# 9. End-to-End Architecture Workflow

The overall architecture follows this sequence:

```text
                    ┌─────────────────────┐
                    │      Amazon EC2     │
                    │                     │
                    │  Apache / OS        │
                    │  CW Agent           │
                    │  SSM Agent          │
                    └──────────┬──────────┘
                               │
                               │ Metrics
                               ↓
                    ┌─────────────────────┐
                    │   Amazon CloudWatch │
                    │                     │
                    │ Metrics / Dashboard │
                    │       Alarms         │
                    └──────────┬──────────┘
                               │
                               │ Alarm Event
                               ↓
                    ┌─────────────────────┐
                    │    AWS Lambda       │
                    │                     │
                    │ Incident Detection  │
                    │ Classification      │
                    │ Orchestration       │
                    └──────┬───────┬──────┘
                           │       │
                    P1     │       │     P2
                           │       │
                           ↓       ↓
                    ┌──────────┐ ┌──────────┐
                    │   SSM    │ │   SSM    │
                    │ Recovery │ │Diagnosis │
                    └────┬─────┘ └────┬─────┘
                         │             │
                         └──────┬──────┘
                                ↓
                         ┌─────────────┐
                         │ Amazon SNS  │
                         │             │
                         │ Email /     │
                         │ Notifications│
                         └──────┬──────┘
                                ↓
                       Operations / NOC
```

---

# 10. Operational Safety Design

The architecture intentionally separates automated remediation from diagnostic automation.

### P1

Automatic remediation is permitted because the approved action is limited to recovering the Apache service and verifying its state.

### P2

Automatic remediation is not permitted. High CPU conditions can have many causes, so the solution collects diagnostic information and escalates the incident for human investigation.

### Unknown Events

Unknown or unsupported alarms are ignored. They do not create incidents, execute SSM commands, or generate notifications.

This control model reduces the risk of inappropriate automated actions.

---

# 11. Monitoring and Observability

The architecture provides monitoring visibility through:

- CloudWatch metrics.
- CloudWatch alarms.
- CloudWatch dashboards.
- Lambda execution logs.
- Systems Manager command execution results.
- SNS incident notifications.

Together these components provide visibility from initial incident detection through recovery, diagnosis, or escalation.

---

# 12. Architecture Benefits

The solution provides the following operational benefits:

- Event-driven incident response.
- Automatic P1 service recovery.
- Controlled P2 diagnosis.
- Reduced manual intervention.
- Faster response to known service failures.
- Improved incident visibility.
- Structured operational notifications.
- Verification before P1 resolution.
- Safe handling of unsupported alarms.
- Centralized AWS-native monitoring and automation.
- A foundation that can be extended to additional approved incident types in the future.

---

# 13. Architecture Summary

The CloudOps NOC Automation architecture integrates Amazon EC2, Amazon CloudWatch, AWS Lambda, Amazon SNS, AWS Systems Manager, IAM, and CloudWatch Logs into a controlled event-driven incident-response workflow.

The architecture supports two finalized operational paths. P1 Apache failures are automatically recovered and verified before resolution. P2 CPU incidents are diagnosed through automated system-level data collection and escalated for manual investigation.

The architecture intentionally avoids P3 automation, unknown-service remediation, and unsafe automatic CPU actions. This provides a focused NOC design that balances automation, operational safety, incident visibility, and controlled recovery.
