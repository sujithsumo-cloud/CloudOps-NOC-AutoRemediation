# Document 8 — Monitoring & Logging Strategy

## Project Title

**CloudOps NOC Automation V2.0**

---

## Document Information

| Item | Details |
|---|---|
| Document Name | Monitoring & Logging Strategy |
| Project | CloudOps NOC Automation |
| Version | 2.0 |
| Environment | AWS Cloud |
| Region | `ap-south-1` — Asia Pacific (Mumbai) |
| Status | Current V2.0 Baseline |

---

# 1. Purpose

This document defines the monitoring, alerting, logging, and operational-observability strategy for CloudOps NOC Automation V2.0.

The strategy is designed to:

- Monitor the EC2 workload.
- Detect the finalized P1 and P2 conditions.
- Send actionable CloudWatch Alarm events directly to Lambda.
- Support P1 automatic HTTPD recovery.
- Support P2 diagnostic-only handling.
- Preserve logs and command evidence for troubleshooting.
- Provide dashboard and alarm visibility.
- Keep monitoring, diagnosis, remediation, and notification as separate responsibilities.

The project supports exactly two incident priorities:

| Priority | Incident | Response |
|---|---|---|
| P1 | Apache HTTPD unavailable | Automatic recovery + verification + stability check |
| P2 | High EC2 CPU utilization | Diagnostic-only + engineer review |

P3 is intentionally excluded.

---

# 2. Core Monitoring Principle

The project separates:

```text
Monitoring
   ↓
Detection
   ↓
Decision
   ↓
Remediation / Diagnosis
   ↓
Verification
   ↓
Notification
```

This means:

> **Detection does not automatically mean remediation.**

P1 has a known failure and a predefined corrective action.

P2 represents an ambiguous operational symptom, so the system collects evidence instead of applying a blind restart.

---

# 3. Correct V2.0 Monitoring Architecture

```text
                         Amazon EC2
                              │
               ┌──────────────┴──────────────┐
               │                             │
               ▼                             ▼
          Apache HTTPD                  EC2 CPU
               │                             │
               ▼                             ▼
       CloudWatch Agent                CPUUtilization
               │                             │
            procstat                         │
               │                             │
               ▼                             │
 procstat_lookup_pid_count                   │
               │                             │
               └──────────────┬──────────────┘
                              ▼
                       Amazon CloudWatch
                              │
                     Metrics / Dashboard
                              │
                       Alarm Evaluation
                              │
                 ┌────────────┴────────────┐
                 ▼                         ▼
      NOC-cloudops-automate             cpu alert
                 │                         │
                 └────────────┬────────────┘
                              ▼
                     Direct Alarm Event
                              │
                              ▼
                           Lambda
                              │
                    Parse + Validate
                              │
                    Actionable Alarm Gate
                              │
                  ┌───────────┴───────────┐
                  ▼                       ▼
                 P1                      P2
                  │                       │
             Recovery                 Diagnosis
                  │                       │
                  └───────────┬───────────┘
                              ▼
                             SSM
                              │
                              ▼
                         EC2 / Linux
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

Important:

> **SNS is not between CloudWatch and Lambda.**

Correct:

```text
CloudWatch → Lambda
```

Notification:

```text
Lambda → SNS → Engineer
```

---

# 4. Monitoring Components

| Service / Component | Monitoring or Logging Responsibility |
|---|---|
| Amazon EC2 | Hosts the monitored workload |
| Apache HTTPD | P1 application/service workload |
| CloudWatch Agent | Publishes configured process/OS metrics |
| Amazon CloudWatch | Stores metrics, evaluates alarms, provides dashboards/logs |
| CloudWatch Alarm | Detects the configured P1/P2 conditions |
| AWS Lambda | Parses, validates, classifies, and orchestrates |
| AWS Systems Manager | Executes P1 commands and P2 diagnostics |
| SSM Agent | Executes SSM instructions on EC2 |
| Amazon SNS | Delivers operational notifications |
| CloudWatch Logs | Stores Lambda execution logs |
| Linux / Agent logs | Provide host-level troubleshooting evidence |

---

# 5. Metric Sources

The project uses two different metric sources.

## P1 Source

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
```

## P2 Source

```text
Amazon EC2
      │
      ▼
AWS/EC2
CPUUtilization
```

This distinction is important:

> **P1 depends on the CloudWatch Agent. P2 uses the native EC2 `CPUUtilization` metric.**

---

# 6. Canonical CloudWatch Agent Configuration

