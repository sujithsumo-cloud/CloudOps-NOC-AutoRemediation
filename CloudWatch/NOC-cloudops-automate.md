# P1 CloudWatch Alarm — `NOC-cloudops-automate`

## Overview

`NOC-cloudops-automate` is the **P1 — Critical HTTPD availability alarm** in the CloudOps NOC Automation V2.0 project.

Its purpose is to detect when the configured Apache HTTPD process is no longer present on the EC2 instance and start the controlled P1 incident-response workflow.

The P1 monitoring path is:

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
Amazon CloudWatch
     │
     ▼
NOC-cloudops-automate
     │
     ▼
ALARM
     │
     ▼
Direct Alarm Event
     │
     ▼
AWS Lambda
```

The current V2.0 design does **not** use SNS between CloudWatch and Lambda.

After Lambda processes the incident, SNS is used for operational notification.

---

## 1. Alarm Role

| Property | Current Project Value |
|---|---|
| Alarm Name | `NOC-cloudops-automate` |
| Priority | P1 |
| Severity | P1 — Critical |
| Service | Apache HTTP Server (`httpd`) |
| Metric Source | CloudWatch Agent |
| Metric | `procstat_lookup_pid_count` |
| Configured Condition | `< 1` |
| Detection Service | Amazon CloudWatch |
| Automation Target | AWS Lambda |
| Remediation Path | Lambda → SSM → EC2 |
| Notification Path | Lambda → SNS → Engineer |

The alarm is responsible for **detection**.

It does not restart HTTPD itself.

---

## 2. Why the CloudWatch Agent Is Required

Native EC2 monitoring provides infrastructure metrics such as:

```text
CPUUtilization
NetworkIn
NetworkOut
StatusCheckFailed
```

but the P1 requirement is to monitor the **HTTPD process**.

Therefore the CloudWatch Agent is configured with `procstat` process monitoring.

Conceptually:

```text
Linux
  │
  ▼
HTTPD Processes
  │
  ▼
CloudWatch Agent
  │
  ▼
procstat lookup: httpd
  │
  ▼
Count matching PIDs
  │
  ▼
procstat_lookup_pid_count
```

This gives CloudWatch a process-level detection signal.

---

## 3. What `procstat_lookup_pid_count` Means

`procstat_lookup_pid_count` represents the number of processes matching the configured HTTPD lookup.

Example:

```text
HTTPD Parent Process
HTTPD Worker Process
HTTPD Worker Process
HTTPD Worker Process
        │
        ▼
Matching PID Count > 0
```

If all matching HTTPD processes disappear:

```text
Matching PID Count = 0
```

the configured P1 alarm condition can be satisfied.

Important:

> **PID count is not user count and is not request count.**

Apache can maintain multiple worker processes even when no customer request is currently being handled.

Also:

> **PID count confirms process presence, not complete end-to-end website health.**

A running HTTPD process could still have an application, configuration, network, or HTTP-response problem.

---

## 4. Normal State

When HTTPD is running and the CloudWatch Agent is publishing valid process data:

```text
HTTPD Running
      │
      ▼
Matching Process Detected
      │
      ▼
procstat_lookup_pid_count >= 1
      │
      ▼
P1 Condition Not Met
      │
      ▼
Alarm = OK
```

No P1 remediation is required.

---

## 5. Failure State

If Apache HTTPD stops:

```text
HTTPD Stops
    │
    ▼
Matching HTTPD PIDs Disappear
    │
    ▼
procstat_lookup_pid_count = 0
    │
    ▼
CloudWatch Evaluates:
0 < 1
    │
    ▼
NOC-cloudops-automate = ALARM
```

This is the **incident detection stage**.

---

## 6. Correct V2.0 Alarm Event Flow

When the P1 alarm becomes actionable, the alarm event is sent **directly to Lambda**.

```text
NOC-cloudops-automate
        │
        ▼
      ALARM
        │
        ▼
Direct CloudWatch Alarm Event
        │
        ▼
      Lambda
```

The old flow:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

is not the current V2.0 architecture.

The current architecture is:

```text
CloudWatch
   │
   ▼
Lambda
   │
   ├────────► SSM
   │
   └────────► SNS
```

---

## 7. Lambda Alarm Parsing

Lambda receives the direct CloudWatch Alarm event and parses:

```python
event["alarmData"]
```

The parser obtains information such as:

```text
Alarm Name
Alarm State
Reason
Timestamp
Alarm ARN
Region
```

Conceptually:

```text
Alarm Event
    │
    ▼
event["alarmData"]
    │
    ▼
Alarm Name = NOC-cloudops-automate
State      = ALARM
```

Alarm parsing answers:

> **What alarm event did Lambda receive?**

---

## 8. Actionable Alarm Gate

Lambda does not automatically act on every alarm event.

It validates:

```text
State = ALARM
```

and checks whether the alarm name is in the approved configuration.

For this P1 workflow:

```text
Alarm Name:
NOC-cloudops-automate
        │
        ▼
