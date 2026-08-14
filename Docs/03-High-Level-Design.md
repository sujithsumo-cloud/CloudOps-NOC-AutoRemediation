# Document 3 – High-Level Design (HLD)

# CloudOps NOC Automation System

---

## Document Information

| Item | Details |
| --- | --- |
| Document Name | High-Level Design (HLD) |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Status | Final |

---

# 1. Overview

The CloudOps NOC Automation System is an event-driven AWS cloud operations solution designed to monitor an Amazon EC2 instance and automatically respond to defined operational incidents.

The finalized solution contains two actionable incident paths:

- **P1 – Apache HTTP Server (httpd) failure:** automatic recovery is performed using AWS Systems Manager.
- **P2 – High EC2 CPU utilization:** diagnostic information is collected using AWS Systems Manager, but no automatic restart or destructive remediation is performed.

The system also validates the CloudWatch alarm name before taking action. Unknown or test alarm names are ignored without creating an incident, executing SSM commands, or sending notifications.

The design uses Amazon CloudWatch, AWS Lambda, Amazon SNS, AWS Systems Manager, Amazon EC2, CloudWatch Agent, and IAM to provide automated incident detection, response, verification, and notification.

---

# 2. Business Objective

The high-level design supports the following operational objectives:

- Detect infrastructure and service incidents automatically.
- Reduce manual investigation for known incidents.
- Automatically recover Apache service failures.
- Collect useful diagnostics for high CPU incidents.
- Prevent unauthorized automation for unknown alarm events.
- Notify operations personnel with complete incident information.
- Improve operational visibility and reduce Mean Time to Recovery (MTTR) for recoverable incidents.

---

# 3. Solution Scope

The implemented solution is intentionally limited to two severities.

| Priority | Incident | Automation |
| --- | --- | --- |
| P1 | Apache HTTP Server (`httpd`) unavailable | Automatic restart and verification |
| P2 | EC2 CPU utilization above 50% | Diagnostic collection and escalation |

**P3 / Unknown Service automation is not part of the finalized design.**

---

# 4. High-Level Architecture

The solution consists of the following logical components:

- Amazon EC2
- Apache HTTP Server
- Amazon CloudWatch Agent
- Amazon CloudWatch
- CloudWatch Alarms
- AWS Lambda
- Amazon SNS
- AWS Systems Manager
- IAM
- Amazon CloudWatch Logs

High-level flow:

```text
                         ┌──────────────────────┐
                         │     Amazon EC2       │
                         │  Apache / OS Metrics │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │  CloudWatch Agent    │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Amazon CloudWatch  │
                         │ Metrics + Alarms     │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   CloudWatch Alarm   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │    AWS Lambda        │
                         │ Incident Classifier  │
                         └──────────┬───────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
              ┌───────────┐                   ┌───────────┐
              │    P1     │                   │    P2     │
              │  httpd    │                   │ High CPU  │
              └─────┬─────┘                   └─────┬─────┘
                    │                               │
                    ▼                               ▼
             AWS Systems Manager              AWS Systems Manager
                 Run Command                      Run Command
                    │                               │
                    ▼                               ▼
             Restart httpd                  Collect diagnostics
                    │                               │
                    ▼                               ▼
              Verify stable                 Manual review /
                 service                       escalation
                    │                               │
                    └───────────────┬───────────────┘
                                    ▼
                              Amazon SNS
                                    │
                                    ▼
                              Email Notification
```

---

# 5. Component Description

## 5.1 Amazon EC2

Amazon EC2 provides the compute environment for the monitored workload.

The instance hosts:

- Amazon Linux 2023
- Apache HTTP Server (`httpd`)
- CloudWatch Agent
- Systems Manager Agent

The EC2 instance is the target system for both P1 recovery and P2 diagnostic operations.

---

## 5.2 Apache HTTP Server

Apache (`httpd`) is the monitored application for the P1 incident path.

The system identifies an Apache availability failure through the configured CloudWatch monitoring mechanism.

When the P1 alarm enters the `ALARM` state, the automation attempts to restart Apache and then verifies that the service remains active.

---

## 5.3 CloudWatch Agent

The CloudWatch Agent collects operating-system and application-related monitoring information from the EC2 instance.

The monitoring environment includes metrics such as:

- CPU utilization
- Memory utilization
- Disk information
- Network information
- Apache process availability

These metrics provide the monitoring data used by the CloudWatch environment.

---

## 5.4 Amazon CloudWatch

Amazon CloudWatch provides centralized monitoring and alarm evaluation.

