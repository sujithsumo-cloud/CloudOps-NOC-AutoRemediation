# Amazon CloudWatch — Monitoring, Metrics, Logs, and Incident Detection

## Overview

Amazon CloudWatch is the **central monitoring and incident-detection layer** of the CloudOps NOC Automation V2.0 project.

The project uses CloudWatch to:

- Receive AWS-native EC2 metrics.
- Receive operating-system and process metrics from the CloudWatch Agent.
- Collect selected EC2 and Apache log files.
- Visualize infrastructure and workload health.
- Evaluate P1 and P2 alarm conditions.
- Generate direct CloudWatch Alarm events for AWS Lambda.

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

Amazon SNS is **not** used between CloudWatch and Lambda in the current architecture.

In simple terms:

> **CloudWatch monitors and detects. Lambda decides. SSM executes. SNS communicates the result.**

---

## 1. Role in the Project

CloudWatch is responsible for:

- Monitoring the EC2 workload.
- Receiving the P1 HTTPD process-count metric from the CloudWatch Agent.
- Monitoring the native EC2 `CPUUtilization` metric for P2.
- Collecting configured Apache and Linux log files through the CloudWatch Agent.
- Evaluating alarm thresholds and state changes.
- Providing `OK`, `ALARM`, and `INSUFFICIENT_DATA` alarm states.
- Sending the direct alarm event to Lambda when the configured alarm action becomes actionable.
- Providing operational visibility for troubleshooting and verification.

CloudWatch is the **detector**, not the remediation engine.

---

## 2. High-Level Monitoring Architecture

```text
                         Amazon EC2
                              │
                  ┌───────────┴───────────┐
                  │                       │
                  ▼                       ▼
            Apache HTTPD             EC2 CPU
                  │                       │
                  ▼                       │
          CloudWatch Agent                │
                  │                       │
              procstat                    │
                  │                       │
                  ▼                       ▼
    procstat_lookup_pid_count       CPUUtilization
                  │                       │
                  └───────────┬───────────┘
                              ▼
                       Amazon CloudWatch
                              │
                       Alarm Evaluation
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
             P1 HTTPD Alarm        P2 CPU Alarm
                    │                   │
                    └─────────┬─────────┘
                              ▼
                    Direct Alarm Event
                              │
                              ▼
                            Lambda
```

---

## 3. CloudWatch Components Used

| Component | Project Responsibility |
|---|---|
| CloudWatch Metrics | Stores and displays monitoring measurements |
| CloudWatch Agent | Collects configured OS, process, network, and log data from EC2 |
| CloudWatch Alarms | Evaluates P1 and P2 incident conditions |
| CloudWatch Dashboard | Provides centralized operational visibility |
| CloudWatch Logs | Stores configured Lambda, Apache, and Linux logs |

CloudWatch is one of the seven implemented AWS services in the project.

---

## 4. Monitoring Sources

The project uses **two different metric sources**.

### P1 — CloudWatch Agent custom metric

```text
HTTPD
  │
  ▼
CloudWatch Agent
  │
  ▼
procstat
  │
  ▼
procstat_lookup_pid_count
```

### P2 — Native EC2 metric

```text
Amazon EC2
    │
    ▼
AWS/EC2
CPUUtilization
```

This distinction is important:

> **P1 requires process-level visibility from the CloudWatch Agent. P2 uses a standard EC2 metric already available in CloudWatch.**

---

## 5. CloudWatch Agent

The CloudWatch Agent runs on the EC2 instance.

The current repository configuration uses:

```text
metrics_collection_interval = 60 seconds
namespace                   = CWAgent
```

The configuration appends the EC2 instance ID as a metric dimension.

The agent collects configured operating-system, process, network, and log data and publishes them to CloudWatch.

Conceptually:

```text
Linux / HTTPD
      │
      ▼
CloudWatch Agent
      │
      ▼
Collect configured data
      │
      ▼
Publish to CloudWatch
```

---

## 6. Current CloudWatch Agent Metrics

The current configuration collects the following metric categories.

### CPU

```text
cpu_usage_idle
cpu_usage_user
cpu_usage_system
```

### Memory

```text
mem_used_percent
```

### Disk

```text
used_percent
```

for configured disk resources.

### Network

The configured Linux network interface is:

```text
ens5
```

Measurements include:

```text
bytes_sent
bytes_recv
```

### HTTPD Process Monitoring

The process-monitoring configuration uses:

```text
pattern = httpd
measurement = pid_count
```

Conceptually:

```text
Linux HTTPD Processes
       │
       ▼
procstat lookup "httpd"
       │
       ▼
Count matching PIDs
       │
       ▼
procstat_lookup_pid_count
       │
       ▼
CloudWatch
```

---

## 7. What Exactly Is `procstat`?

