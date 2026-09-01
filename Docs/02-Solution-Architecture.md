# Document 2 — Solution Architecture

## Project Title

**CloudOps NOC Automation V2.0**

---

## Document Information

| Item | Details |
|---|---|
| Document Name | Solution Architecture |
| Project | CloudOps NOC Automation |
| Version | 2.0 |
| Project Type | AWS Cloud Operations Automation |
| Region | `ap-south-1` — Asia Pacific (Mumbai) |
| Status | Current V2.0 Baseline |

---

# 1. Purpose

This document describes the **solution architecture** of CloudOps NOC Automation V2.0.

The project is designed to reduce unnecessary manual intervention in repetitive cloud operations incidents while keeping automation controlled and verifiable.

The architecture applies a simple operational lifecycle:

```text
Monitor
   ↓
Detect
   ↓
Validate
   ↓
Decide
   ↓
Remediate / Diagnose
   ↓
Verify
   ↓
Notify / Escalate
```

The solution intentionally separates:

```text
Detection
≠
Diagnosis
≠
Remediation
```

This is important because not every detected condition should automatically cause a corrective action.

---

# 2. Business Problem

Traditional incident handling can require repeated manual operational steps:

```text
Incident
   ↓
Engineer notices alert
   ↓
Engineer investigates
   ↓
Engineer connects to server
   ↓
Engineer performs action
   ↓
Engineer verifies recovery
```

For known and repetitive incidents, this can increase:

- Manual operational effort.
- Response delay.
- Mean Time to Recovery (MTTR).
- Risk of inconsistent handling.

The business requirement is therefore:

> **Reduce unnecessary manual intervention in predefined repetitive incidents while maintaining operational safety and human control where required.**

---

# 3. Business Solution

The solution uses AWS-native monitoring and automation to create a controlled event-driven incident workflow.

```text
Incident Condition
       │
       ▼
CloudWatch
       │
       ▼
Alarm Event
       │
       ▼
Lambda
       │
       ▼
Validate + Classify
       │
    ┌──┴──┐
    ▼     ▼
   P1     P2
    │      │
    ▼      ▼
Recover Diagnose
    │      │
    └──┬───┘
       ▼
      SNS
       │
       ▼
Engineer
```

---

# 4. Finalized Scope

CloudOps NOC Automation V2.0 supports exactly two incident priorities.

| Priority | Incident | Response |
|---|---|---|
| P1 | Apache HTTPD unavailable | Automatic recovery + verification + stability check |
| P2 | High EC2 CPU utilization | Diagnostic-only + engineer review |

P3 is intentionally excluded.

---

# 5. Implemented AWS Services

The finalized architecture uses exactly **seven AWS services**.

| AWS Service | Architectural Responsibility | Repository Reference |
|---|---|---|
| Amazon VPC | Network foundation and logical network boundary | [VPC](../VPC/README.md) |
| Amazon EC2 | Hosts Amazon Linux and Apache HTTPD | [EC2](../EC2/README.md) |
| Amazon CloudWatch | Monitoring, metrics, alarms, logs, dashboard | [CloudWatch](../CloudWatch/README.md) |
| AWS Lambda | Incident decision and orchestration | [Lambda](../Lambda/README.md) |
| AWS Systems Manager | Controlled EC2 execution and diagnostics | [SSM](../SSM/README.md) |
| Amazon SNS | Operational notification delivery | [SNS](../SNS/README.md) |
| AWS IAM | Authorization and least-privilege access control | [IAM](../IAM/README.md) |

Supporting components are **not additional top-level AWS services** in the project scope.

Supporting components include:

```text
Apache HTTPD
CloudWatch Agent
SSM Agent
Linux systemd
Boto3
CloudWatch Logs capability
CloudWatch Dashboard capability
```

---

# 6. High-Level Solution Architecture