CloudWatch is responsible for:

- Receiving monitoring metrics.
- Evaluating alarm conditions.
- Detecting configured incidents.
- Initiating the automation workflow.
- Maintaining monitoring history and logs.

The finalized automation uses two actionable alarm definitions:

- `NOC-cloudops-automate` → P1 Apache recovery.
- `cpu alert` → P2 CPU diagnostic workflow.

The P2 alarm threshold is **CPU utilization > 50%**.

---

## 5.5 AWS Lambda

AWS Lambda is the central incident automation engine.

The Lambda function:

1. Receives the CloudWatch alarm event.
2. Parses the `alarmData` structure.
3. Reads the alarm name and alarm state.
4. Confirms that the alarm is in the `ALARM` state.
5. Matches the alarm name against the approved P1/P2 configuration.
6. Ignores unknown alarm names.
7. Creates an incident ID for an actionable incident.
8. Retrieves the EC2 instance name.
9. Executes the appropriate P1 or P2 workflow.
10. Sends incident notifications through Amazon SNS.

The Lambda function does not automatically act on arbitrary alarm names.

---

# 6. P1 High-Level Design – Apache Recovery

The P1 workflow is designed for automatic service recovery.

### P1 Flow

```text
Apache failure
      │
      ▼
CloudWatch Alarm: NOC-cloudops-automate
      │
      ▼
Lambda detects P1
      │
      ▼
Incident ID generated
      │
      ▼
Initial notification
      │
      ▼
SSM Run Command
      │
      ▼
systemctl restart httpd
      │
      ▼
Verify httpd is active
      │
      ▼
Wait and perform stability verification
      │
      ├───────────────┐
      │               │
      ▼               ▼
   Stable          Not Stable
      │               │
      ▼               ▼
  RESOLVED        ESCALATED
      │               │
      └───────┬───────┘
              ▼
        SNS Email Report
```

### P1 Recovery Logic

The automation:

1. Detects the P1 alarm.
2. Sends an initial incident notification.
3. Executes the Apache restart through Systems Manager.
4. Checks whether `httpd` is active.
5. Performs a stability verification after the initial recovery check.
6. Marks the incident as resolved if the service remains active.
7. Escalates the incident if recovery or stability verification fails.
8. Sends the final incident report through SNS.

No manual restart is required when the automated P1 recovery succeeds.

---

# 7. P2 High-Level Design – CPU Diagnosis

The P2 workflow is intentionally diagnostic-only.

### P2 Flow

```text
CPU utilization > 50%
      │
      ▼
CloudWatch Alarm: cpu alert
      │
      ▼
Lambda detects P2
      │
      ▼
Incident ID generated
      │
      ▼
Initial notification
      │
      ▼
SSM Run Command
      │
      ▼
Collect diagnostics
      │
      ├── uptime / load
      ├── top CPU consumers
      └── memory information
      │
      ▼
Diagnostic report
      │
      ▼
SNS Email
      │
      ▼
Manual Review / Escalation
```

The P2 workflow does **not** restart services, terminate processes, reboot the instance, or perform other automatic corrective actions.

This design reduces the risk of taking an inappropriate automated action when high CPU utilization requires investigation before remediation.

---

# 8. Alarm Validation and Safety Control

The Lambda function contains an explicit incident classification gate.

Only the following alarm names are actionable:

| Alarm Name | Priority | Action |
| --- | --- | --- |
| `NOC-cloudops-automate` | P1 | Apache recovery |
| `cpu alert` | P2 | CPU diagnosis |

If an unknown alarm name such as a parser test alarm is received:

```text
CloudWatch event
      │
      ▼
Lambda parses event
      │
      ▼
Alarm name not recognized
      │
      ▼
Ignore event
      │
      ├── No incident ID
      ├── No SSM command
      └── No notification
```

This control prevents test, unsupported, or unrelated alarms from triggering operational automation.

---

# 9. Amazon Systems Manager

AWS Systems Manager provides remote command execution on the EC2 instance.

For P1, Systems Manager executes the Apache recovery command:

```text
systemctl restart httpd
```

The service is then checked using:

```text
systemctl is-active httpd
```

For P2, Systems Manager executes diagnostic commands that collect:

- System uptime and load.
- Top CPU-consuming processes.
- Memory usage.

The command execution result and diagnostic output are returned to Lambda for inclusion in the incident notification.

---

# 10. Amazon SNS

Amazon SNS provides the notification layer for the automation.

The solution uses SNS to deliver detailed incident emails.

The email contains operational information such as:

