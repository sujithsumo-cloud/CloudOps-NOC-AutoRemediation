# P2 CloudWatch Alarm — `cpu alert`

## Overview

`cpu alert` is the **P2 — High CPU utilization alarm** in the CloudOps NOC Automation V2.0 project.

Its purpose is to detect high CPU utilization on the EC2 instance and start a **diagnostic-only incident workflow**.

P2 does **not** automatically restart HTTPD or reboot the EC2 instance.

The current P2 flow is:

```text
Amazon EC2
    │
    ▼
CPUUtilization
    │
    ▼
Amazon CloudWatch
    │
    ▼
cpu alert
    │
    ▼
ALARM
    │
    ▼
Direct Alarm Event
    │
    ▼
AWS Lambda
    │
    ▼
P2 Classification
    │
    ▼
AWS Systems Manager
    │
    ▼
CPU Diagnostics
    │
    ▼
Amazon SNS
    │
    ▼
Operations Engineer
```

The current V2.0 architecture does **not** use SNS between CloudWatch and Lambda.

---

## 1. Alarm Role

| Property | Current Project Value |
|---|---|
| Alarm Name | `cpu alert` |
| Priority | P2 |
| Severity | P2 — High |
| Service | EC2 CPU Utilization |
| Metric Source | Native EC2 metric |
| Namespace | `AWS/EC2` |
| Metric | `CPUUtilization` |
| Project Threshold Label | `> 50%` |
| Detection Service | Amazon CloudWatch |
| Decision Layer | AWS Lambda |
| Diagnostic Layer | AWS Systems Manager |
| Notification Layer | Amazon SNS |
| Automatic Recovery | No |
| Manual Review | Required |

The P2 alarm is responsible for **detecting a high-CPU condition**.

It does not perform remediation itself.

---

## 2. Why P2 Uses a Native EC2 Metric

Unlike the P1 HTTPD process alarm, P2 does not require the CloudWatch Agent for its primary detection metric.

Amazon EC2 already publishes:

```text
AWS/EC2
CPUUtilization
```

to CloudWatch.

Therefore the P2 monitoring path is:

```text
EC2
 │
 ▼
CPUUtilization
 │
 ▼
CloudWatch
 │
 ▼
cpu alert
```

This is different from P1:

```text
P1
HTTPD → CloudWatch Agent → procstat → CloudWatch

P2
EC2 → CPUUtilization → CloudWatch
```

---

## 3. Normal CPU State

When CPU utilization does not satisfy the configured alarm condition:

```text
EC2 CPU
   │
   ▼
CPUUtilization
   │
   ▼
Below Alarm Condition
   │
   ▼
cpu alert = OK
```

No P2 diagnostic workflow is started.

---

## 4. High CPU State

When the configured high-CPU condition is satisfied:

```text
EC2 CPU Increases
       │
       ▼
CPUUtilization
       │
       ▼
Configured Threshold Condition Met
       │
       ▼
cpu alert = ALARM
```

This is the **detection stage**.

The current Lambda configuration identifies the P2 threshold label as:

```text
> 50%
```

The exact CloudWatch statistic, period, evaluation count, and missing-data behavior should remain synchronized with the deployed CloudWatch alarm configuration.

---

## 5. Correct V2.0 Event Flow

When `cpu alert` becomes actionable, CloudWatch sends the alarm event **directly to Lambda**.

Correct:

```text
CloudWatch
   │
   ▼
Lambda
```

Not:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

SNS is used later, after Lambda has processed the P2 incident.

---

## 6. Lambda Parsing and Classification

Lambda receives the direct CloudWatch Alarm event and parses:

```python
event["alarmData"]
```

It validates the alarm state and alarm identity through the Actionable Alarm Gate.

For P2:

```text
Alarm Name = cpu alert
State      = ALARM
        │
        ▼
Approved Alarm?
      /     \
    YES      NO
     │        │
     ▼        ▼
    P2      Ignore
```

The current Lambda configuration defines:

```text
Priority    : P2
Severity    : P2 - High
Action Type : diagnosis
Metric      : CPUUtilization
Threshold   : > 50%
```

This is important:

> **P2 is classified as diagnosis, not recovery.**

---

## 7. Why P2 Is Diagnostic-Only

High CPU utilization is a **symptom**, not a single known root cause.

Possible causes include:

- Legitimate customer traffic.
- Application workload.
- Background jobs.
- A CPU-heavy Linux process.
- Resource pressure.
- Unexpected software behavior.

A blind restart could interrupt a healthy workload or hide the real cause.

For example:

```text
Marketing Campaign
       │
       ▼
Many Real Users
       │
       ▼
CPU High
```

Automatically restarting HTTPD in that situation could make the service worse.

Therefore:

