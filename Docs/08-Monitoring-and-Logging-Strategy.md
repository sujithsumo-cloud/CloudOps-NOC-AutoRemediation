# Document 8 – Monitoring & Logging Strategy

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda, and AWS Systems Manager

---

# Document Information

| Item | Details |
| --- | --- |
| Document Name | Monitoring & Logging Strategy |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Status | Final |

---

# 1. Purpose

This document defines the monitoring and logging strategy for the CloudOps NOC Automation solution. The strategy provides continuous visibility into the monitored EC2 environment, detects the defined operational conditions, supports automated remediation, and retains logs required for troubleshooting and operational review.

The finalized solution covers two operational automation areas:

- **P1 – HTTPD automation:** Detection and automatic recovery of the Apache (httpd) service.
- **P2 – CPU utilization automation:** Monitoring and automation associated with high CPU utilization.

P3 and Unknown Service automation are intentionally excluded from the finalized project scope.

---

# 2. Monitoring Objectives

The monitoring strategy is designed to:

- Continuously monitor the EC2 environment.
- Monitor Apache (httpd) process availability for P1 automation.
- Monitor CPU utilization for P2 automation.
- Collect operating-system and application-related metrics through the CloudWatch Agent.
- Present operational metrics through a CloudWatch Dashboard.
- Evaluate CloudWatch Alarm conditions.
- Trigger the appropriate automation workflow when an alarm enters the required state.
- Maintain Lambda, Systems Manager, CloudWatch Agent, and operating-system logs for troubleshooting.
- Provide sufficient operational evidence for incident investigation and testing.

---

# 3. Monitoring Architecture

The monitoring and automation flow is based on AWS managed services.

```text
EC2 Instance
      |
      v
CloudWatch Agent
      |
      v
Amazon CloudWatch Metrics
      |
      +----------------------+
      |                      |
      v                      v
CloudWatch Dashboard     CloudWatch Alarms
                              |
                              v
                         Amazon SNS
                              |
                              v
                         AWS Lambda
                              |
                              v
                    AWS Systems Manager
                              |
                              v
                    Automated Remediation
                              |
                              v
                     Verification / Result
                              |
                              v
                     SNS Notification
```

The P1 and P2 workflows use the same monitoring and automation foundation while applying different alarm conditions and remediation logic.

---

# 4. Monitoring Components

| AWS Service / Component | Monitoring or Logging Purpose |
| --- | --- |
| Amazon EC2 | Hosts the monitored workload and agents |
| CloudWatch Agent | Collects system and process metrics |
| Amazon CloudWatch | Stores and evaluates monitoring metrics |
| CloudWatch Dashboard | Provides centralized operational visibility |
| CloudWatch Alarm | Detects configured P1/P2 conditions |
| Amazon SNS | Distributes alarm and notification events |
| AWS Lambda | Processes alarm events and performs automation logic |
| AWS Systems Manager | Executes remediation commands on the managed EC2 instance |
| Amazon CloudWatch Logs | Stores Lambda execution and related AWS service logs |
| EC2 local logs | Provide host-level troubleshooting information |

---

# 5. CloudWatch Agent Monitoring

The Amazon CloudWatch Agent runs on the EC2 instance and publishes configured operating-system and application/process metrics to CloudWatch.

The agent is used as the primary metric collection mechanism for the project.

### Collection Interval

60 seconds.

### Monitoring Areas

- CPU utilization
- Memory utilization
- Disk utilization
- Disk I/O
- Network traffic
- Apache/httpd process status

The exact metrics exposed to CloudWatch are used by the dashboard and alarm configurations according to the finalized P1/P2 implementation.

---

# 6. P1 – HTTPD Monitoring Strategy

## 6.1 Objective

The P1 workflow monitors Apache (httpd) availability and provides automated recovery when the monitored Apache process is no longer available.

## 6.2 Detection

The CloudWatch Agent collects the Apache process metric.

The relevant condition is:

```text
Apache/httpd process count = 0
```

When the configured alarm condition is met, the CloudWatch Alarm transitions into the `ALARM` state.

## 6.3 Remediation Flow

```text
Apache/httpd process unavailable
          |
          v
CloudWatch Agent metric
          |
          v
CloudWatch Alarm
          |
          v
SNS
          |
          v
Lambda
          |
          v
SSM Run Command
          |
          v
Restart httpd
          |
          v
Verify service
```