Known + Approved?
      /     \
    YES      NO
     │        │
     ▼        ▼
    P1      Ignore
```

The Actionable Alarm Gate is a safety control that prevents unknown or unsupported alarms from triggering remediation.

---

## 9. P1 Automated Recovery

After the alarm is validated as P1, Lambda starts the recovery workflow.

The configured remediation command is:

```bash
systemctl restart httpd
```

Execution path:

```text
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

Important responsibility separation:

```text
CloudWatch = Detect
Lambda     = Decide / Orchestrate
SSM        = Controlled Remote Execution
systemd    = Actual Linux Service Management
```

---

## 10. Immediate Verification

The project does not assume that a submitted restart command means the service recovered successfully.

After the recovery attempt, Lambda uses SSM to run:

```bash
systemctl is-active httpd
```

Expected successful output:

```text
active
```

Verification answers:

> **Did HTTPD recover immediately after the corrective action?**

---

## 11. One Automatic Retry

The current P1 Lambda workflow permits **one automatic retry** if the initial recovery attempt fails.

```text
Attempt 1
    │
    ▼
HTTPD Active?
   /       \
 YES        NO
  │          │
  │       Retry Once
  │          │
  │          ▼
  │     HTTPD Active?
  │       /      \
  │     YES       NO
  │      │         │
  ▼      ▼         ▼
Continue       Escalation
```

The retry is intentionally bounded.

The automation does not retry indefinitely.

---

## 12. Stability Verification

If HTTPD passes immediate verification, the current Lambda implementation performs a second service check after approximately **15 seconds**.

```text
Recovery Successful
       │
       ▼
Immediate Check = active
       │
       ▼
Wait 15 Seconds
       │
       ▼
Run:
systemctl is-active httpd
       │
       ▼
Stability Check
```

This distinguishes:

```text
Immediate Recovery
```

from:

```text
Sustained Recovery
```

The incident is considered successfully resolved only when the service is confirmed active through the workflow.

---

## 13. Successful P1 Outcome

A successful P1 incident follows:

```text
DETECTED
   │
   ▼
RECOVERING
   │
   ▼
RECOVERED
   │
   ▼
STABILITY VERIFIED
   │
   ▼
RESOLVED
```

Lambda then publishes the operational result to SNS.

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer / Subscriber
```

SNS is used for communication after Lambda has processed the incident.

---

## 14. Failed P1 Outcome

If the initial recovery and the permitted retry cannot confirm HTTPD as active:

```text
DETECTED
   │
   ▼
RECOVERY FAILED
   │
   ▼
ESCALATED
   │
   ▼
SNS
   │
   ▼
Engineer
```

The engineer receives a notification indicating that manual investigation is required.

Important:

> **Lambda decides to escalate; SNS delivers the escalation notification.**

---

## 15. CloudWatch Alarm Recovery

After HTTPD returns and the CloudWatch Agent resumes publishing a healthy process-count metric, CloudWatch can evaluate the alarm back toward:

```text
OK
```

Conceptually:

```text
HTTPD Recovered
      │
      ▼
Matching PIDs Present
      │
      ▼
CloudWatch Agent
      │
      ▼
procstat_lookup_pid_count >= 1
      │
      ▼
Alarm Condition Clears
      │
      ▼
CloudWatch Alarm = OK
```

This CloudWatch alarm-state recovery is separate from Lambda's immediate and stability verification logic.

---

## 16. `INSUFFICIENT_DATA`

CloudWatch can also show:

```text
INSUFFICIENT_DATA
```

when it does not have enough valid datapoints to evaluate the alarm.

For this P1 metric, that can occur when the EC2 instance is stopped because:

```text
EC2 Stopped
    │
    ▼
CloudWatch Agent Stopped
    │
    ▼
No New procstat Metric
    │
    ▼
CloudWatch Lacks Data
```

`INSUFFICIENT_DATA` does not automatically mean HTTPD has failed.

It means CloudWatch cannot currently determine the alarm state from available datapoints.

---

## 17. Manual P1 Failure Test

A controlled P1 test can be performed by stopping Apache HTTPD:

```bash
sudo systemctl stop httpd
```

Verify:

```bash
sudo systemctl status httpd --no-pager
```

Check matching processes:

```bash
pgrep -a httpd
```

Expected conceptual sequence:

```text
systemctl stop httpd
        │
        ▼
HTTPD Processes Disappear
        │
        ▼
CloudWatch Agent Publishes Updated Metric
        │
        ▼
NOC-cloudops-automate
        │
        ▼
ALARM
        │
        ▼
Lambda
        │
        ▼