`procstat` is the **CloudWatch Agent process-monitoring component/plugin** used to collect statistics about configured processes.

It is not the same as Linux `/proc`.

```text
/proc
= Linux virtual filesystem/interface exposing process information

procstat
= CloudWatch Agent process-monitoring component
```

In this project:

```text
procstat
   │
   ▼
Lookup pattern: httpd
   │
   ▼
Find matching HTTPD processes
   │
   ▼
Count matching PIDs
   │
   ▼
Publish process-count metric
```

The project uses this process-count metric as the P1 detection signal.

---

## 8. P1 — HTTPD Monitoring

### Alarm

```text
NOC-cloudops-automate
```

### Priority

```text
P1 — Critical
```

### Metric

```text
procstat_lookup_pid_count
```

### Configured condition

```text
< 1
```

Conceptually:

```text
Matching HTTPD processes exist
           │
           ▼
PID Count >= 1
           │
           ▼
Alarm normally remains OK
```

Failure:

```text
HTTPD stops
    │
    ▼
No matching HTTPD process
    │
    ▼
PID Count = 0
    │
    ▼
CloudWatch evaluates < 1
    │
    ▼
P1 Alarm = ALARM
```

---

## 9. Important PID-Count Meaning

The P1 metric indicates **matching HTTPD process presence**.

It does not mean:

```text
PID Count = Number of users
```

and it does not mean:

```text
PID Count = Number of HTTP requests
```

Apache can have a parent process and multiple worker processes even when no users are actively sending requests.

Therefore:

> **`procstat_lookup_pid_count` is used as a process-availability signal, not as a user-count or full application-health metric.**

A positive PID count confirms matching HTTPD processes exist, but it does not by itself prove complete end-to-end HTTP health.

---

## 10. P1 Event Flow

The current V2.0 P1 flow is:

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
ALARM
      │
      ▼
Direct CloudWatch Alarm Event
      │
      ▼
Lambda
      │
      ▼
Actionable Alarm Gate
      │
      ▼
SSM
      │
      ▼
EC2 / HTTPD Recovery
```

Important:

> **SNS is not between CloudWatch and Lambda.**

SNS is used later by Lambda for operational notification.

---

## 11. P2 — CPU Monitoring

### Alarm

```text
cpu alert
```

### Priority

```text
P2 — High
```

### Namespace

```text
AWS/EC2
```

### Metric

```text
CPUUtilization
```

### Current project threshold label

```text
> 50%
```

The alarm evaluates EC2 CPU utilization.

Conceptually:

```text
EC2 CPU
   │
   ▼
CPUUtilization
   │
   ▼
CloudWatch
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
```

---

## 12. P2 Is Diagnostic-Only

P2 does **not** automatically restart HTTPD or the EC2 instance.

The workflow is:

```text
High CPU
   │
   ▼
cpu alert
   │
   ▼
Lambda
   │
   ▼
P2 Classification
   │
   ▼
SSM Diagnostics
   │
   ▼
Operational Evidence
   │
   ▼
SNS
   │
   ▼
Engineer Review
```

Diagnostic evidence includes:

```text
uptime / load
top CPU-consuming processes
memory information
```

The design principle is:

> **Detection does not automatically mean remediation.**

High CPU is a symptom that can have multiple root causes, so P2 retains human judgment.

---

## 13. P1 vs P2

| Characteristic | P1 — HTTPD | P2 — CPU |
|---|---|---|
| Alarm | `NOC-cloudops-automate` | `cpu alert` |
| Metric source | CloudWatch Agent | Native EC2 metric |
| Metric | `procstat_lookup_pid_count` | `CPUUtilization` |
| Condition | `< 1` | `> 50%` |
| Severity | P1 — Critical | P2 — High |
| Lambda action type | Recovery | Diagnosis |
| Automatic corrective action | Yes | No |
| Human involvement | On escalation | Required for final decision |

P3 is intentionally excluded from the finalized project scope.

---

## 14. CloudWatch Alarm States

CloudWatch alarms use three main states.

### OK

The monitored condition does not currently satisfy the alarm threshold.

```text
OK
```

### ALARM

The configured alarm condition has been satisfied according to the alarm evaluation configuration.

```text
ALARM
```

### INSUFFICIENT_DATA

CloudWatch does not have enough valid datapoints to determine the alarm state.

```text
INSUFFICIENT_DATA
```

For P1, `INSUFFICIENT_DATA` can occur when the EC2 instance is stopped because the CloudWatch Agent can no longer publish new process metrics.

---

## 15. Alarm Event

When an actionable alarm changes to the required state, CloudWatch sends a direct alarm event to Lambda.

Conceptually:

```text
Metric
   │
   ▼
Alarm Evaluation
   │
   ▼
Alarm State Change
   │
   ▼
Alarm Event
   │
   ▼