The Lambda workflow uses AWS Systems Manager to perform the service recovery rather than requiring manual SSH intervention.

---

# 7. P2 – CPU Utilization Monitoring Strategy

## 7.1 Objective

The P2 workflow monitors CPU utilization and provides the automation path associated with the finalized CPU utilization alarm.

## 7.2 Detection

CloudWatch evaluates the configured CPU utilization metric against the defined alarm condition.

When the configured CPU condition is met:

```text
High CPU utilization
        |
        v
CloudWatch Alarm
        |
        v
SNS
        |
        v
Lambda automation
        |
        v
Configured P2 remediation
```

The P2 workflow is separate from the P1 Apache recovery workflow and must not be interpreted as an Apache-service failure.

---

# 8. CloudWatch Dashboard

The project uses a CloudWatch Dashboard to provide centralized operational visibility.

### Dashboard

```text
cloudops-NOC-dashboard
```

### Dashboard Monitoring Areas

- CPU utilization
- Memory utilization
- Disk utilization
- Network metrics
- Apache/httpd process status

The dashboard is used during normal monitoring, testing, incident investigation, and post-remediation verification.

---

# 9. CloudWatch Alarm Strategy

The finalized project uses two severity levels.

| Severity | Monitoring Area | Purpose |
| --- | --- | --- |
| P1 | Apache/httpd | Detect and automatically recover Apache service failure |
| P2 | CPU utilization | Detect and process high CPU utilization conditions |

### P1 Alarm

The current working CloudWatch alarm used for the Apache automation is:

```text
NOC-cloudops-automate
```

Its purpose is to detect the Apache process failure condition and initiate the P1 automation workflow.

### P2 Alarm

The CPU utilization automation is represented by the finalized CPU monitoring workflow.

The alarm evaluates CPU utilization against its configured threshold and initiates the P2 workflow when the condition is met.

### Scope Control

The following are intentionally excluded:

- P3
- Unknown Service automation
- Unwanted legacy notifications associated with those flows

This prevents the finalized monitoring strategy from reintroducing retired automation behavior.

---

# 10. Alerting and Automation Strategy

When a configured alarm enters the required state:

1. CloudWatch changes the alarm state.
2. The configured notification path publishes the alarm event to Amazon SNS.
3. SNS invokes the Lambda automation workflow.
4. Lambda parses and validates the incoming event.
5. Lambda identifies the applicable automation path.
6. AWS Systems Manager is used where remediation requires EC2 command execution.
7. The remediation result is evaluated.
8. A notification is generated for the resulting operational state.

For P1, the remediation includes restarting Apache and verifying the service result.

For P2, the automation follows the finalized CPU-utilization remediation logic implemented for the project.

---

# 11. Logging Strategy

Logging is maintained at multiple levels so that each stage of the monitoring and remediation workflow can be investigated independently.

## 11.1 Lambda Logs

Lambda execution logs are stored in Amazon CloudWatch Logs.

The logs are used to investigate:

- Incoming alarm events
- Event parsing
- Alarm/severity identification
- Automation decisions
- Systems Manager requests
- Command results
- Verification results
- Notification results
- Exceptions and failures

These logs are particularly important when troubleshooting alarm-triggered automation.

---

## 11.2 Systems Manager Logs

AWS Systems Manager provides execution information for commands sent to the EC2 managed node.

Logs and execution information are used to verify:

- Whether the Run Command was received.
- Whether the command was executed.
- Whether the command completed successfully.
- Whether the target managed node was available.

The EC2 host also maintains SSM Agent logs under:

```text
/var/log/amazon/ssm/
```

---

## 11.3 CloudWatch Agent Logs

The CloudWatch Agent maintains local logs that can be used when metrics stop appearing or metric collection behaves unexpectedly.

Typical location:

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

These logs help investigate:

- Agent startup
- Configuration loading
- Metric collection
- Metric publishing
- Agent errors

---

## 11.4 Operating System Logs

The EC2 instance operating-system logs are used for host-level troubleshooting.

A commonly used system log is:

```text
/var/log/messages
```

These logs can help correlate application, service, and operating-system events with CloudWatch alarm activity.

---

# 12. Notification Strategy

Amazon SNS provides the notification and event-distribution layer.

The finalized workflow uses SNS for:

- Delivering alarm events to Lambda.
- Sending operational notifications through the configured notification path.
- Communicating remediation results.

