# AWS Lambda — Incident Decision and Orchestration

## Overview

AWS Lambda is the **decision and orchestration layer** of the CloudOps NOC Automation V2.0 project.

The current architecture uses a **direct CloudWatch Alarm → Lambda** event path. Lambda receives the alarm event, parses the alarm context, validates whether the event is actionable, identifies the incident type, and starts the appropriate P1 recovery or P2 diagnostic workflow.

Lambda does **not** directly log in to the EC2 instance and it does **not** directly restart Apache HTTPD. For EC2 operations, the Lambda function uses **Boto3**, the AWS SDK for Python, to call **AWS Systems Manager (SSM)** APIs.

---

## 1. Role in the Project

Lambda is responsible for:

- Receiving direct CloudWatch Alarm events.
- Parsing `event["alarmData"]`.
- Validating that the alarm state is `ALARM`.
- Applying the **Actionable Alarm Gate**.
- Ignoring unknown or unsupported alarms.
- Classifying incidents as P1 or P2.
- Calling AWS Systems Manager through Boto3.
- Coordinating P1 HTTPD recovery.
- Coordinating P2 CPU diagnostics.
- Verifying P1 recovery.
- Performing a stability verification.
- Applying the configured bounded retry behavior.
- Publishing incident results and escalation notifications through Amazon SNS.

In simple terms:

> **CloudWatch detects. Lambda decides. SSM executes. SNS notifies.**

---

## 2. Lambda Architecture

```text
CloudWatch Alarm
      │
      ▼
Direct Alarm Event
      │
      ▼
AWS Lambda
      │
      ▼
Parse event["alarmData"]
      │
      ▼
Check Alarm State
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
   │      │
   │      └──► SSM Diagnostics
   │
   └─────────► SSM Recovery
                │
                ▼
               EC2
                │
                ▼
        Verification / Stability
                │
                ▼
               SNS
                │
                ▼
        Operations Engineer
```

---

## 3. Direct CloudWatch Alarm Parsing

The Lambda function expects the current direct CloudWatch Alarm event format and reads:

```python
event["alarmData"]
```

The parser extracts operational context such as:

- Alarm name
- Alarm state
- Alarm reason
- Timestamp
- Alarm ARN
- AWS account
- AWS Region

Conceptually:

```text
Alarm Event
    │
    ▼
event["alarmData"]
    │
    ▼
Alarm Name
State
Reason
Timestamp
```

**Alarm parsing** answers:

> **What alarm event did Lambda receive?**

---

## 4. Actionable Alarm Gate

Not every incoming event is allowed to start automation.

The Lambda function first verifies that the alarm state is:

```text
ALARM
```

It then checks whether the alarm name exists in the approved alarm configuration.

Current actionable alarms are:

| Alarm | Priority | Metric | Action |
|---|---|---|---|
| `NOC-cloudops-automate` | P1 | `procstat_lookup_pid_count` | HTTPD recovery |
| `cpu alert` | P2 | `CPUUtilization` | CPU diagnosis |

Conceptually:

```text
Parsed Alarm
     │
     ▼
State = ALARM?
   /        \
 NO         YES
 │           │
 ▼           ▼
Ignore    Known Alarm?
           /      \
         NO        YES
         │          │
         ▼          ▼
       Ignore     Continue
```

The Actionable Alarm Gate is an **automation safety control** that prevents unknown or unsupported alarms from starting operational actions.

---

## 5. P1 — HTTPD Failure

### Detection

P1 uses:

```text
Alarm  : NOC-cloudops-automate
Metric : procstat_lookup_pid_count
Rule   : < 1
```

The metric represents the number of matching HTTPD processes reported through the CloudWatch Agent procstat monitoring configuration.

When the configured alarm condition becomes actionable, Lambda identifies the event as:

```text
P1 - Critical
Apache HTTP Server (httpd)
Action Type: Recovery
```

### Recovery command

The configured recovery action is:

```bash
systemctl restart httpd
```

The configured verification command is:

```bash
systemctl is-active httpd
```

### P1 execution path

