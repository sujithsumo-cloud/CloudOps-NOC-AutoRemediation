# Amazon CloudWatch Configuration

## Overview

Amazon CloudWatch is the central monitoring and alerting service used in the CloudOps NOC Automation project.

CloudWatch receives infrastructure and operating-system metrics from the Amazon EC2 instance, displays them through dashboards, evaluates configured alarm conditions, and initiates the appropriate notification and automation workflow.

The project uses CloudWatch for two operational severities:

- **P1 – HTTPD Service Failure:** Detects when the Apache (`httpd`) process is unavailable and initiates automatic service recovery.
- **P2 – High CPU Utilization:** Detects excessive CPU utilization and generates an operational notification for investigation.

CloudWatch therefore acts as the primary monitoring and incident-detection layer of the NOC solution.

---

# 1. Purpose

Amazon CloudWatch is used to:

- Monitor Amazon EC2 infrastructure health.
- Monitor Apache HTTP Server availability.
- Monitor CPU utilization.
- Collect operating-system metrics through the CloudWatch Agent.
- Display infrastructure health through a dashboard.
- Detect abnormal conditions using CloudWatch Alarms.
- Publish alarm notifications to Amazon SNS.
- Initiate automated P1 remediation through the existing Lambda and SSM workflow.
- Provide monitoring history for troubleshooting and incident analysis.

---

# 2. CloudWatch Role in the Project

CloudWatch is positioned between the monitored EC2 infrastructure and the event-driven automation layer.

```text
                    Amazon EC2
                 cloudops-server
                       │
                       ▼
              CloudWatch Agent
                       │
                       ▼
              Amazon CloudWatch
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
        Dashboard          CloudWatch Alarms
                                 │
                         ┌───────┴────────┐
                         │                │
                         ▼                ▼
                   P1 HTTPD          P2 CPU
                    Failure          High Usage
                         │                │
                         ▼                ▼
                        SNS            SNS
                         │
                         ▼
                       Lambda
                         │
                         ▼
                  Systems Manager
                         │
                         ▼
                Restart Apache
```

---

# 3. CloudWatch Components Used

| Component | Project Usage |
|---|---|
| CloudWatch Metrics | Stores and evaluates monitoring data |
| CloudWatch Agent | Collects OS-level metrics from EC2 |
| CloudWatch Dashboard | Provides centralized monitoring visibility |
| CloudWatch Alarms | Detects P1 and P2 conditions |
| CloudWatch Logs | Stores Lambda and operational logs |
| Amazon SNS | Receives alarm notifications |

---

# 4. CloudWatch Resources

## Dashboard

**Dashboard Name**

```text
cloudops-NOC-dashboard
```

The dashboard provides a centralized view of the EC2 instance.

### Dashboard Monitoring

- CPU Utilization
- Memory Utilization
- Disk Utilization
- Network Traffic
- Apache Process Count

---

# 5. CloudWatch Alarms

The project intentionally uses **two severities only**.

## P1 – HTTPD Automation

**Current Alarm**

```text
NOC-cloudops-automate
```

### Purpose

Detect Apache HTTP Server failure and initiate automatic recovery.

### Monitoring Condition

The Apache process count becomes zero.

```text
httpd process count = 0
```

### Workflow

```text
Apache Process Failure
        ↓
CloudWatch Alarm
        ↓
ALARM State
        ↓
Amazon SNS
        ↓
AWS Lambda
        ↓
AWS Systems Manager
        ↓
systemctl restart httpd
        ↓
Apache Recovery
```

P1 is the primary automated remediation workflow in this project.

---

# 6. P2 – CPU Utilization Monitoring

**Alarm**

```text
cloudops-cpuutilization
```

### Purpose

Monitor excessive CPU utilization on the EC2 instance.

### Metric

```text
CPUUtilization
```

### Threshold

The alarm uses the configured CPU utilization threshold for the project environment.

Example:

```text
CPU Utilization >= 80%
```

### Workflow

```text
High CPU Utilization
        ↓
CloudWatch Alarm
        ↓
ALARM State
        ↓
Amazon SNS
        ↓
NOC Notification
        ↓
Engineer Investigation
```

P2 is used for CPU monitoring and alerting. It is separate from the P1 HTTPD service-recovery workflow.

---

# 7. CloudWatch Agent

The CloudWatch Agent runs on the Amazon EC2 instance and collects operating-system-level metrics that are not available through standard EC2 monitoring alone.

### Configuration File

```text
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_file_amazon-cloudwatch-agent.json
```

### Collection Interval

```text
60 seconds
```

