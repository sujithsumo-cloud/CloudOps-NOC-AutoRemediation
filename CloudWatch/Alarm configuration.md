# CloudWatch Alarms Configuration

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda, and AWS Systems Manager

---

# 1. Document Information

| Item | Details |
|---|---|
| Document Name | CloudWatch Alarms Configuration |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Region | ap-south-1 |
| Severity Levels | P1 – Critical, P2 – High |

---

# 2. Overview

Amazon CloudWatch Alarms are used to continuously evaluate infrastructure and application metrics and identify conditions that require operational action.

This project implements **two severity levels only**:

- **P1 – Critical:** Apache HTTPD service failure
- **P2 – High:** High CPU utilization

The P1 alarm is connected to the automated remediation workflow. When Apache stops, CloudWatch detects that the HTTPD process count has reached zero and initiates the SNS → Lambda → Systems Manager workflow.

The P2 alarm monitors CPU utilization and generates an operational notification when the configured CPU threshold is exceeded.

---

# 3. Alarm Architecture

```text
                         Amazon EC2
                       cloudops-server
                             │
              ┌──────────────┴──────────────┐
              │                             │
        HTTPD Process                 CPU Utilization
              │                             │
              ▼                             ▼
       CloudWatch Agent              AWS/EC2 Metrics
              │                             │
              ▼                             ▼
       P1 HTTPD Alarm                 P2 CPU Alarm
              │                             │
              └──────────────┬──────────────┘
                             │
                             ▼
                         Amazon SNS
                             │
                    ┌────────┴────────┐
                    │                 │
                  Email            Lambda
                                      │
                                      ▼
                              AWS Systems Manager
                                      │
                                      ▼
                              Restart Apache
```

---

# 4. Severity Model

| Severity | Condition | Purpose | Automation |
|---|---|---|---|
| **P1 – Critical** | Apache/httpd process count = 0 | Detect complete Apache service failure | Automatic remediation |
| **P2 – High** | CPU utilization exceeds configured threshold | Detect high CPU usage | Notification/monitoring |

Only **P1 and P2** are implemented in this project.

---

# 5. P1 – Critical HTTPD Alarm

## 5.1 Alarm Information

| Property | Configuration |
|---|---|
| Severity | **P1 – Critical** |
| Alarm Name | `NOC-cloudops-automate` |
| Metric | HTTPD Process Count |
| Namespace | `CWAgent` |
| Process | `httpd` |
| Evaluation Period | 60 seconds |
| Condition | Process Count = 0 |
| State | ALARM |
| Action | Publish notification to SNS |
| SNS Topic | `cloudops-sns` |
| Remediation | Lambda → SSM → Restart HTTPD |

---

## 5.2 Purpose

The P1 alarm detects a complete Apache HTTPD service failure.

The CloudWatch Agent monitors the `httpd` process on the EC2 instance.

When the HTTPD process count becomes zero, the alarm changes from `OK` to `ALARM`.

This represents a **critical service availability incident**.

---

## 5.3 Detection Logic

```text
HTTPD Running
     │
     ▼
Process Count > 0
     │
     ▼
CloudWatch Alarm = OK
```

When Apache stops:

```text
HTTPD Stops
     │
     ▼
Process Count = 0
     │
     ▼
CloudWatch Alarm
     │
     ▼
P1 - CRITICAL
     │
     ▼
ALARM State
```

---

# 6. P1 Automatic Remediation Workflow

Once the P1 alarm enters the `ALARM` state:

```text
Apache HTTPD Stops
        │
        ▼
CloudWatch Agent
        │
        ▼
HTTPD Process Count = 0
        │
        ▼
NOC-cloudops-automate
        │
        ▼
SNS Topic
cloudops-sns
        │
        ├──────────────► NOC Engineer Email
        │
        ▼
Lambda
Cloudops-NOC-automate
        │
        ▼
SSM Run Command
        │
        ▼
systemctl restart httpd
        │
        ▼
HTTPD Running
        │
        ▼
CloudWatch Detects Recovery
        │
        ▼
Alarm Returns to OK
```

---

# 7. P1 Recovery Verification

After Lambda invokes Systems Manager, the automation verifies whether Apache has recovered.

Expected result:

```text
systemctl is-active httpd
```

Expected output:

```text
active
```

The incident is considered automatically recovered when:

- HTTPD is active.
- HTTPD process count becomes greater than zero.
- CloudWatch receives the updated metric.
- The P1 alarm returns to `OK`.

---

# 8. P2 – High CPU Alarm

## 8.1 Alarm Information

| Property | Configuration |
|---|---|
| Severity | **P2 – High** |
| Alarm Name | `cloudops-cpuutilization` |
| Metric | CPU Utilization |
| Namespace | `AWS/EC2` |
| Instance | `cloudops-server` |
| Evaluation Period | 60 seconds |
| Condition | Configured CPU threshold exceeded |
| State | ALARM |
| Action | SNS notification |
| Purpose | High CPU monitoring |

---

# 9. P2 Purpose

The P2 alarm monitors excessive CPU utilization on the EC2 instance.

High CPU usage can indicate:

- Increased application workload
- Resource-intensive processes
- Abnormal system activity
- Performance degradation

The P2 alarm provides an early warning so that the NOC engineer can investigate the server before the condition becomes a service-impacting incident.

---

# 10. P2 Detection Logic

Normal condition:

```text
CPU Utilization
       │
       ▼
Below Configured Threshold
       │
       ▼
Alarm = OK
```

High CPU condition:

```text
CPU Utilization
       │
       ▼
Threshold Exceeded
       │
       ▼
P2 - HIGH
       │
       ▼
Alarm = ALARM
       │
       ▼
SNS Notification
       │
       ▼
NOC Engineer
```

---

# 11. P1 vs P2

| Feature | P1 – Critical | P2 – High |
|---|---|---|
| Incident | Apache failure | High CPU |
| Metric | HTTPD Process Count | CPU Utilization |
| Namespace | CWAgent | AWS/EC2 |
| Condition | Process Count = 0 | CPU threshold exceeded |
| Alarm | `NOC-cloudops-automate` | `cloudops-cpuutilization` |
| Notification | SNS | SNS |
| Lambda | Yes | Monitoring/notification workflow |
| SSM | Yes | Not required |
| Automatic Apache Restart | Yes | No |
| Operational Priority | Critical | High |

---

# 12. Alarm State Model

CloudWatch alarms use three primary states:

```text
              ┌─────────────┐
              │     OK      │
              └──────┬──────┘
                     │
              Threshold Breach
                     │
                     ▼
              ┌─────────────┐
              │    ALARM    │
              └──────┬──────┘
                     │
              Condition Recovered
                     │
                     ▼
              ┌─────────────┐
              │     OK      │
              └─────────────┘
```

The `INSUFFICIENT_DATA` state may occur when CloudWatch does not have enough valid metric data to evaluate the alarm.

---

# 13. SNS Integration

Both alarms use Amazon SNS for operational notification.

SNS Topic:

```text
cloudops-sns
```

The P1 workflow additionally uses SNS to invoke the Lambda remediation function.

```text
CloudWatch Alarm
       │
       ▼
   cloudops-sns
       │
       ├──────────► Email
       │
       └──────────► Lambda
```

---

# 14. Alarm Testing

## P1 Test

Stop Apache manually:

```bash
sudo systemctl stop httpd
```

Verify:

```bash
sudo systemctl status httpd
```

Expected:

```text
inactive
```

Then verify the CloudWatch alarm changes to:

```text
ALARM
```

Expected automation:

```text
CloudWatch
   ↓
SNS
   ↓
Lambda
   ↓
SSM
   ↓
restart httpd
```

Verify recovery:

```bash
sudo systemctl status httpd
```

Expected:

```text
active
```

---

# 15. P2 Test

Generate controlled CPU load on the EC2 instance and monitor the CPU metric.

The alarm should enter:

```text
ALARM
```

when the configured CPU threshold is exceeded.

After CPU utilization returns below the configured threshold, the alarm should return to:

```text
OK
```

Testing should be performed carefully to avoid unnecessary resource consumption.

---

# 16. Alarm Verification Checklist

| Verification | P1 | P2 |
|---|---|---|
| Alarm exists | ✓ | ✓ |
| Correct metric configured | ✓ | ✓ |
| Correct EC2 instance monitored | ✓ | ✓ |
| Threshold configured | ✓ | ✓ |
| SNS action configured | ✓ | ✓ |
| Alarm enters ALARM during test | ✓ | ✓ |
| Notification received | ✓ | ✓ |
| Automatic remediation | ✓ | — |
| SSM command executed | ✓ | — |
| Apache recovery verified | ✓ | — |
| Alarm returns to OK | ✓ | ✓ |

---

# 17. Troubleshooting

## P1 Alarm Does Not Trigger

Check:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

Verify the HTTPD process:

```bash
pgrep httpd
```

Check CloudWatch Agent logs:

```bash
sudo journalctl -u amazon-cloudwatch-agent -n 50 --no-pager
```

Verify that the `httpd` process metric is being published.

---

## P1 Alarm Triggers but Lambda Does Not Execute

Check:

- SNS topic configuration
- Lambda SNS subscription
- Lambda execution logs
- Lambda execution role
- SNS-to-Lambda permission
- Lambda function configuration

---

## Lambda Executes but Apache Does Not Restart

Check:

- Lambda IAM permissions
- Systems Manager managed-node status
- SSM Agent status
- SSM Run Command execution
- EC2 IAM role

Verify SSM Agent:

```bash
sudo systemctl status amazon-ssm-agent
```

---

## P2 Alarm Does Not Trigger

Check:

- EC2 CPU metric
- Alarm threshold
- Evaluation period
- Alarm state
- SNS action
- CloudWatch metric availability

---

# 18. Best Practices

- Use meaningful alarm names.
- Configure thresholds based on actual workload.
- Avoid unnecessary alarms.
- Test alarm actions regularly.
- Use SNS for centralized notification.
- Use least-privilege IAM permissions.
- Monitor alarm state changes.
- Document remediation procedures.
- Keep P1 remediation automatic and P2 monitoring focused on early detection.

---

# 19. Repository Placement

```text
cloudops-noc-automation/
│
├── cloudwatch/
│   ├── dashboard.json
│   ├── alarms/
│   │   ├── httpd-alarm.md
│   │   └── cpu-alarm.md
│   └── README.md
```

---

# 20. Conclusion

CloudWatch Alarms form the incident-detection layer of the CloudOps NOC Automation project.

The project implements two operational severity levels:

**P1 – Critical**

Apache HTTPD failure is detected through the HTTPD process metric. The alarm triggers SNS, Lambda, and Systems Manager to automatically restart Apache and verify recovery.

**P2 – High**

CPU utilization is continuously monitored to identify high resource usage and notify the NOC engineer when the configured threshold is exceeded.

This two-level alarm strategy keeps the project focused on the most important operational scenarios while demonstrating automated incident detection, notification, remediation, and recovery using AWS native services.
```
