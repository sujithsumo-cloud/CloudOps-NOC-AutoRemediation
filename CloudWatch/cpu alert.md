# CloudWatch CPU Utilization Alarm — P2 High

## Overview

The CPU Utilization CloudWatch Alarm is the **P2 – High severity** monitoring and automation component of the CloudOps NOC Automation project.

Its purpose is to detect sustained high CPU utilization on the Amazon EC2 instance and initiate the project's automated incident-response workflow.

The alarm monitors the standard EC2 `CPUUtilization` metric provided by Amazon CloudWatch. When CPU utilization satisfies the configured threshold and evaluation criteria, the alarm changes to the **ALARM** state and publishes an event to the project's Amazon SNS topic.

The SNS event invokes the AWS Lambda automation function, which uses AWS Systems Manager Run Command to perform the configured CPU remediation action on the affected EC2 instance.

---

# 1. Severity

| Property | Configuration |
| --- | --- |
| Severity | **P2 – High** |
| Service | Amazon EC2 |
| Failure Type | High CPU utilization |
| Monitoring Service | Amazon CloudWatch |
| Metric Source | Amazon EC2 |
| Notification | Amazon SNS |
| Automation | AWS Lambda |
| Remediation | AWS Systems Manager Run Command |
| Target | Amazon EC2 |

P2 represents the **high-severity infrastructure performance condition** in this project.

> **P3 is not part of this project scope.**

---

# 2. Purpose

The CPU alarm is designed to:

- Detect high CPU utilization on the EC2 instance.
- Generate a P2 high-severity incident condition.
- Notify the NOC administrator.
- Trigger the automated remediation workflow.
- Execute the configured SSM remediation command.
- Reduce prolonged CPU-related service impact.
- Allow CloudWatch to monitor the recovery state.

---

# 3. Monitoring Architecture

```text
Amazon EC2
    │
    │ CPU Utilization
    ▼
Amazon CloudWatch
    │
    │ Alarm Evaluation
    ▼
P2 CPU Alarm
    │
    │ ALARM State
    ▼
Amazon SNS
    │
    ├──────────────► Email Notification
    │
    ▼
AWS Lambda
    │
    ▼
AWS Systems Manager
    │
    ▼
SSM Agent
    │
    ▼
EC2
    │
    ▼
Configured CPU Remediation
```

---

# 4. Alarm Condition

The alarm evaluates the standard EC2 CPU utilization metric:

```text
Namespace: AWS/EC2
Metric: CPUUtilization
```

When CPU utilization remains below the configured alarm threshold:

```text
EC2 CPU
   │
   ▼
Normal CPU Utilization
   │
   ▼
CloudWatch Metric
   │
   ▼
Alarm = OK
```

When CPU utilization reaches or exceeds the configured threshold:

```text
High CPU Utilization
        │
        ▼
CloudWatch CPUUtilization
        │
        ▼
Threshold Condition Satisfied
        │
        ▼
P2 Alarm = ALARM
```

The exact threshold, period, evaluation periods, statistic, dimensions, and alarm actions must match the configuration deployed in the AWS environment.

---

# 5. Alarm Configuration

The following values describe the project configuration. Keep the numerical values synchronized with the actual CloudWatch console configuration.

| Property | Value |
| --- | --- |
| Alarm Purpose | Detect high EC2 CPU utilization |
| Severity | **P2 – High** |
| Namespace | `AWS/EC2` |
| Metric | `CPUUtilization` |
| Statistic | Configured CloudWatch statistic |
| Threshold | Configured CPU percentage |
| Period | Configured evaluation period |
| Evaluation Periods | Configured evaluation count |
| Alarm Action | Amazon SNS |
| Notification | NOC administrator |
| Automation | AWS Lambda |
| Remediation | AWS Systems Manager Run Command |
| Target | Project EC2 instance |

> Do not document a threshold such as 80% or 90% as the deployed value unless that exact value is present in the AWS environment.

---

# 6. Normal State

When CPU utilization is below the configured alarm threshold:

```text
EC2
 │
 ▼
CPU Utilization
 │
 ▼
Below Alarm Threshold
 │
 ▼
CloudWatch Alarm
 │
 ▼
OK
```

No remediation action is required.

---

# 7. High CPU State

When CPU utilization satisfies the configured alarm condition:

```text
EC2
 │
 ▼
High CPU Utilization
 │
 ▼
CloudWatch CPU Metric
 │
 ▼
Threshold Condition Satisfied
 │
 ▼
P2 Alarm = ALARM
```

The alarm action then publishes the event to Amazon SNS.

---

# 8. Automated Remediation Workflow

After the P2 CPU alarm enters the ALARM state:

### Step 1 – Detection

Amazon CloudWatch detects that the configured CPU utilization condition has been satisfied.

### Step 2 – Alarm

The CPU alarm changes from:

```text
OK
```

to:

```text
ALARM
```

### Step 3 – SNS Notification

CloudWatch publishes the alarm event to the configured SNS topic.

### Step 4 – Lambda Invocation

SNS invokes the project's Lambda automation function:

```text
Cloudops-NOC-automate
```

### Step 5 – SSM Command

Lambda calls AWS Systems Manager Run Command.

### Step 6 – CPU Remediation

SSM Agent executes the configured Linux remediation command on the EC2 instance.

The exact command must match the remediation implemented in the deployed Lambda/SSM configuration.

### Step 7 – Verification

The automation checks whether the remediation command completed successfully and, where configured, verifies that the affected condition has recovered.

### Step 8 – Monitoring Recovery

CloudWatch continues evaluating `CPUUtilization`.

If CPU utilization returns below the configured threshold for the required evaluation period, the alarm can return to:

```text
OK
```

---

# 9. CPU Failure Simulation