### Namespace

```text
CWAgent
```

---

# 8. Metrics Collected

## CPU Metrics

The project monitors CPU-related information to identify resource utilization and performance issues.

Examples:

- CPU utilization
- CPU user time
- CPU system time
- CPU idle time

---

## Memory Metrics

The CloudWatch Agent provides operating-system memory information.

Examples:

- Memory used
- Memory available
- Memory utilization

---

## Disk Metrics

The project monitors storage utilization and disk activity.

Examples:

- Disk usage
- Disk free space
- Disk I/O
- Read operations
- Write operations

---

## Network Metrics

The EC2 network interface monitored by the CloudWatch Agent is:

```text
ens5
```

Examples:

- Network bytes received
- Network bytes sent
- Network packets received
- Network packets sent

---

## Apache Process Monitoring

Apache is monitored through the Linux process:

```text
httpd
```

The process count is used to determine whether the Apache service is running.

### Normal Condition

```text
httpd process count > 0
```

### Failure Condition

```text
httpd process count = 0
```

When the failure condition persists according to the configured alarm evaluation, the P1 alarm enters the `ALARM` state.

---

# 9. Default EC2 Metrics

Amazon CloudWatch also receives standard EC2 metrics without requiring the CloudWatch Agent.

Examples include:

- CPUUtilization
- NetworkIn
- NetworkOut
- DiskReadOps
- DiskWriteOps
- StatusCheckFailed

These metrics provide basic EC2 infrastructure visibility.

---

# 10. CloudWatch Alarm State

CloudWatch alarms use states to represent the monitored condition.

### OK

The monitored condition is normal.

```text
OK
```

### ALARM

The configured threshold or failure condition has been reached.

```text
ALARM
```

### INSUFFICIENT_DATA

CloudWatch does not have enough valid monitoring data to determine the alarm state.

```text
INSUFFICIENT_DATA
```

---

# 11. Alarm-to-SNS Integration

When an alarm enters the `ALARM` state, CloudWatch publishes a notification to the configured Amazon SNS topic.

### SNS Topic

```text
cloudops-sns
```

### Display Name

```text
NOC-topic
```

The SNS topic distributes the event to the configured subscribers.

For P1, the event can initiate the Lambda remediation workflow.

For P2, the event provides the required operational notification.

---

# 12. P1 Automated Remediation Workflow

The P1 workflow is the main self-healing workflow implemented in the project.

```text
1. Apache httpd stops
        ↓
2. CloudWatch Agent detects process failure
        ↓
3. CloudWatch evaluates the metric
        ↓
4. NOC-cloudops-automate enters ALARM
        ↓
5. CloudWatch publishes to SNS
        ↓
6. SNS invokes Lambda
        ↓
7. Lambda validates the alarm event
        ↓
8. Lambda calls SSM Run Command
        ↓
9. SSM executes:
   systemctl restart httpd
        ↓
10. Lambda checks execution result
        ↓
11. Apache becomes active
        ↓
12. CloudWatch detects recovery
        ↓
13. Alarm returns to OK
        ↓
14. Recovery notification is sent
```

---

# 13. P2 Monitoring Workflow

The P2 workflow focuses on CPU utilization monitoring.

```text
EC2 CPU Utilization
        ↓
CloudWatch Metric
        ↓
CPU Alarm Evaluation
        ↓
Threshold Exceeded
        ↓
cloudops-cpuutilization
        ↓
ALARM State
        ↓
SNS Notification
        ↓
NOC Engineer Investigation
```

P2 does not replace or modify the P1 HTTPD remediation workflow.

---

# 14. CloudWatch Logs

CloudWatch Logs provides visibility into AWS service operations and automation execution.

The project uses CloudWatch Logs primarily for:

- Lambda execution logs
- Automation troubleshooting
- Error investigation
- Operational auditing

Lambda logs can be used to identify:

- Received SNS event
- Target EC2 instance
- SSM command execution
- SSM response
- Apache restart result
- Success or failure conditions

---

# 15. CloudWatch Integration with Other Project Services

CloudWatch works with the other six project services as follows:

| Service | Integration |
|---|---|
| IAM | Provides permissions for monitoring and service access |
| EC2 | Provides the infrastructure being monitored |
| VPC | Provides the network environment |
| SNS | Receives CloudWatch alarm notifications |
| Lambda | Performs P1 automation |
| Systems Manager | Executes the Apache restart command |

The complete implemented AWS service baseline is:

```text
IAM
EC2
VPC
CloudWatch
SNS
Systems Manager
Lambda
```