Lambda
```

The event contains structured information describing the alarm.

Lambda then parses the current direct alarm format using:

```python
event["alarmData"]
```

CloudWatch generates the event.

Lambda parses and validates it.

---

## 16. CloudWatch vs Lambda Responsibility

These responsibilities must remain separate.

### CloudWatch

```text
Monitor
Evaluate
Detect
Generate Alarm Event
```

### Lambda

```text
Receive
Parse
Validate
Classify
Decide
Orchestrate
```

Therefore:

> **CloudWatch detects the incident. Lambda decides what operational workflow is allowed.**

---

## 17. CloudWatch Logs

The current CloudWatch Agent configuration collects selected EC2 log files.

### Apache Access Log

Source:

```text
/var/log/httpd/access_log
```

CloudWatch Log Group:

```text
/aws/ec2/httpd/access
```

Purpose:

> Shows client HTTP requests and HTTP response activity reaching Apache.

### Apache Error Log

Source:

```text
/var/log/httpd/error_log
```

CloudWatch Log Group:

```text
/aws/ec2/httpd/error
```

Purpose:

> Provides Apache server-side error and operational information.

### Linux Messages

Source:

```text
/var/log/messages
```

CloudWatch Log Group:

```text
/aws/ec2/messages
```

### Linux Security Log

Source:

```text
/var/log/secure
```

CloudWatch Log Group:

```text
/aws/ec2/secure
```

The configured log stream name uses:

```text
{instance_id}
```

---

## 18. Metrics vs Logs

Metrics and logs serve different purposes.

### Metrics

Answer questions such as:

> Is the monitored condition abnormal?

Examples:

```text
procstat_lookup_pid_count
CPUUtilization
mem_used_percent
disk used_percent
```

### Logs

Answer questions such as:

> What exactly happened?

Examples:

```text
HTTP requests
Apache errors
Linux system messages
Security-related messages
Lambda execution details
```

Easy distinction:

> **Metrics are strong for detection and trend monitoring. Logs are strong for investigation and diagnosis.**

---

## 19. Access Log vs Error Log

### Access Log

Answers:

> **What requests reached Apache and what response activity occurred?**

### Error Log

Answers:

> **What Apache-side problem or operational error occurred?**

This gives deeper application visibility than process count alone.

---

## 20. CloudWatch Dashboard

The project uses a centralized CloudWatch dashboard:

```text
cloudops-NOC-dashboard
```

The dashboard can provide visibility into relevant infrastructure and workload metrics such as:

- CPU utilization
- Memory utilization
- Disk utilization
- Network activity
- Apache process count

The dashboard is for **visibility**.

The alarms are for **condition evaluation and incident detection**.

---

## 21. CloudWatch Agent vs Native EC2 Monitoring

### Native EC2 Monitoring

Provides AWS infrastructure metrics such as:

```text
CPUUtilization
NetworkIn
NetworkOut
DiskReadOps
DiskWriteOps
StatusCheckFailed
```

### CloudWatch Agent

Provides additional OS/application-level visibility such as:

```text
memory utilization
disk utilization
Linux network measurements
HTTPD process count
selected log files
```

This is why the CloudWatch Agent is needed for P1.

---

## 22. Monitoring Flow vs User Traffic Flow

These are different flows.

### User Traffic Flow

```text
Browser
   │
   ▼
Internet
   │
   ▼
VPC / EC2
   │
   ▼
HTTPD
```

### Monitoring Flow

```text
HTTPD Process
      │
      ▼
CloudWatch Agent / procstat
      │
      ▼
CloudWatch
```

CloudWatch monitoring is not part of the browser request path.

---

## 23. CloudWatch and SNS

In the current V2.0 architecture, CloudWatch is **not using SNS as the Lambda trigger path**.

Correct:

```text
CloudWatch
   │
   ▼
Lambda
   │
   ▼
SNS
```

Lambda publishes incident results to SNS after processing.

SNS remains the operational notification service.

---

## 24. CloudWatch and SSM

CloudWatch does not execute Linux commands.

Correct separation:

```text
CloudWatch
= Detect

Lambda
= Decide

SSM
= Controlled Remote Execution

systemd
= Linux Service Management
```

For P1:

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
systemctl restart httpd
```

---

## 25. CloudWatch and IAM

IAM controls whether AWS identities and services are authorized to perform required AWS actions.

Examples include permissions required for:

- CloudWatch Agent publishing.
- Lambda logging.
- Lambda receiving/being invoked by the configured alarm action.
- Supporting AWS API interactions across the workflow.

The project follows the **Principle of Least Privilege**.

---

## 26. Testing P1

A controlled P1 test can stop Apache:

```bash
sudo systemctl stop httpd
```

Verify:

```bash
sudo systemctl status httpd
```

Check matching processes:

```bash
pgrep -a httpd
```