SSM Recovery
```

---

## 18. Verification Commands

### Check HTTPD

```bash
sudo systemctl status httpd --no-pager
```

### Check HTTPD active state

```bash
systemctl is-active httpd
```

### Check HTTPD processes

```bash
pgrep -a httpd
```

### Test HTTP locally

```bash
curl http://localhost
```

### Check CloudWatch Agent

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
```

### Check SSM Agent

```bash
sudo systemctl status amazon-ssm-agent --no-pager
```

---

## 19. Troubleshooting

If `NOC-cloudops-automate` does not trigger or recover as expected, check the workflow layer by layer.

### Detection Layer

```text
HTTPD State
   ↓
CloudWatch Agent State
   ↓
procstat Configuration
   ↓
procstat_lookup_pid_count
   ↓
Alarm Configuration
```

Verify:

- HTTPD actually stopped.
- CloudWatch Agent is running.
- `procstat` is configured to match `httpd`.
- The expected process-count metric reaches CloudWatch.
- The alarm is using the correct metric and condition.
- The alarm is configured with the correct Lambda action.

### Lambda Layer

Verify:

- Lambda received the direct alarm event.
- `event["alarmData"]` was parsed.
- Alarm state is `ALARM`.
- Alarm name exactly matches `NOC-cloudops-automate`.
- The actionable gate accepted the incident.

### SSM Layer

Verify:

- EC2 is an SSM managed node.
- SSM Agent is running.
- Lambda has the required SSM permissions.
- Run Command execution succeeded.
- HTTPD commands are valid on the instance.

### Notification Layer

Verify:

- Lambda has `sns:Publish` permission.
- `TOPIC_ARN` is correct.
- SNS subscription is confirmed.

Do **not** troubleshoot an SNS → Lambda subscription for this P1 workflow because SNS is not the current Lambda trigger.

---

## 20. IAM Dependencies

### Lambda Execution Role

Lambda requires the permissions necessary for:

- SSM command execution.
- Reading SSM command results.
- SNS publishing.
- Required EC2 read operations.
- Lambda/CloudWatch logging.

### EC2 Instance Role

The EC2 instance requires the permissions necessary for:

- SSM managed-node operation.
- CloudWatch Agent monitoring/log publishing as configured.

The project follows the **Principle of Least Privilege**.

---

## 21. Detection vs Remediation

A key architecture principle is:

> **Detection ≠ Remediation**

For P1:

```text
CloudWatch
= Detects HTTPD process failure

Lambda
= Decides whether the event is approved

SSM
= Executes the approved remote operation

systemd
= Performs the HTTPD service restart

Lambda
= Verifies recovery

SNS
= Communicates the result
```

Each layer has a separate responsibility.

---

## 22. Three-Level Interview Answer

### Level 1

> **`NOC-cloudops-automate` is the P1 CloudWatch alarm that detects HTTPD process failure.**

### Level 2

> **The CloudWatch Agent uses procstat to publish the HTTPD process-count metric. If `procstat_lookup_pid_count` falls below 1 according to the configured alarm evaluation, `NOC-cloudops-automate` enters ALARM and sends the alarm event directly to Lambda.**

### Level 3

> **Lambda parses `event["alarmData"]`, validates the ALARM state and the approved alarm name, and starts the P1 recovery workflow. Lambda uses Boto3 to call SSM Run Command, SSM executes `systemctl restart httpd` on EC2, and Lambda verifies the service with `systemctl is-active httpd`. The current code allows one retry and performs a 15-second stability recheck before resolving or escalating the incident through SNS.**

---

## 23. Complete P1 Flow

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
NOC-cloudops-automate
     │
     ▼
ALARM
     │
     ▼
Direct Alarm Event
     │
     ▼
Lambda
     │
     ▼
Alarm Parser
     │
     ▼
Actionable Alarm Gate
     │
     ▼
P1 Recovery
     │
     ▼
Boto3 / SSM
     │
     ▼
SSM Agent
     │
     ▼
systemctl restart httpd
     │
     ▼
Immediate Verification
     │
     ▼
One Retry if Required
     │
     ▼
15-Second Stability Check
     │
   ┌─┴─────────────┐
   ▼               ▼
Resolved        Escalated
   │               │
   └───────┬───────┘
           ▼
          SNS
           │
           ▼
        Engineer
```

---

## 24. Final Summary

`NOC-cloudops-automate` is the finalized **P1 HTTPD detection alarm** for CloudOps NOC Automation V2.0.

The key relationship is:

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
systemd Restarts HTTPD
        │
        ▼
Lambda Verifies
        │
        ▼
SNS Notifies
```

---

## Key Design Statement

> **The `NOC-cloudops-automate` alarm detects HTTPD process unavailability and sends the alarm event directly to Lambda. Lambda validates the incident and orchestrates recovery through Systems Manager; SNS is used afterward for operational notification, not as the Lambda trigger.**