---

# 16. CloudWatch Configuration Verification

### Check CloudWatch Agent

```bash
sudo systemctl status amazon-cloudwatch-agent
```

### Check Agent Configuration

```bash
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_file_amazon-cloudwatch-agent.json
```

### Check Agent Logs

```bash
sudo ls -lah /opt/aws/amazon-cloudwatch-agent/logs/
```

### Check Apache Process

```bash
pgrep -a httpd
```

### Check Apache Service

```bash
sudo systemctl status httpd
```

---

# 17. Testing P1 HTTPD Monitoring

The P1 workflow can be tested by stopping Apache.

```bash
sudo systemctl stop httpd
```

Verify:

```bash
sudo systemctl status httpd
```

Verify the process:

```bash
pgrep -a httpd
```

The process count should become zero.

CloudWatch should subsequently detect the condition and move:

```text
NOC-cloudops-automate
```

to:

```text
ALARM
```

The SNS → Lambda → SSM workflow should then execute the remediation.

---

# 18. Testing Apache Recovery

After the automation workflow executes, verify:

```bash
sudo systemctl status httpd
```

Verify the process:

```bash
pgrep -a httpd
```

Expected result:

```text
httpd process is running
```

CloudWatch should eventually detect the recovered state and the P1 alarm should return to:

```text
OK
```

---

# 19. Testing P2 CPU Monitoring

Generate controlled CPU activity only when performing a test in the lab environment.

Example Linux command:

```bash
yes > /dev/null &
```

Check the process:

```bash
ps aux | grep yes
```

After testing, terminate the process:

```bash
pkill yes
```

The purpose of the test is to verify:

```text
CPU Increase
     ↓
CloudWatch Metric
     ↓
P2 Alarm
     ↓
SNS Notification
```

Do not use uncontrolled CPU generation on a production system.

---

# 20. Troubleshooting

## Metrics Not Appearing

Check:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

Then inspect:

```bash
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

Verify that the EC2 IAM role has the required CloudWatch permissions.

---

## P1 Alarm Not Triggering

Check:

1. Apache process count.
2. CloudWatch Agent status.
3. CloudWatch metric namespace.
4. Metric dimensions.
5. Alarm threshold.
6. Alarm evaluation period.
7. SNS action.
8. Lambda trigger.

---

## P2 Alarm Not Triggering

Check:

1. `CPUUtilization` metric.
2. EC2 instance dimension.
3. Alarm threshold.
4. Evaluation period.
5. Alarm actions.
6. SNS topic configuration.

---

## Lambda Not Invoked

Check:

1. SNS subscription.
2. Lambda SNS trigger.
3. Lambda execution role.
4. SNS topic configuration.
5. CloudWatch alarm action.

---

# 21. Best Practices

- Use meaningful alarm names.
- Keep P1 and P2 conditions clearly separated.
- Use appropriate evaluation periods to reduce false alarms.
- Monitor both infrastructure and operating-system metrics.
- Use IAM roles instead of static AWS credentials.
- Keep CloudWatch Agent configuration under version control.
- Review alarm actions regularly.
- Test the P1 remediation workflow periodically.
- Avoid unnecessary custom metrics.
- Monitor CloudWatch costs when using high-cardinality or high-frequency metrics.
- Retain only the logs required for operational and troubleshooting purposes.

---

# 22. Project Role Summary

Amazon CloudWatch is the **monitoring and detection engine** of the CloudOps NOC Automation project.

Its responsibilities are:

```text
Collect
   ↓
Store
   ↓
Visualize
   ↓
Evaluate
   ↓
Detect
   ↓
Notify
```

For the two implemented severities:

```text
P1 → HTTPD Failure → SNS → Lambda → SSM → Apache Restart

P2 → High CPU      → SNS → NOC Notification
```

---

# 23. Final Summary

Amazon CloudWatch provides the monitoring foundation for the CloudOps NOC Automation solution.

The CloudWatch Agent collects operating-system and Apache process metrics from the EC2 instance. CloudWatch stores and evaluates these metrics, provides operational dashboards, and triggers alarms when abnormal conditions are detected.

The project intentionally maintains two operational severities:

- **P1 – HTTPD service failure with automatic remediation**
- **P2 – CPU utilization monitoring and alerting**

The P1 workflow integrates CloudWatch with SNS, Lambda, and Systems Manager to automatically restart the Apache service and verify recovery.

This architecture demonstrates a practical NOC monitoring and auto-remediation workflow using AWS-native services while maintaining a clear separation between critical automated incidents and performance-related operational alerts.