The canonical repository configuration is:

[View `cloudwatch-agent-config.json`](../CloudWatch/cloudwatch-agent-config.json)

The deployment script is:

[View `01-configure-cloudwatch-agent.sh`](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

Current canonical configuration:

```text
Namespace           : CWAgent
Collection Interval : 60 seconds
Process Match       : httpd
Process Measurement : pid_count
```

The agent also publishes configured CPU measurements for additional observability.

Important:

> The P2 `cpu alert` uses the native `AWS/EC2` `CPUUtilization` metric, not the CloudWatch Agent CPU measurements.

---

# 7. CloudWatch Agent CPU Metrics

The canonical agent configuration includes:

```text
cpu_usage_idle
cpu_usage_user
cpu_usage_system
```

These metrics provide additional operating-system visibility.

They are not the source of the current P2 alarm.

Current P2 source:

```text
AWS/EC2
CPUUtilization
```

This avoids mixing two different CPU metric sources.

---

# 8. `procstat` Monitoring

`procstat` is the CloudWatch Agent process-monitoring component.

In this project:

```text
procstat
   │
   ▼
Match httpd
   │
   ▼
Count matching PIDs
   │
   ▼
procstat_lookup_pid_count
```

`procstat` is not the same as Linux `/proc`.

```text
/proc
= Linux virtual filesystem exposing process information

procstat
= CloudWatch Agent process-monitoring component
```

---

# 9. P1 Monitoring Strategy

## Objective

Detect when the configured Apache HTTPD process is no longer present.

Current alarm:

```text
NOC-cloudops-automate
```

Metric:

```text
procstat_lookup_pid_count
```

Configured condition:

```text
< 1
```

Reference:

[View P1 alarm documentation](../CloudWatch/NOC-cloudops-automate.md)

---

# 10. P1 Normal State

```text
HTTPD Running
     │
     ▼
Matching HTTPD PIDs Present
     │
     ▼
procstat_lookup_pid_count >= 1
     │
     ▼
Alarm Condition Not Met
     │
     ▼
Alarm = OK
```

---

# 11. P1 Failure Detection

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
NOC-cloudops-automate
    │
    ▼
ALARM
```

The CloudWatch alarm is responsible for **detection**, not remediation.

---

# 12. P1 Automation Flow

```text
NOC-cloudops-automate
        │
        ▼
Direct Alarm Event
        │
        ▼
Lambda
        │
        ▼
event["alarmData"]
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
systemctl restart httpd
        │
        ▼
systemctl is-active httpd
        │
        ▼
Stability Verification
        │
        ▼
Resolved / Escalated
        │
        ▼
SNS
```

The current workflow also uses bounded retry behavior.

---

# 13. P1 Process Metric Limitation

A positive PID count means:

> Matching HTTPD processes exist.

It does **not** prove:

```text
Website fully healthy
HTTP request successful
Application response correct
Network path healthy
```

Therefore process monitoring is an availability signal, not complete application-health monitoring.

For deeper validation, commands such as:

```bash
curl http://localhost
```

and Apache logs can be used during troubleshooting.

---

# 14. P2 Monitoring Strategy

Current P2 alarm:

```text
cpu alert
```

Metric:

```text
AWS/EC2
CPUUtilization
```

Current project threshold label:

```text
> 50%
```

Reference:

[View P2 alarm documentation](../CloudWatch/cpu%20alert.md)

---

# 15. P2 Detection Flow

```text
EC2 CPU Activity
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

# 16. P2 Is Diagnostic-Only

The current P2 workflow does not perform automatic remediation.

Correct:

```text
High CPU
   │
   ▼
Detect
   │
   ▼
Diagnose
   │
   ▼
Collect Evidence
   │
   ▼
Notify Engineer
```

Not:

```text
High CPU
   │
   ▼
Automatic Restart
```

Possible high-CPU causes include:

- Legitimate traffic.
- Background processes.
- Application load.
- Resource contention.
- Unexpected process behavior.

---

# 17. P2 Diagnostic Evidence

Lambda uses Systems Manager to collect evidence using commands equivalent to:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

This provides:

| Command | Evidence |
|---|---|
| `uptime` | Uptime and load averages |
| `ps aux --sort=-%cpu | head -11` | Highest CPU-consuming processes |
| `free -h` | Memory state |

Flow:

```text
cpu alert
    │
    ▼
Lambda
    │
    ▼
SSM
    │
    ▼
Diagnostics
    │
    ▼
Result
    │
    ▼
SNS
    │
    ▼
Engineer Review
```

---

# 18. P1 vs P2 Monitoring Model

| Characteristic | P1 | P2 |
|---|---|---|
| Alarm | `NOC-cloudops-automate` | `cpu alert` |
| Metric | `procstat_lookup_pid_count` | `CPUUtilization` |
| Metric Source | CloudWatch Agent | Native EC2 |
| Response | Recovery | Diagnosis |
| Automatic Fix | Yes | No |
| SSM Usage | Restart + verify | Collect evidence |
| Human Review | On escalation | Required |

---

# 19. CloudWatch Dashboard Strategy

Current dashboard:

```text
cloudops-NOC-dashboard
```

The dashboard provides centralized visibility for:

- Normal monitoring.
- Controlled incident testing.
- Troubleshooting.
- Post-incident review.

At minimum, the current monitoring baseline can visualize:

```text
AWS/EC2 CPUUtilization
CWAgent HTTPD process count
CWAgent configured CPU metrics
```

Additional memory, disk, network, or application widgets may be added only when the corresponding metric collection is actually configured.

This avoids documenting dashboard metrics that are not currently produced by the canonical CloudWatch Agent configuration.

---

# 20. CloudWatch Alarm Strategy

The finalized project has two active incident priorities.

| Priority | Alarm | Purpose |
|---|---|---|
| P1 | `NOC-cloudops-automate` | Detect HTTPD process unavailability |
| P2 | `cpu alert` | Detect high EC2 CPU utilization |

Unknown/test alarms are not approved operational incidents.

The Lambda Actionable Alarm Gate ignores unsupported alarms.

---

# 21. Alarm States

CloudWatch alarms can enter:

```text
OK
ALARM
INSUFFICIENT_DATA
```

## OK

The alarm condition is not currently satisfied.

## ALARM

The configured threshold/evaluation condition is satisfied.

## INSUFFICIENT_DATA

CloudWatch does not have enough valid datapoints to determine the current state.

For P1, `INSUFFICIENT_DATA` can occur when the EC2 instance is stopped and the CloudWatch Agent cannot publish new process metrics.

---

# 22. Direct Alarm Event Strategy

When an approved alarm becomes actionable:

```text
CloudWatch
    │
    ▼
Alarm Event
    │
    ▼
Lambda
```

Lambda then:

```text
Receives
   ↓
Parses
   ↓
Validates
   ↓
Classifies
   ↓
Orchestrates
```

The current Lambda parser reads:

```python
event["alarmData"]
```

Reference:

[View Lambda implementation](../Lambda/lambda_function.py)

---

# 23. SNS Notification Strategy

SNS is used **after** Lambda processes the incident.

Correct:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

SNS can deliver:

```text
P1 recovery started
P1 recovery successful
P1 recovery failed
P1 escalation required
P2 diagnostics started
P2 diagnostic report
```

SNS does not deliver alarm events to Lambda in the current V2.0 architecture.

Reference:

[View SNS README](../SNS/README.md)

---

# 24. Logging Strategy Overview

Logging is maintained at multiple layers so that a failure can be isolated.

```text
Lambda Logs
SSM Run Command Results
SSM Agent Logs
CloudWatch Agent Logs
Linux Logs
Apache Logs
```

Important distinction:

> The current canonical CloudWatch Agent JSON is focused on metrics and does not currently define log-file collection.

Therefore Apache/Linux logs are treated as **local EC2 troubleshooting sources** unless log shipping is explicitly re-added to the CloudWatch Agent configuration.

---

# 25. Lambda Logs

Lambda execution logs are stored in CloudWatch Logs through the normal Lambda logging integration.

They can be used to investigate:

- Incoming alarm event.
- `event["alarmData"]` parsing.
- Alarm name/state.
- Actionable Alarm Gate result.
- P1/P2 classification.
- Incident ID generation.
- SSM command request.
- SSM Command ID.
- Command status/output.
- P1 verification.
- P1 stability result.
- P2 diagnostic result.
- SNS publish status.
- Exceptions and failures.

Repository reference:

[View Lambda README](../Lambda/README.md)

---

# 26. Systems Manager Execution Evidence

Systems Manager Run Command provides:

```text
Command ID
Target
Execution Status
Standard Output
Standard Error
```

Lambda retrieves command results using the SSM API.

This allows the workflow to distinguish:

```text
Command submitted
```

from:

```text
Command executed successfully
```

Reference:

[View SSM README](../SSM/README.md)

---

# 27. SSM Agent Logs

On EC2, SSM Agent logs are available under:

```text
/var/log/amazon/ssm/
```

These logs are useful when:

- The instance is not appearing as a managed node.
- Commands do not reach the instance.
- Agent communication fails.
- Local command execution reports unexpected errors.

Example:

```bash
sudo tail -n 50 /var/log/amazon/ssm/amazon-ssm-agent.log
```

---

# 28. CloudWatch Agent Logs

CloudWatch Agent local logs are typically under:

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

These are useful for investigating:

- Agent startup.
- Configuration parsing.
- Metric collection.
- Metric publishing.
- AWS communication errors.

Example:

```bash
sudo ls -lah /opt/aws/amazon-cloudwatch-agent/logs/
```

---

# 29. Apache Logs

Apache commonly provides:

```text
/var/log/httpd/access_log
/var/log/httpd/error_log
```

## Access Log

Helps answer:

> What requests reached Apache and what response activity occurred?

## Error Log

Helps answer:

> What Apache-side error or operational problem occurred?

These remain local troubleshooting sources in the current canonical monitoring baseline unless CloudWatch Agent log collection is explicitly configured later.

---

# 30. Linux Operating-System Logs

A common Amazon Linux system log is:

```text
/var/log/messages
```

Other logs may also be relevant depending on the problem.

Linux logs can help correlate:

```text
Service events
Agent events
Operating-system events
Network events
```

with the CloudWatch alarm timeline.

---

# 31. Metrics vs Logs

Metrics answer:

> **Is something abnormal?**

Examples:

```text
procstat_lookup_pid_count
CPUUtilization
```

Logs answer:

> **What happened and why?**

Examples:

```text
Lambda execution logs
Apache error logs
SSM Agent logs
CloudWatch Agent logs
```

Easy distinction:

```text
Metrics
= Detection / trends

Logs
= Investigation / evidence
```

---

# 32. Monitoring Troubleshooting Order

Troubleshoot from the source toward the result.

## P1

```text
HTTPD
  ↓
CloudWatch Agent
  ↓
procstat metric
  ↓
CloudWatch Alarm
  ↓
Lambda
  ↓
SSM
  ↓
HTTPD recovery
  ↓
SNS
```

## P2

```text
EC2 CPU
  ↓
CPUUtilization
  ↓
CloudWatch Alarm
  ↓
Lambda
  ↓
SSM diagnostics
  ↓
SNS
```

The first stage where expected behavior stops usually identifies the problem layer.

---

# 33. P1 Monitoring Test

A controlled P1 test can stop HTTPD.

Main command:

```bash
sudo systemctl stop httpd
```

Repository script:

[View `stop-httpd.sh`](../Scripts/Operations/stop-httpd.sh)

Expected:

```text
HTTPD stops
   ↓
PID count falls
   ↓
P1 alarm = ALARM
   ↓
Lambda invoked directly
   ↓
SSM restart
   ↓
HTTPD active
   ↓
Stability verification
   ↓
SNS result
```

Verification references:

- [Verify services](../Scripts/Verification/verify-services.sh)
- [Health check](../Scripts/Verification/health-check.sh)

---

# 34. P2 Monitoring Test

Generate a controlled CPU condition.

Example lab command:

```bash
yes > /dev/null &
```

Stop after testing:

```bash
pkill yes
```

Expected:

```text
CPU increases
   ↓
cpu alert = ALARM
   ↓
Lambda invoked directly
   ↓
P2 classified
   ↓
SSM diagnostics
   ↓
SNS report
   ↓
Engineer review
```

No automatic restart should occur.

---

# 35. Monitoring Verification Commands

## HTTPD

```bash
systemctl is-active httpd
```

## HTTPD Processes

```bash
pgrep -a httpd
```

## CloudWatch Agent

```bash
systemctl is-active amazon-cloudwatch-agent
```

## SSM Agent

```bash
systemctl is-active amazon-ssm-agent
```

## Local HTTP Test

```bash
curl http://localhost
```

## CPU / Load

```bash
uptime
top
```

---

# 36. Repository References

| Monitoring Area | Repository Reference |
|---|---|
| CloudWatch design | [CloudWatch README](../CloudWatch/README.md) |
| Canonical agent config | [CloudWatch Agent config](../CloudWatch/cloudwatch-agent-config.json) |
| Agent config deployment | [Configure agent script](../Scripts/Configuration/01-configure-cloudwatch-agent.sh) |
| P1 alarm | [P1 alarm](../CloudWatch/NOC-cloudops-automate.md) |
| P2 alarm | [P2 alarm](../CloudWatch/cpu%20alert.md) |
| Lambda logic | [Lambda source](../Lambda/lambda_function.py) |
| Lambda design | [Lambda README](../Lambda/README.md) |
| SSM design | [SSM README](../SSM/README.md) |
| SNS design | [SNS README](../SNS/README.md) |
| Deployment | [Deployment Guide](06-Deployment-Guide.md) |
| P1 test script | [Stop HTTPD](../Scripts/Operations/stop-httpd.sh) |
| Verification | [Verify services](../Scripts/Verification/verify-services.sh) |
| Diagnostics | [Diagnostics scripts](../Scripts/Diagnostics/) |

---

# 37. Monitoring Benefits

The finalized strategy provides:

- Continuous visibility into the defined project conditions.
- Dedicated P1 HTTPD process monitoring.
- Dedicated P2 CPU monitoring.
- Event-driven incident handling.
- Reduced manual intervention for P1.
- Diagnostic evidence for P2.
- Centralized Lambda execution logs.
- Systems Manager execution evidence.
- Clear separation of detection, decision, recovery, diagnosis, and notification.
- Controlled testability.
- Troubleshooting evidence across multiple layers.

---

# 38. Best Practices Implemented

The monitoring design follows these practices:

- Use CloudWatch alarms instead of continuous manual checking.
- Use a process-specific P1 metric rather than relying only on infrastructure metrics.
- Use native EC2 `CPUUtilization` for P2.
- Keep alarm names and incident classifications explicit.
- Send CloudWatch Alarm events directly to Lambda.
- Validate alarms through the Actionable Alarm Gate.
- Keep P1 remediation bounded and verified.
- Keep P2 diagnostic-only.
- Maintain logs and SSM command results for troubleshooting.
- Keep one canonical CloudWatch Agent configuration in the repository.
- Do not claim metrics or log shipping that are not actually configured.
- Exclude retired P3/unknown automation behavior.

---

# 39. Three-Level Monitoring Answer

## Level 1

> **CloudWatch is the monitoring and incident-detection layer of my project.**

## Level 2

> **For P1, the CloudWatch Agent uses procstat to publish the HTTPD process-count metric and CloudWatch evaluates `NOC-cloudops-automate`. For P2, CloudWatch monitors the native EC2 `CPUUtilization` metric through `cpu alert`. When an approved alarm becomes actionable, CloudWatch sends the alarm event directly to Lambda.**

## Level 3

> **The canonical CloudWatch Agent configuration uses a 60-second collection interval and publishes the HTTPD `pid_count` through procstat into the `CWAgent` namespace. This produces the `procstat_lookup_pid_count` signal used for P1. P2 remains independent and uses `AWS/EC2` `CPUUtilization`. Lambda parses `event["alarmData"]`, validates the alarm, and uses SSM for either P1 recovery or P2 diagnostics. Lambda execution logs and SSM command results provide the primary centralized automation evidence, while agent, Linux, and Apache logs remain available for host-level troubleshooting.**

---

# 40. Final Monitoring and Logging Summary

```text
P1 Monitoring

HTTPD
  ↓
CloudWatch Agent
  ↓
procstat
  ↓
procstat_lookup_pid_count
  ↓
NOC-cloudops-automate
  ↓
Lambda
  ↓
SSM Recovery
  ↓
Verification
  ↓
SNS
```

```text
P2 Monitoring

EC2
  ↓
CPUUtilization
  ↓
cpu alert
  ↓
Lambda
  ↓
SSM Diagnostics
  ↓
SNS
  ↓
Engineer
```

Logging/evidence:

```text
Lambda
→ CloudWatch Logs

SSM
→ Run Command status/output

SSM Agent
→ /var/log/amazon/ssm/

CloudWatch Agent
→ /opt/aws/amazon-cloudwatch-agent/logs/

Apache
→ access_log / error_log

Linux
→ /var/log/messages
```

---

## Key Design Statement

> **CloudWatch provides monitoring and detection, not remediation. P1 uses the CloudWatch Agent HTTPD procstat metric and allows controlled automatic recovery; P2 uses native EC2 CPUUtilization and remains diagnostic-only. CloudWatch sends the alarm event directly to Lambda, while SNS is used afterward for operational notification.**