```text
P1 Alarm
   │
   ▼
Lambda
   │
   ▼
Boto3
   │
   ▼
SSM SendCommand API
   │
   ▼
AWS Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2 Linux
   │
   ▼
systemctl restart httpd
   │
   ▼
systemd
   │
   ▼
Apache HTTPD
```

Lambda **requests and coordinates** the recovery.

Systems Manager provides the controlled command-execution path.

Linux `systemd` ultimately manages the HTTPD service.

---

## 6. P1 Verification

A successful command submission does not automatically prove that HTTPD recovered.

After remediation, the automation checks:

```bash
systemctl is-active httpd
```

Expected successful output:

```text
active
```

Verification answers:

> **Did HTTPD recover immediately after the remediation action?**

---

## 7. Stability Verification

Immediate recovery can be temporary.

For example:

```text
Restart
   ↓
HTTPD active
   ↓
Short time passes
   ↓
HTTPD fails again
```

To avoid reporting a temporary recovery as a successful resolution, the current P1 workflow performs a second service-status check after a **15-second stability interval**.

Conceptually:

```text
HTTPD Restart
      │
      ▼
Immediate Verification
      │
      ▼
Active
      │
      ▼
Wait 15 Seconds
      │
      ▼
Stability Verification
      │
      ▼
Still Active?
```

The stability verification answers:

> **Did the recovered service remain healthy after the initial recovery?**

---

## 8. Bounded Retry and Escalation

The P1 workflow uses a **bounded retry** rather than an unlimited recovery loop.

If the initial recovery attempt fails, the automation allows the configured retry attempt.

Conceptually:

```text
Initial Recovery
      │
      ▼
Successful?
   /       \
 YES        NO
  │          │
  │       Retry
  │          │
  │          ▼
  │      Successful?
  │       /       \
  │      YES       NO
  │       │         │
  ▼       ▼         ▼
Resolved         Escalation
```

If the service cannot be confirmed active and stable after the allowed recovery attempts, the incident is escalated for manual investigation.

This prevents uncontrolled automation loops.

---

## 9. P2 — High CPU Diagnosis

P2 uses:

```text
Alarm  : cpu alert
Metric : CPUUtilization
Rule   : > 50%
```

P2 is **diagnostic-only**.

The Lambda function does not automatically restart HTTPD or the EC2 instance for a high-CPU condition.

The configured diagnostic commands collect evidence such as:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

The diagnostic workflow is:

```text
cpu alert
    │
    ▼
Lambda
    │
    ▼
P2 Identified
    │
    ▼
SSM Diagnostics
    │
    ▼
CPU / Load / Process / Memory Evidence
    │
    ▼
SNS
    │
    ▼
Operations Engineer
```

### Why P2 is diagnostic-only

High CPU utilization is a **symptom with multiple possible root causes**.

Examples include:

- Legitimate user traffic
- Application workload
- Background processes
- Misbehaving processes
- Resource pressure

For this reason:

> **Detection does not automatically mean remediation.**

P2 keeps human judgment in the operational decision loop.

---

## 10. Boto3 and AWS APIs

The Lambda function is written in Python and creates AWS clients with Boto3.

Conceptually:

```text
Lambda Python Code
        │
        ▼
      Boto3
        │
        ▼
     AWS API
        │
   ┌────┼────┐
   ▼    ▼    ▼
  SSM  SNS   EC2
```

Boto3 is used to interact programmatically with AWS services.

Examples include:

- Calling Systems Manager Run Command.
- Reading command execution results.
- Publishing SNS notifications.
- Reading EC2 instance details.

Lambda does not need to open an AWS console or manually connect to the instance. It communicates through AWS APIs.

---

## 11. Systems Manager Integration

The Lambda function uses Systems Manager Run Command with the AWS-managed document:

```text
AWS-RunShellScript
```

Conceptually:

```text
Lambda
   │
   ▼
Boto3
   │
   ▼
ssm:SendCommand
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
Linux Shell
```

The SSM layer separates the **automation decision** from the **server-side command execution**.

This is an important design principle:

```text
Lambda
= Decision / Orchestration

SSM
= Controlled Execution

systemd
= Linux Service Management
```

---

## 12. SNS Integration

SNS is used after incident processing to deliver operational notifications.