- Incident ID
- Priority and severity
- Environment
- Service
- Detection time
- Alarm state
- Alarm reason
- AWS account
- AWS Region
- Instance name
- Instance ID
- Private IP
- Availability Zone
- Alarm name
- Alarm ARN
- Detection metric
- Threshold
- SNS topic name
- SNS topic ARN
- Automation pipeline
- SSM command ID
- Execution result
- Recovery status
- Resolution time
- Manual action
- Diagnostic output where applicable

The notification design provides both detection and final incident information for operational review.

---

# 11. Incident Lifecycle

The automation follows a common incident lifecycle:

```text
DETECTED
   │
   ▼
CLASSIFIED
   │
   ├───────────────┐
   │               │
   ▼               ▼
   P1              P2
   │               │
   ▼               ▼
RECOVERING      DIAGNOSING
   │               │
   ▼               ▼
VERIFIED        DIAGNOSED
   │               │
   ▼               ▼
RESOLVED        ESCALATED
```

For P1, the lifecycle can end in **RESOLVED** or **ESCALATED**.

For P2, the lifecycle intentionally ends in **DIAGNOSED / ESCALATED** because the automation does not perform an automatic CPU remediation.

---

# 12. Monitoring and Logging

Amazon CloudWatch provides monitoring and operational visibility.

The environment maintains:

- EC2 monitoring metrics.
- CloudWatch Agent metrics.
- Alarm state information.
- Lambda execution logs.
- Incident processing information.

Lambda logs provide visibility into:

- Alarm parsing.
- Incident classification.
- Incident ID generation.
- SSM command execution.
- Command status.
- Recovery verification.
- Notification delivery.

---

# 13. Security Design

The solution uses AWS IAM roles and policies to control access between services.

Security principles include:

- Least-privilege permissions.
- IAM roles instead of long-term access keys.
- Systems Manager for remote command execution.
- No requirement for SSH during automated remediation.
- Controlled access to EC2 and AWS APIs.
- CloudWatch Logs for operational auditing.

---

# 14. Failure Handling

The design includes failure handling for the automation workflow.

### P1 Failure

If Apache cannot be confirmed as active after recovery and stability verification:

```text
Recovery Failed
      │
      ▼
Incident Escalated
      │
      ▼
Manual Investigation Required
```

### P2 Diagnostic Failure

If diagnostic output is unavailable, the notification identifies that no diagnostic output was captured and directs the operator to review the Systems Manager Run Command history.

### Unknown Alarm

Unknown alarm names are ignored without performing operational actions.

---

# 15. High-Level Security and Operational Boundaries

The architecture intentionally separates responsibilities:

| Component | Responsibility |
| --- | --- |
| CloudWatch | Monitoring and alarm detection |
| Lambda | Incident classification and orchestration |
| SSM | EC2 command execution |
| SNS | Incident notification |
| EC2 | Application and operating-system workload |
| IAM | Authorization |
| CloudWatch Logs | Operational logging |

This separation makes the automation easier to understand, troubleshoot, and maintain.

---

# 16. Limitations

The current HLD has the following limitations:

- The implemented environment uses a single EC2 instance.
- The deployment operates in a single AWS Region.
- P1 automation is limited to Apache HTTP Server recovery.
- P2 automation is diagnostic-only.
- No P3 automation is implemented.
- Unknown alarm names are intentionally ignored.
- No automatic CPU remediation is performed.
- High Availability and Multi-AZ application deployment are not part of the current implementation.
- The architecture does not include Auto Scaling or a Load Balancer.

---

# 17. Future Enhancements

Potential future enhancements include:

- Support for additional EC2 instances.
- Application Load Balancer integration.
- Auto Scaling.
- Multi-AZ deployment.
- Additional controlled remediation workflows.
- Infrastructure as Code.
- CI/CD integration.
- Centralized incident management.
- Additional notification channels.

These enhancements are outside the finalized P1/P2 implementation scope.

---

# 18. Conclusion

The CloudOps NOC Automation System provides a controlled event-driven approach to cloud incident response.

The finalized design separates incidents into two operational priorities:

- **P1:** automatic Apache recovery with post-recovery stability verification.
- **P2:** high CPU diagnosis with detailed evidence collection and manual escalation.

AWS CloudWatch provides monitoring and alarm detection, Lambda performs incident classification and orchestration, Systems Manager executes commands on the EC2 instance, and SNS provides detailed operational notifications.

The explicit alarm validation mechanism ensures that only approved P1 and P2 incidents trigger automation, while unknown or test events are safely ignored.