```text
                           USER / BROWSER
                                 │
                                 ▼
                              Internet
                                 │
                                 ▼
                           Internet Gateway
                                 │
                                 ▼
                                VPC
                                 │
                                 ▼
                               EC2
                                 │
                          Apache HTTPD
                                 │
                   ┌─────────────┴─────────────┐
                   │                           │
                   ▼                           ▼
          CloudWatch Agent              CPUUtilization
                   │                           │
                   ▼                           │
       procstat_lookup_pid_count               │
                   │                           │
                   └─────────────┬─────────────┘
                                 ▼
                         Amazon CloudWatch
                                 │
                        Alarm Evaluation
                                 │
                   ┌─────────────┴─────────────┐
                   ▼                           ▼
       NOC-cloudops-automate               cpu alert
                   │                           │
                   └─────────────┬─────────────┘
                                 ▼
                         Direct Alarm Event
                                 │
                                 ▼
                             AWS Lambda
                                 │
                   Parse + Validate + Classify
                                 │
                         Actionable Alarm Gate
                                 │
                     ┌───────────┴───────────┐
                     ▼                       ▼
                    P1                      P2
                     │                       │
             HTTPD Recovery             Diagnostics
                     │                       │
                     └───────────┬───────────┘
                                 ▼
                       AWS Systems Manager
                                 │
                                 ▼
                             SSM Agent
                                 │
                                 ▼
                              EC2 Linux
                                 │
                     ┌───────────┴───────────┐
                     ▼                       ▼
             Restart / Verify          Collect Evidence
                     │                       │
                     └───────────┬───────────┘
                                 ▼
                             AWS Lambda
                                 │
                                 ▼
                              Amazon SNS
                                 │
                                 ▼
                       CloudOps / NOC Engineer
```

IAM provides authorization across the AWS API interactions.

---

# 7. Correct Event Path

The current V2.0 event path is:

```text
CloudWatch Alarm
      │
      ▼
Direct Alarm Event
      │
      ▼
Lambda
```

SNS is **not** between CloudWatch and Lambda.

The notification path is:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

Therefore:

```text
CloudWatch
= Detect

Lambda
= Decide

SSM
= Execute

SNS
= Notify
```

---

# 8. Amazon VPC Architecture

Amazon VPC provides the network foundation.

Current project network:

```text
cloudops-vpc
10.0.0.0/16
     │
     ▼
cloudops-subnet
10.0.0.0/28
     │
     ▼
cloudops-server
```

Supporting network components:

```text
cloudops-igw
cloudops-rt
cloudops-sg
```

At a high level:

```text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Route Table
   │
   ▼
Public Subnet
   │
   ▼
Security Group
   │
   ▼
EC2
```

Repository reference:

[View VPC design](../VPC/README.md)

---

# 9. Amazon EC2 Architecture

EC2 hosts the operational workload.

```text
Amazon EC2
   │
   ├── Amazon Linux
   ├── Apache HTTPD
   ├── CloudWatch Agent
   └── SSM Agent
```

Apache HTTPD is the service monitored by P1.

The EC2 instance is also the target for:

```text
P1
→ Recovery + verification

P2
→ Diagnostic collection
```

Repository reference:

[View EC2 design](../EC2/README.md)

---

# 10. CloudWatch Monitoring Architecture

The project has two separate monitoring paths.

## P1 — HTTPD Process Availability

```text
Apache HTTPD
      │
      ▼
CloudWatch Agent
      │
      ▼
procstat
      │
      ▼
procstat_lookup_pid_count
      │
      ▼
CloudWatch
      │
      ▼
NOC-cloudops-automate
```

Configured P1 condition:

```text
procstat_lookup_pid_count < 1
```

Reference:

[View P1 alarm](../CloudWatch/NOC-cloudops-automate.md)

---

## P2 — EC2 CPU Utilization

```text
Amazon EC2
    │
    ▼
AWS/EC2
CPUUtilization
    │
    ▼
CloudWatch
    │
    ▼
cpu alert
```

Current project threshold label:

```text
> 50%
```

P2 uses the native EC2 `CPUUtilization` metric.

Reference:

[View P2 alarm](../CloudWatch/cpu%20alert.md)

---

# 11. CloudWatch Agent

The CloudWatch Agent is a supporting component running on EC2.

For the finalized P1 monitoring requirement it provides:

```text
HTTPD lookup
    │
    ▼
procstat pid_count
    │
    ▼
procstat_lookup_pid_count
```

The canonical project configuration should be stored at:

[View CloudWatch Agent configuration](../CloudWatch/cloudwatch-agent-config.json)