The current V2.0 architecture is:

```text
CloudWatch
     │
     ▼
Lambda
     │
     ▼
Incident Processing
     │
     ▼
SNS
     │
     ▼
Subscriber / Engineer
```

SNS is **not** the trigger between CloudWatch and Lambda in the current design.

Lambda publishes incident results to SNS for scenarios such as:

- Successful recovery
- Recovery failure
- Escalation
- P2 diagnostic results

SNS is the **notification transport**.

Escalation is the **operational decision to involve a human engineer**.

---

## 13. IAM and Least Privilege

Lambda uses an execution role.

The execution role should contain only the permissions required for the project workflow.

Required capabilities include access to the relevant:

- Systems Manager operations
- SNS publishing
- EC2 read operations
- Lambda logging

The project follows the **Principle of Least Privilege**:

> Give an identity only the minimum permissions required to perform its responsibility.

Lambda should not receive broad administrator permissions when narrower permissions are sufficient.

---

## 14. P1 vs P2 Decision Model

| Characteristic | P1 — HTTPD | P2 — CPU |
|---|---|---|
| Alarm | `NOC-cloudops-automate` | `cpu alert` |
| Metric | `procstat_lookup_pid_count` | `CPUUtilization` |
| Priority | P1 | P2 |
| Action Type | Recovery | Diagnosis |
| Automatic corrective action | Yes | No |
| SSM usage | Restart + verify | Collect diagnostics |
| Human involvement | On escalation | Required for final decision |

The core operational principle is:

> **Monitoring, diagnosis, and remediation are separate decisions.**

---

## 15. Failure Handling

The Lambda workflow is designed to handle failures safely.

Examples include:

- Invalid event format
- Alarm state other than `ALARM`
- Unknown alarm name
- SSM command failure
- SSM invocation timeout
- HTTPD verification failure
- Stability verification failure

Unknown alarms are ignored rather than triggering uncontrolled actions.

Failed P1 recovery is escalated instead of retrying indefinitely.

---

## 16. Operational Responsibility Model

| Layer | Component | Responsibility |
|---|---|---|
| Network | VPC | Network foundation |
| Workload | EC2 / HTTPD | Run the web workload |
| Monitoring | CloudWatch | Detect incident conditions |
| Decision | Lambda | Parse, validate, classify, orchestrate |
| Execution | Systems Manager | Execute controlled EC2 operations |
| Linux service control | systemd | Start/restart/manage HTTPD |
| Notification | SNS | Deliver incident notifications |
| Authorization | IAM | Control AWS permissions |

---

## 17. Three-Level Interview Answer

### Level 1

> **Lambda is the decision and orchestration layer of the project.**

### Level 2

> **Lambda receives the direct CloudWatch alarm event, parses and validates it, applies the actionable-alarm gate, identifies P1 or P2, and starts the appropriate remediation or diagnostic workflow.**

### Level 3

> **The Lambda Python function reads `event["alarmData"]` and validates that the event is in the `ALARM` state and belongs to the approved alarm configuration. For P1, it uses Boto3 to call the SSM SendCommand API, coordinates HTTPD restart verification and stability checking, and publishes the result through SNS. For P2, it uses SSM to collect diagnostic evidence rather than automatically restarting the workload.**

---

## 18. Summary

AWS Lambda is the **decision and orchestration layer** of CloudOps NOC Automation V2.0.

The Lambda workflow can be summarized as:

```text
Receive
   │
   ▼
Parse
   │
   ▼
Validate
   │
   ▼
Classify
   │
   ▼
Orchestrate
   │
   ▼
Verify
   │
   ▼
Notify / Escalate
```

End-to-end:

```text
CloudWatch Detects
        │
        ▼
Lambda Decides
        │
        ▼
SSM Executes
        │
        ▼
EC2 / Linux Runs
        │
        ▼
Lambda Verifies
        │
        ▼
SNS Notifies
```

---

## Key Design Statement

> **Lambda does not directly restart HTTPD. Lambda decides and requests the approved recovery action through Systems Manager; Systems Manager delivers the command to the EC2 instance, and Linux systemd performs the actual HTTPD service restart.**