For P1, a successful Apache recovery is reported after the Lambda/SSM workflow verifies the result.

The notification content should identify the relevant incident, target instance, action performed, and final result.

---

# 13. Operational Monitoring Workflow

## P1 – Apache Failure

```text
Apache/httpd Running
        |
        v
CloudWatch Agent
        |
        v
Apache Process Metric
        |
        v
CloudWatch Alarm
        |
Apache stops
        |
        v
Alarm = ALARM
        |
        v
SNS
        |
        v
Lambda
        |
        v
SSM Run Command
        |
        v
Restart httpd
        |
        v
Verify Apache
        |
        v
Success / Failure Result
```

## P2 – CPU Utilization

```text
EC2 CPU Activity
        |
        v
CloudWatch Metric
        |
        v
CPU Alarm Evaluation
        |
        v
Alarm = ALARM
        |
        v
SNS
        |
        v
Lambda
        |
        v
P2 Automation Logic
        |
        v
Remediation / Result
        |
        v
Notification
```

---

# 14. Troubleshooting Strategy

Troubleshooting should follow the monitoring chain from the source metric toward the automation result.

| Check | What to Verify |
| --- | --- |
| EC2 | Instance is running and reachable |
| Apache | `httpd` service/process state for P1 |
| CloudWatch Agent | Agent is running and publishing metrics |
| Metrics | Expected CPU/process metrics are updating |
| Dashboard | Current values are visible |
| Alarm | Correct condition and state |
| SNS | Event/notification path is functioning |
| Lambda | Invocation, event parsing, and execution logs |
| Systems Manager | Managed node is online and command execution succeeds |
| Remediation | Expected P1/P2 action completed |
| Notification | Final result was delivered |

A failure should be isolated by identifying the first stage in the chain where expected behavior stopped.

---

# 15. Monitoring Test Strategy

The monitoring implementation should be validated using controlled tests.

## P1 Test

1. Confirm Apache is running.
2. Stop Apache intentionally.
3. Confirm the Apache process metric reaches the failure condition.
4. Confirm the P1 alarm enters `ALARM`.
5. Confirm SNS receives the event.
6. Confirm Lambda is invoked.
7. Confirm SSM executes the restart command.
8. Confirm Apache returns to the running state.
9. Confirm the remediation result is logged and notified.

## P2 Test

1. Confirm CPU utilization monitoring is active.
2. Generate the controlled CPU condition required by the configured alarm.
3. Confirm the P2 alarm enters `ALARM`.
4. Confirm the SNS/Lambda workflow is triggered.
5. Confirm the configured P2 automation executes.
6. Confirm the final result in Lambda/CloudWatch logs and notifications.

---

# 16. Monitoring Benefits

The finalized monitoring strategy provides:

- Continuous infrastructure visibility.
- Dedicated P1 Apache monitoring.
- Dedicated P2 CPU monitoring.
- Automated incident response.
- Reduced manual intervention.
- Faster service recovery for P1.
- Centralized operational logs.
- CloudWatch dashboard visibility.
- Clear separation of finalized severity workflows.
- Troubleshooting evidence for each automation stage.

---

# 17. Best Practices Implemented

The solution follows practical AWS monitoring and operational practices:

- Native AWS monitoring services are used.
- Metrics are collected centrally in CloudWatch.
- Dashboard visibility is provided for operational review.
- Alarm-driven automation is used instead of continuous manual checking.
- Lambda execution logs support automation troubleshooting.
- Systems Manager provides controlled remote command execution.
- Monitoring and remediation are separated logically by severity.
- Retired P3/Unknown Service behavior is excluded from the finalized workflow.
- Testing is performed using controlled failure conditions.

---

# 18. Conclusion

The Monitoring & Logging Strategy provides the operational monitoring foundation for the CloudOps NOC Automation project.

The finalized solution monitors two defined severity areas: **P1 Apache/httpd availability** and **P2 CPU utilization**. CloudWatch provides metric collection, visualization, and alarm evaluation, while SNS and Lambda provide the event-driven automation path. Systems Manager supports secure command execution for the P1 recovery workflow.

The logging strategy provides the evidence required to troubleshoot metric collection, alarm evaluation, Lambda execution, Systems Manager command execution, and remediation results. This enables the project to demonstrate a complete monitoring, alerting, automation, and troubleshooting lifecycle without reintroducing the excluded P3 or Unknown Service workflows.