Expected monitoring behavior:

```text
HTTPD stops
   │
   ▼
Matching PID count falls
   │
   ▼
CloudWatch Agent publishes metric
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

## 27. Testing P2

A controlled CPU-load test can be used to validate the P2 alarm.

Example lab command:

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

CPU testing must be performed carefully because excessive load can affect the web server and other project components.

Expected flow:

```text
CPU increases
   │
   ▼
CPUUtilization
   │
   ▼
cpu alert
   │
   ▼
ALARM
   │
   ▼
Lambda
   │
   ▼
P2 Diagnostics
```

---

## 28. CloudWatch Verification Commands

### CloudWatch Agent status

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
```

### Apache status

```bash
sudo systemctl status httpd --no-pager
```

### HTTPD processes

```bash
pgrep -a httpd
```

### Local HTTP test

```bash
curl http://localhost
```

### CloudWatch Agent logs

```bash
sudo ls -lah /opt/aws/amazon-cloudwatch-agent/logs/
```

These checks help separate monitoring problems from application problems.

---

## 29. Troubleshooting P1

If `NOC-cloudops-automate` does not behave as expected, verify:

1. HTTPD state.
2. CloudWatch Agent state.
3. Agent configuration.
4. `procstat` pattern is configured for `httpd`.
5. The process-count metric is reaching CloudWatch.
6. Alarm threshold and evaluation settings.
7. Alarm is configured for the correct Lambda action.
8. Lambda receives the direct alarm event.
9. Lambda parsing and actionable-gate logic succeeds.
10. SSM is able to reach the managed EC2 instance.

---

## 30. Troubleshooting P2

If `cpu alert` does not behave as expected, verify:

1. The EC2 instance is publishing `AWS/EC2` `CPUUtilization`.
2. Correct instance dimension.
3. Correct Region.
4. Correct statistic.
5. Correct threshold.
6. Correct evaluation period.
7. Alarm action points to Lambda.
8. Lambda identifies `cpu alert` as P2.
9. SSM diagnostic commands run successfully.
10. SNS delivers the diagnostic notification.

---

## 31. CloudWatch Integration with the Seven Services

| Service | Relationship with CloudWatch |
|---|---|
| VPC | Provides the EC2 network environment |
| EC2 | Provides the monitored workload |
| IAM | Authorizes required AWS monitoring interactions |
| CloudWatch | Performs monitoring and alarm evaluation |
| Lambda | Receives the direct alarm event and makes the automation decision |
| Systems Manager | Performs P1 recovery and P2 diagnostics after Lambda decision |
| SNS | Delivers notifications published after incident processing |

The implemented project baseline remains exactly these seven AWS services.

---

## 32. Three-Level Interview Answer

### Level 1

> **CloudWatch is the monitoring and incident-detection layer of my project.**

### Level 2

> **For P1, the CloudWatch Agent uses procstat to publish the HTTPD process-count metric, and CloudWatch evaluates the `NOC-cloudops-automate` alarm. For P2, CloudWatch monitors the native EC2 `CPUUtilization` metric through the `cpu alert` alarm. When an actionable condition is met, CloudWatch sends the alarm event directly to Lambda.**

### Level 3

> **The CloudWatch Agent runs on EC2 with a 60-second collection interval and publishes OS-level metrics in the `CWAgent` namespace. Its procstat configuration matches the `httpd` process and collects `pid_count`, which appears as the HTTPD process-count metric used for P1. The agent also collects memory, disk, `ens5` network measurements, and selected Apache/Linux logs. CloudWatch evaluates the P1 and P2 alarms and sends direct alarm events to Lambda; Lambda, not CloudWatch, performs alarm parsing and incident classification.**

---

## 33. Operational Summary

CloudWatch can be remembered as:

```text
COLLECT / RECEIVE
       │
       ▼
     OBSERVE
       │
       ▼
    EVALUATE
       │
       ▼
     DETECT
       │
       ▼
GENERATE ALARM EVENT
```

CloudWatch does not:

- Restart HTTPD.
- Execute SSM commands.
- Decide P1 remediation logic.
- Perform P2 diagnosis.
- Act as the final notification transport.

Those responsibilities belong to Lambda, SSM, Linux/systemd, and SNS.

---

## 34. Final Summary

Amazon CloudWatch is the **central monitoring and incident-detection service** in CloudOps NOC Automation V2.0.

The two primary monitoring paths are:

```text
P1

HTTPD
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
Lambda
```

and:

```text
P2

EC2
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
Diagnostics
```

---

## Key Design Statement

> **CloudWatch detects the incident and generates the alarm event. Lambda receives that event directly, parses and validates it, and decides whether the workflow should perform P1 recovery or P2 diagnosis. SNS is used later for operational notification and is not the Lambda trigger in the current V2.0 architecture.**