> **Detection does not automatically mean remediation.**

P2 uses a **human-in-the-loop** operational model.

---

## 8. P2 Diagnostic Commands

After Lambda classifies the alarm as P2, it uses Systems Manager Run Command to collect diagnostic evidence.

The current Lambda code uses commands equivalent to:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

These provide:

| Command | Purpose |
|---|---|
| `uptime` | Shows uptime and system load averages |
| `ps aux --sort=-%cpu | head -11` | Shows the highest CPU-consuming processes |
| `free -h` | Shows memory usage |

The current Lambda code also adds section labels to make the captured output easier to read.

---

## 9. P2 SSM Diagnostic Flow

```text
cpu alert
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
   ├── uptime
   ├── top CPU consumers
   └── memory status
```

Systems Manager returns the command result and standard output to Lambda.

Lambda then includes that evidence in the P2 diagnostic notification.

---

## 10. No Automatic CPU Fix

The current P2 policy explicitly does **not** perform:

```text
HTTPD restart
EC2 reboot
Process kill
Destructive remediation
```

The implemented workflow is:

```text
DETECTED
   │
   ▼
DIAGNOSING
   │
   ▼
DIAGNOSED
   │
   ▼
ESCALATED / HANDED TO ENGINEER
```

The current Lambda output states that no automatic fix is applied for CPU and that manual review is required.

---

## 11. Diagnostic Result

After SSM completes the diagnostic command, Lambda reads:

```text
SSM Command ID
SSM Result Status
Standard Output
```

Conceptually:

```text
SSM Diagnostics
      │
      ▼
Command Result
      │
      ▼
Lambda
      │
      ▼
Diagnostic Report
```

If no diagnostic output is captured, the workflow indicates that the SSM Run Command history should be checked.

---

## 12. SNS Notification

After diagnosis, Lambda publishes the P2 result to SNS.

Correct notification path:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

The current Lambda workflow sends:

### Initial notification

```text
High CPU Detected
Diagnostics In Progress
```

### Final notification

```text
CPU Diagnostic Report
Review Required
```

The final message communicates that:

```text
Diagnosis complete
No automatic fix applied
Manual review required
```

SNS delivers the message.

Lambda decides the P2 outcome.

---

## 13. P2 Operational Example

Imagine the EC2 instance reaches high CPU utilization.

CloudWatch detects:

```text
CPUUtilization > configured threshold
```

Then:

```text
cpu alert
   │
   ▼
ALARM
   │
   ▼
Lambda
   │
   ▼
P2 Diagnosis
```

SSM runs:

```text
uptime
ps aux --sort=-%cpu | head -11
free -h
```

Suppose the result shows:

```text
httpd            20%
background-job   65%
```

The automation does not automatically restart HTTPD because the diagnostic evidence suggests another process may be the main CPU consumer.

Instead:

```text
Diagnostic Evidence
       │
       ▼
SNS
       │
       ▼
Engineer Review
```

This is the intended P2 behavior.

---

## 14. P1 vs P2

| Characteristic | P1 — HTTPD | P2 — CPU |
|---|---|---|
| Alarm | `NOC-cloudops-automate` | `cpu alert` |
| Metric | `procstat_lookup_pid_count` | `CPUUtilization` |
| Metric Source | CloudWatch Agent | Native EC2 |
| Action Type | Recovery | Diagnosis |
| Automatic Fix | Yes | No |
| SSM Role | Restart + verify | Collect evidence |
| Verification | HTTPD service check | Diagnostic result status |
| Human Involvement | On failed recovery | Required for final decision |

This separation is intentional.

---

## 15. CloudWatch Recovery to OK

CloudWatch continues evaluating `CPUUtilization` independently of the diagnostic workflow.

If CPU utilization later falls below the alarm condition according to the configured evaluation rules:

```text
CPU Returns to Normal
       │
       ▼
CloudWatch Evaluation
       │
       ▼
cpu alert
       │
       ▼
OK
```

This does **not** mean the P2 automation performed a corrective action.

The CPU condition may recover naturally or after a later engineer action.

---

## 16. Controlled CPU Test

A lab CPU-load test can be used carefully to validate the alarm.

Example:

```bash
yes > /dev/null &
```

Find the process:

```bash
pgrep -a yes
```

Stop the test:

```bash
pkill yes
```

Important:

> A single `yes` process may not raise overall instance CPU enough on a multi-vCPU instance.

Testing should match the instance CPU capacity and the deployed alarm configuration.

Do not leave artificial CPU load running longer than required.

---

## 17. Verification Commands

### View current CPU/load

```bash
top
```

or:

```bash
uptime
```

### CPU information

```bash
lscpu
```

### Highest CPU-consuming processes

```bash
ps aux --sort=-%cpu | head
```