For testing, CPU load should be generated in a controlled manner and only for the duration required to validate the alarm.

Example Linux test command:

```bash
yes > /dev/null &
```

Identify the test process:

```bash
pgrep -a yes
```

Stop the test process:

```bash
pkill yes
```

For a multi-vCPU EC2 instance, a single CPU-consuming process may not raise overall CPU utilization enough to cross the alarm threshold. The test method must therefore match the number of vCPUs and the configured alarm threshold.

> Perform CPU-load testing carefully because excessive load can affect the Apache web server and other project components.

---

# 10. Expected Automation Flow

```text
CPU Load Generated
        │
        ▼
EC2 CPU Utilization Increases
        │
        ▼
CloudWatch CPUUtilization
        │
        ▼
P2 CPU Alarm
        │
        ▼
ALARM
        │
        ▼
SNS
        │
        ├────────────► NOC Email
        │
        ▼
Lambda
        │
        ▼
SSM Run Command
        │
        ▼
Configured CPU Remediation
        │
        ▼
CPU Condition Verified
        │
        ▼
CloudWatch Recovery
        │
        ▼
OK
```

---

# 11. Verification Commands

### Check CPU utilization

```bash
top
```

or:

```bash
uptime
```

### Check CPU information

```bash
lscpu
```

### Find CPU-consuming processes

```bash
ps aux --sort=-%cpu | head
```

### Check CloudWatch Agent

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
```

### Check SSM Agent

```bash
sudo systemctl status amazon-ssm-agent --no-pager
```

### Check Apache

```bash
sudo systemctl status httpd --no-pager
```

### Test the web server

```bash
curl http://localhost
```

---

# 12. Troubleshooting

If the P2 CPU alarm does not trigger, check the following.

## CloudWatch Metric

Verify that the EC2 instance is publishing:

```text
AWS/EC2
CPUUtilization
```

Check:

- Correct EC2 instance.
- Correct AWS Region.
- Correct metric dimensions.
- Correct statistic.
- Correct period.
- Correct threshold.
- Correct evaluation periods.

## CloudWatch Alarm

Verify:

- Alarm exists.
- Alarm is associated with the correct EC2 instance.
- Alarm action points to the correct SNS topic.
- Alarm is enabled.
- Alarm state changes during the controlled CPU test.

## SNS

Verify:

- SNS topic exists.
- CloudWatch alarm action references the correct topic.
- Email subscription is confirmed.
- Lambda subscription exists.
- Lambda invocation is being received.

## Lambda

Check Lambda execution logs in:

```text
Amazon CloudWatch Logs
```

Verify:

- SNS event is received.
- Event parsing succeeds.
- SSM command is submitted.
- Target instance ID is correct.
- No IAM authorization error occurs.

## Systems Manager

Verify:

```bash
sudo systemctl status amazon-ssm-agent --no-pager
```

Also check:

- EC2 is registered as a managed node.
- SSM Agent is running.
- EC2 has the required IAM role.
- SSM Run Command reaches the target instance.
- Command execution completes successfully.

---

# 13. IAM Dependencies

The P2 workflow depends on appropriate IAM permissions.

## EC2 Role

The EC2 instance requires the permissions necessary for Systems Manager management, commonly provided through:

```text
AmazonSSMManagedInstanceCore
```

## Lambda Role

Lambda requires only the permissions needed by the deployed automation, including the required Systems Manager operations and CloudWatch Logs permissions.

The project should use a least-privilege custom policy where practical rather than granting unnecessary broad access.

---

# 14. Important Design Principle

Each service has a separate responsibility:

```text
CloudWatch
    │
    └── Detects high CPU utilization

SNS
    │
    └── Distributes the alarm event

Lambda
    │
    └── Orchestrates remediation

SSM
    │
    └── Executes the remote command

EC2
    │
    └── Executes the Linux operation
```

Therefore:

```text
Detection ≠ Remediation
```

This separation makes the NOC automation workflow easier to monitor, troubleshoot, and secure.

---

# 15. P1 and P2 Relationship

The project uses two severity levels:

| Severity | Condition | Primary Monitoring |
| --- | --- | --- |
| **P1 – Critical** | Apache HTTPD service failure | HTTPD process/service alarm |
| **P2 – High** | High EC2 CPU utilization | `CPUUtilization` alarm |

P1 represents a critical application/service availability problem.

P2 represents a high-severity infrastructure performance problem.

> **P3 is intentionally excluded from the finalized project scope.**

---

# 16. Operational Result

A successful P2 incident should follow this pattern:

```text
P2 High CPU Condition Detected
        ↓
CloudWatch Alarm = ALARM
        ↓
SNS Notification
        ↓
Lambda Invoked
        ↓
SSM Command Executed
        ↓
Configured Remediation
        ↓
Condition Re-checked
        ↓
CloudWatch Recovery
```

The objective is to detect abnormal CPU utilization, automatically execute the configured remediation, and verify that the infrastructure condition returns to a healthy state.

---

# 17. Repository Reference

Recommended location:

```text
cloudops-noc/
│
├── cloudwatch/
│   ├── alarms/
│   │   ├── httpd-alarm.md
│   │   └── cpu-alarm.md
│   │
│   └── dashboard.json
```

---

# 18. Summary

The CPU Utilization alarm is the **P2 – High** monitoring and automation mechanism for EC2 CPU performance.

It connects monitoring with the project's automated remediation pipeline:

```text
CloudWatch
    ↓
SNS
    ↓
Lambda
    ↓
SSM
    ↓
EC2
    ↓
Configured CPU Remediation
```

The P2 workflow demonstrates the project's second operational use case:

> **Detect high CPU utilization, notify the NOC operator, initiate automated remediation, and verify recovery.**