and deployed using:

[View CloudWatch Agent configuration script](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

The agent is part of the CloudWatch monitoring implementation and is not counted as an eighth AWS service.

---

# 12. Lambda Decision Architecture

AWS Lambda is the **decision and orchestration layer**.

Current flow:

```text
CloudWatch Alarm Event
       │
       ▼
event["alarmData"]
       │
       ▼
Alarm Parsing
       │
       ▼
State Validation
       │
       ▼
Actionable Alarm Gate
       │
       ▼
Incident Classification
       │
    ┌──┴──┐
    ▼     ▼
   P1     P2
```

Current actionable alarms:

| Alarm | Classification | Response |
|---|---|---|
| `NOC-cloudops-automate` | P1 | HTTPD recovery |
| `cpu alert` | P2 | CPU diagnosis |
| Unknown/Test | Unsupported | Ignore |

Repository references:

- [Lambda README](../Lambda/README.md)
- [Lambda source code](../Lambda/lambda_function.py)

---

# 13. Actionable Alarm Gate

The Actionable Alarm Gate prevents uncontrolled automation.

Conceptually:

```text
Incoming Alarm
      │
      ▼
State = ALARM?
   /        \
 NO         YES
 │           │
 ▼           ▼
Ignore    Approved Alarm?
           /        \
         NO          YES
         │            │
         ▼            ▼
       Ignore       Continue
```

This safety control ensures only predefined project incidents can enter the operational workflow.

---

# 14. P1 Solution Architecture

P1 represents a known service-level failure with a known corrective action.

```text
HTTPD Failure
     │
     ▼
CloudWatch Agent
     │
     ▼
procstat_lookup_pid_count
     │
     ▼
NOC-cloudops-automate
     │
     ▼
Lambda
     │
     ▼
Actionable Alarm Gate
     │
     ▼
P1
     │
     ▼
SSM SendCommand
     │
     ▼
SSM Agent
     │
     ▼
systemctl restart httpd
     │
     ▼
systemd
     │
     ▼
HTTPD
     │
     ▼
systemctl is-active httpd
     │
     ▼
Stability Check
     │
 ┌───┴──────────┐
 ▼              ▼
Resolved     Escalated
 │              │
 └──────┬───────┘
        ▼
       SNS
```

The current workflow uses:

```bash
systemctl restart httpd
```

and verification:

```bash
systemctl is-active httpd
```

The current implementation also performs a stability recheck after approximately 15 seconds and uses a bounded retry policy.

---

# 15. Which Component Actually Restarts HTTPD?

This responsibility should be explained precisely.

```text
Lambda
= Decides and requests recovery

Systems Manager
= Provides controlled remote execution

SSM Agent
= Executes the requested command on EC2

systemctl
= Requests local service management

systemd
= Actually manages/restarts HTTPD
```

Therefore:

> **Lambda does not directly restart HTTPD. Lambda requests the approved operation through Systems Manager, and Linux systemd performs the actual service restart.**

---

# 16. P2 Solution Architecture

P2 intentionally uses diagnosis instead of automatic remediation.

```text
High CPU
   │
   ▼
CPUUtilization
   │
   ▼
cpu alert
   │
   ▼
Lambda
   │
   ▼
Actionable Alarm Gate
   │
   ▼
P2
   │
   ▼
SSM Diagnostics
   │
   ├── uptime
   ├── top CPU processes
   └── memory information
   │
   ▼
Diagnostic Result
   │
   ▼
SNS
   │
   ▼
Engineer Review
```

No automatic:

```text
HTTPD restart
EC2 reboot
Process termination
Destructive remediation
```

is performed for P2.

---

# 17. Why P1 and P2 Are Different

## P1

P1 has:

```text
Known failure
+
Known service
+
Known corrective action
+
Verifiable result
```

Therefore controlled automatic remediation is appropriate.

## P2

High CPU may be caused by:

```text
Legitimate traffic
Application load
Background processing
Misbehaving process
Resource contention
Other unknown causes
```

Therefore:

```text
P2
→ Diagnose
→ Collect Evidence
→ Notify
→ Human Decision
```

Core principle:

> **Detection does not automatically mean remediation.**

---

# 18. Systems Manager Architecture

Systems Manager provides controlled EC2 command execution.

```text
Lambda
   │
   ▼
Boto3
   │
   ▼
SSM API
   │
   ▼
AWS Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2 Linux
```

The current runtime code uses:

```text
AWS-RunShellScript
```

for Run Command.

Repository references:

- [SSM README](../SSM/README.md)
- [Run Command guide](../SSM/run-command.md)

---

# 19. SNS Notification Architecture

Amazon SNS is the operational notification layer.

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Configured Subscriber
   │
   ▼
Engineer
```

SNS can communicate:

```text
Incident detection
Recovery started
Recovery succeeded
Recovery failed
Escalation required
P2 diagnostics complete
Manual review required
```

Important:

> **SNS does not decide to escalate. Lambda/workflow logic decides the incident state; SNS delivers the resulting message.**

Repository reference:

[View SNS design](../SNS/README.md)

---

# 20. IAM Security Architecture

IAM provides AWS authorization.

```text
Who / Which Service?
       │
       ▼
What Action?
       │
       ▼
Which Resource?
       │
       ▼
Allow / Deny
```

The architecture uses separate permission responsibilities for:

```text
EC2 Instance Role
Lambda Execution Role
```

Examples:

```text
Lambda
→ ssm:SendCommand
→ ssm:GetCommandInvocation
→ sns:Publish
→ ec2:DescribeInstances
→ Parameter Store access

EC2
→ CloudWatch Agent permissions
→ SSM Agent permissions
```

The project follows:

> **Principle of Least Privilege**

Repository references:

- [IAM README](../IAM/README.md)
- [Lambda IAM policy](../IAM/cloudops-lambda-inline-policy.json)
- [EC2 IAM policy](../IAM/cloudops-EC2-inline-role.json)

---

# 21. Observability Architecture

Observability is provided primarily through Amazon CloudWatch capabilities and Systems Manager command results.

```text
CloudWatch Metrics
CloudWatch Alarms
CloudWatch Dashboard
CloudWatch Logs
Lambda Execution Logs
SSM Command Results
SNS Notifications
```

CloudWatch Logs is treated as a capability within the CloudWatch service baseline rather than as an additional eighth implemented project service.

---

# 22. User Traffic vs Monitoring vs Management

These are three different architectural flows.

## User Traffic

```text
Browser
   │
   ▼
Internet
   │
   ▼
VPC
   │
   ▼
EC2
   │
   ▼
HTTPD
```

## Monitoring

```text
HTTPD / EC2
      │
      ▼
CloudWatch Agent / Native Metric
      │
      ▼
CloudWatch
```

## Management

```text
Lambda
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2 Linux
```

These flows should not be mixed together.

---

# 23. Security Layers

The architecture applies multiple controls.

```text
VPC / Security Group
        │
        ▼
Network Control

IAM
        │
        ▼
Authorization

Actionable Alarm Gate
        │
        ▼
Automation Safety

Systems Manager
        │
        ▼
Controlled Execution

Verification
        │
        ▼
Operational Safety
```

This is a defense-in-depth approach.

---

# 24. Deployment and Implementation References

The solution architecture maps directly to repository implementation.

| Architecture Area | Implementation Reference |
|---|---|
| Deployment procedure | [Deployment Guide](06-Deployment-Guide.md) |
| Apache installation | [Install Apache](../Scripts/Installation/01-install-apache.sh) |
| CloudWatch Agent installation | [Install CloudWatch Agent](../Scripts/Installation/02-install-cloudwatch-agent.sh) |
| SSM Agent | [Install/verify SSM Agent](../Scripts/Installation/03-install-ssm-agent.sh) |
| CloudWatch Agent configuration | [Configure CloudWatch Agent](../Scripts/Configuration/01-configure-cloudwatch-agent.sh) |
| P1 failure test | [Stop HTTPD](../Scripts/Operations/stop-httpd.sh) |
| HTTPD manual recovery | [Restart HTTPD](../Scripts/Operations/restart-httpd.sh) |
| Service verification | [Verify services](../Scripts/Verification/verify-services.sh) |
| Diagnostics | [Diagnostics scripts](../Scripts/Diagnostics/) |
| Lambda implementation | [Lambda source](../Lambda/lambda_function.py) |

---

# 25. Current Limitations

The current V2.0 architecture intentionally remains limited to the project requirements.

Current limitations include:

```text
Single EC2 instance
Single-AZ workload
No Auto Scaling
No application load balancer
No automated instance replacement
No full disaster-recovery architecture
P1 recovery limited to predefined HTTPD failure
P2 remains diagnostic-only
```

These limitations do not invalidate the current solution.

They define the boundary between:

```text
Current Learning / Portfolio Implementation
```

and:

```text
Future Production Architecture
```

---

# 26. Possible Future Enhancements

Possible future improvements include:

```text
Multi-AZ design
Application Load Balancer
Auto Scaling
Private application subnets
Infrastructure as Code
Centralized audit logging
Enhanced application-level health checks
Long-term backup / restore architecture
Expanded observability
```

These are not implemented components of the current V2.0 baseline.

---

# 27. Architecture Decision

The architecture is intentionally **requirements-driven** and **fit-for-purpose**.

The project does not add services only to increase architectural complexity.

The current seven-service design provides the required capabilities:

```text
Network
Compute
Monitoring
Decision
Execution
Notification
Authorization
```

This keeps the solution:

- Understandable.
- Testable.
- Operationally focused.
- Easier to troubleshoot.
- Suitable for demonstrating core CloudOps/NOC concepts.

---

# 28. Three-Level Architecture Explanation

## Level 1

> **The project is an event-driven AWS incident-management solution where CloudWatch detects, Lambda decides, Systems Manager executes, SNS notifies, IAM authorizes, EC2 hosts the workload, and VPC provides the network.**

## Level 2

> **Apache HTTPD runs on EC2 inside a VPC. CloudWatch monitors P1 HTTPD process availability and P2 CPU utilization. When an approved alarm enters ALARM, CloudWatch sends the event directly to Lambda. Lambda parses and validates the alarm, classifies it as P1 or P2, and uses Systems Manager either for HTTPD recovery or CPU diagnostics. SNS then communicates the operational result, while IAM controls the required AWS permissions.**

## Level 3

> **For P1, the CloudWatch Agent procstat configuration publishes `procstat_lookup_pid_count`. The `NOC-cloudops-automate` alarm detects the configured process-count failure condition and invokes Lambda directly. Lambda reads `event["alarmData"]`, applies the Actionable Alarm Gate, and uses Boto3 to call SSM Run Command. SSM Agent executes `systemctl restart httpd` on EC2, Linux systemd manages the service, and the workflow verifies `systemctl is-active httpd`, applies bounded retry/stability validation, and publishes the final state through SNS. P2 uses the native `AWS/EC2` `CPUUtilization` metric and `cpu alert`; Lambda requests diagnostic commands only and retains human review for the final decision.**

---

# 29. Final Architecture Summary

```text
                   CloudOps NOC Automation V2.0

                              IAM
                               │
                   Authorization / Least Privilege
                               │
                               ▼

User → VPC → EC2 / HTTPD
                │
                ├── P1 → CloudWatch Agent → procstat
                │                         → procstat_lookup_pid_count
                │
                └── P2 → AWS/EC2 CPUUtilization
                               │
                               ▼
                          CloudWatch
                               │
                           Alarm Event
                               │
                               ▼
                            Lambda
                               │
                    Actionable Alarm Gate
                               │
                     ┌─────────┴─────────┐
                     ▼                   ▼
                    P1                  P2
                     │                   │
                  Recovery           Diagnosis
                     │                   │
                     └─────────┬─────────┘
                               ▼
                              SSM
                               │
                               ▼
                          SSM Agent
                               │
                               ▼
                              EC2
                               │
                               ▼
                            Result
                               │
                               ▼
                              SNS
                               │
                               ▼
                           Engineer
```

---

## Key Design Statement

> **The architecture separates detection, decision, execution, verification, and notification. CloudWatch detects the incident, Lambda decides whether an approved workflow is allowed, Systems Manager performs controlled EC2 operations, Linux manages the local service, SNS communicates the result, IAM authorizes AWS actions, EC2 hosts the workload, and VPC provides the network foundation.**