### Memory status

```bash
free -h
```

### Check SSM Agent

```bash
sudo systemctl status amazon-ssm-agent --no-pager
```

### Check HTTPD

```bash
sudo systemctl status httpd --no-pager
```

---

## 18. Troubleshooting P2

If `cpu alert` does not behave as expected, verify the workflow layer by layer.

### CloudWatch Metric

Verify:

```text
Namespace : AWS/EC2
Metric    : CPUUtilization
```

Check:

- Correct EC2 instance.
- Correct AWS Region.
- Correct dimensions.
- Correct statistic.
- Correct period.
- Correct threshold.
- Correct evaluation periods.

### CloudWatch Alarm

Verify:

- Alarm name is `cpu alert`.
- Alarm monitors the intended EC2 instance.
- Alarm action points directly to the intended Lambda function.
- Alarm actions are enabled.
- Alarm state changes during a controlled test.

### Lambda

Verify:

- Lambda receives the direct CloudWatch Alarm event.
- `event["alarmData"]` parsing succeeds.
- Alarm state is `ALARM`.
- Alarm name matches `cpu alert`.
- Actionable Alarm Gate accepts the P2 incident.
- Lambda selects the `handle_p2` diagnosis path.

### Systems Manager

Verify:

- EC2 is a managed node.
- SSM Agent is running.
- Lambda has required SSM permissions.
- SSM Run Command reaches the instance.
- Diagnostic commands complete.
- Command output is returned.

### SNS

Verify:

- Lambda has `sns:Publish` permission.
- `TOPIC_ARN` is correct.
- Subscription is confirmed.
- Diagnostic notification is received.

Do not check for an SNS → Lambda subscription because that is not part of the current V2.0 path.

---

## 19. IAM Dependencies

### Lambda Execution Role

Lambda requires the permissions needed to:

- Send SSM commands.
- Read SSM command results.
- Publish SNS notifications.
- Read required EC2 instance information.
- Write Lambda logs.

### EC2 Instance Role

The EC2 instance requires the permissions necessary to operate as an SSM managed node.

Permissions should follow the **Principle of Least Privilege**.

---

## 20. Important Design Principle

Each component has a separate responsibility:

```text
CloudWatch
    │
    └── Detects high CPU

Lambda
    │
    └── Validates and classifies P2

SSM
    │
    └── Collects diagnostic evidence

SNS
    │
    └── Delivers the diagnostic report

Engineer
    │
    └── Reviews evidence and decides next action
```

Therefore:

> **Monitoring, diagnosis, and remediation are separate decisions.**

---

## 21. Three-Level Interview Answer

### Level 1

> **`cpu alert` is the P2 CloudWatch alarm that detects high EC2 CPU utilization and starts a diagnostic-only workflow.**

### Level 2

> **CloudWatch monitors the native EC2 `CPUUtilization` metric. When the configured P2 condition is met, the alarm event goes directly to Lambda. Lambda identifies it as P2 and uses SSM to collect CPU, load, process, and memory diagnostics instead of automatically restarting the workload.**

### Level 3

> **The Lambda configuration maps `cpu alert` to P2 with `action_type` set to `diagnosis`, `CPUUtilization` as the metric, and a project threshold label of `> 50%`. The P2 handler uses SSM Run Command to execute `uptime`, `ps aux --sort=-%cpu | head -11`, and `free -h`. Lambda captures the SSM result and output, then publishes a diagnostic report to SNS stating that no automatic fix was applied and manual review is required.**

---

## 22. Complete P2 Flow

```text
Amazon EC2
     │
     ▼
CPUUtilization
     │
     ▼
Amazon CloudWatch
     │
     ▼
cpu alert
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
P2 Classification
     │
     ▼
Boto3 / SSM
     │
     ▼
SSM Agent
     │
     ▼
CPU / Load / Process / Memory Diagnostics
     │
     ▼
Lambda Captures Result
     │
     ▼
DIAGNOSED
     │
     ▼
SNS
     │
     ▼
Engineer Review
```

---

## 23. Final Summary

`cpu alert` is the finalized **P2 high-CPU detection alarm** in CloudOps NOC Automation V2.0.

The key flow is:

```text
CloudWatch Detects
        │
        ▼
Lambda Decides
        │
        ▼
SSM Diagnoses
        │
        ▼
SNS Notifies
        │
        ▼
Engineer Decides
```

P2 intentionally stops at diagnosis and engineer review.

---

## Key Design Statement

> **The `cpu alert` alarm detects high EC2 CPU utilization and sends the alarm event directly to Lambda. Lambda classifies the event as P2 and uses Systems Manager to collect diagnostic evidence. No automatic restart or destructive remediation is performed; the result is sent through SNS for manual review.**
