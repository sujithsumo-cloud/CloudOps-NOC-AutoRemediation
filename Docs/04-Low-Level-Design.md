# Document 4 – Low-Level Design (LLD)

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, Lambda, Amazon SNS, and AWS Systems Manager

---

# Document Information

| Item | Details |
| --- | --- |
| Document Name | Low-Level Design (LLD) |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Environment | AWS Cloud |
| Region | ap-south-1 |

---

# 1. Introduction

This Low-Level Design document describes the detailed technical implementation of the finalized CloudOps NOC Automation solution.

The implementation contains two actionable incident paths:

- **P1 – Apache HTTP Server (`httpd`) failure:** automatic recovery and stability verification.
- **P2 – EC2 CPU utilization above 50%:** diagnostic collection and manual escalation.

The Lambda function receives the CloudWatch alarm event in the direct CloudWatch alarm event format and reads the alarm information from `event["alarmData"]`.

The implementation also contains an explicit alarm-name validation mechanism. Only the approved P1 and P2 alarm names are actionable. Unknown or test alarm names are ignored without SSM execution or notification.

---

# 2. AWS Environment

| Component | Value |
| --- | --- |
| AWS Account | 257074875139 |
| Region | ap-south-1 |
| Region Name | Asia Pacific (Mumbai) |
| Operating System | Amazon Linux 2023 |
| Instance Type | t3.micro |
| Instance Name | cloudops-server |
| Instance ID | i-0b7d483631875bb1c |
| Private IP | 10.0.0.13 |
| Availability Zone | ap-south-1a |

---

# 3. Network Configuration

The EC2 instance operates inside the project VPC environment.

## 3.1 VPC

| Property | Value |
| --- | --- |
| Name | cloudops-vpc |
| CIDR Block | 10.0.0.0/16 |

---

## 3.2 Subnet

| Property | Value |
| --- | --- |
| Name | cloudops-subnet |
| CIDR Block | 10.0.0.0/28 |
| Type | Public subnet |

---

## 3.3 Internet Gateway

| Property | Value |
| --- | --- |
| Name | cloudops-igw |
| Purpose | Internet connectivity for the public subnet |

---

## 3.4 Route Table

The public subnet uses a route to the Internet Gateway.

| Destination | Target |
| --- | --- |
| 0.0.0.0/0 | cloudops-igw |

---

# 4. Security Group Configuration

## Security Group

| Property | Value |
| --- | --- |
| Name | cloudops-sg |
| Purpose | Control network access to the EC2 instance |

### Inbound Rules

| Protocol | Port | Source | Purpose |
| --- | ---: | --- | --- |
| TCP | 22 | Administrator IP | SSH administration |
| TCP | 80 | 0.0.0.0/0 | HTTP access |

### Outbound Rules

Outbound traffic is allowed according to the configured security group policy.

---

# 5. EC2 Configuration

| Property | Value |
| --- | --- |
| Instance Name | cloudops-server |
| Instance ID | i-0b7d483631875bb1c |
| AMI | Amazon Linux 2023 |
| Instance Type | t3.micro |
| Private IP | 10.0.0.13 |
| Availability Zone | ap-south-1a |
| IAM Role | cloudops-EC2-inline-role |

The EC2 instance hosts the Apache web server and provides the target environment for Systems Manager commands.

---

# 6. EC2 Software Components

The EC2 instance contains the following operational components:

- Apache HTTP Server (`httpd`)
- Amazon CloudWatch Agent
- AWS Systems Manager Agent

The Apache service is the monitored application for P1.

The operating-system metrics collected by the CloudWatch Agent support both general monitoring and the P2 CPU incident workflow.

---

# 7. IAM Configuration

## 7.1 EC2 IAM Role

| Property | Value |
| --- | --- |
| Role Name | cloudops-EC2-inline-role |
| Purpose | Provide AWS permissions required by the EC2 monitoring and management components |
| Policy Type | Custom inline policy |

The role provides the permissions required for the CloudWatch Agent and Systems Manager-related operations used by the implementation.

---

## 7.2 Lambda Execution Permissions

The Lambda function requires permissions to perform the automation workflow, including:

- Systems Manager Run Command
- Systems Manager command status retrieval
- EC2 instance information retrieval
- Amazon SNS publishing
- CloudWatch Logs

Permissions should follow the principle of least privilege.

---

# 8. CloudWatch Agent Configuration

The CloudWatch Agent is installed on the EC2 instance and publishes operating-system and process-related monitoring information.

## Metrics

The monitoring configuration includes information for:

- CPU utilization
- Memory utilization
- Disk usage
- Disk I/O
- Network traffic
- Network packets
- Apache process availability

The network interface monitored by the configuration is `ens5`.

## Collection Interval

**60 seconds**

## Apache Process Monitoring

The Apache process is monitored using process-statistics information.

The important P1 signal is the Apache process count:

```text
httpd process count
```

When the configured Apache process metric indicates that the process is unavailable, the P1 CloudWatch alarm can enter the `ALARM` state.

---

# 9. CloudWatch Dashboard

## Dashboard Name

```text
cloudops-NOC-dashboard
```

The dashboard provides operational visibility into the EC2 environment.

Typical monitoring information includes:

- CPU utilization
- Memory utilization
- Disk utilization
- Network traffic
- Apache process availability

The dashboard is used for monitoring and operational verification rather than directly performing remediation.

---

# 10. CloudWatch Alarm Configuration

The finalized implementation uses two actionable CloudWatch alarms.

---

## 10.1 P1 Alarm

| Property | Value |
| --- | --- |
| Alarm Name | `NOC-cloudops-automate` |
| Priority | P1 |
| Severity | P1 - Critical |
| Service | Apache HTTP Server (`httpd`) |
| Metric | `procstat_lookup_pid_count` |
| Condition | Apache process unavailable / count below 1 |
| Automation | Automatic Apache recovery |

### P1 Purpose

The alarm detects an Apache service/process failure and starts the P1 recovery workflow.

---

## 10.2 P2 Alarm

| Property | Value |
| --- | --- |
| Alarm Name | `cpu alert` |
| Priority | P2 |
| Severity | P2 - High |
| Service | EC2 CPU Utilization |
| Metric | `CPUUtilization` |
| Threshold | `> 50%` |
| Automation | Diagnostic-only |

### P2 Purpose

The alarm detects high CPU utilization and starts the CPU diagnostic workflow.

No automatic restart or destructive remediation is performed for P2.

---

# 11. Lambda Configuration

## Function

| Property | Value |
| --- | --- |
| Function Name | `Cloudops-NOC-automate` |
| Runtime | Python |
| Purpose | Incident detection, classification, orchestration, verification, and notification |

---

## 11.1 Environment Variables

The Lambda configuration uses:

| Variable | Purpose |
| --- | --- |
| `INSTANCE_ID` | Identifies the target EC2 instance |
| `TOPIC_ARN` | Identifies the SNS notification topic |
| `ENVIRONMENT` | Identifies the environment, defaulting to Production |
| `AWS_REGION` | Identifies the AWS Region |

Current target values include:

```text
INSTANCE_ID = i-0b7d483631875bb1c
TOPIC_ARN = arn:aws:sns:ap-south-1:257074875139:cloudops-sns
ENVIRONMENT = Production
REGION = ap-south-1
```

---

# 12. Lambda Event Parsing

The current Lambda implementation expects the direct CloudWatch alarm event structure.

The relevant alarm information is read from:

```python
event["alarmData"]
```

The Lambda extracts:

- Alarm name
- Alarm state
- Alarm reason
- Alarm timestamp

Example structure:

```json
{
  "source": "aws.cloudwatch",
  "alarmArn": "arn:aws:cloudwatch:ap-south-1:257074875139:alarm:cpu alert",
  "accountId": "257074875139",
  "time": "2026-08-11T09:00:00.000+0000",
  "region": "ap-south-1",
  "alarmData": {
    "alarmName": "cpu alert",
    "state": {
      "value": "ALARM",
      "reason": "CPU utilization exceeded 50%",
      "timestamp": "2026-08-11T09:00:00.000+0000"
    }
  }
}
```

The Lambda does not treat arbitrary test JSON as an actionable incident.

---

# 13. Alarm Classification Logic

The Lambda contains an allow-list of actionable alarm names.

| Alarm Name | Priority | Action Type |
| --- | --- | --- |
| `NOC-cloudops-automate` | P1 | Recovery |
| `cpu alert` | P2 | Diagnosis |

The classification process is:

```text
Receive CloudWatch event
        ↓
Parse alarmData
        ↓
Read alarmName
        ↓
Check state = ALARM
        ↓
Match exact alarm name
        ↓
 ┌───────────────┬─────────────────┐
 │               │                 │
P1 match       P2 match       Unknown name
 │               │                 │
 ▼               ▼                 ▼
Recovery       Diagnosis         Ignore
```

Unknown alarm names generate no incident ID, no SSM command, and no notification.

---

# 14. Incident ID Generation

For actionable incidents, Lambda generates a daily sequential incident identifier.

Format:

```text
INC-YYYYMMDD-NNNN
```

Example:

```text
INC-20260811-0012
```

The daily counter is maintained through AWS Systems Manager Parameter Store.

---

# 15. EC2 Instance Identification

For each actionable incident, Lambda retrieves the EC2 instance information and obtains the EC2 `Name` tag.

Current instance:

```text
Instance Name : cloudops-server
Instance ID   : i-0b7d483631875bb1c
```

The instance identifier is used as the target for Systems Manager Run Command.

---

# 16. Amazon SNS Configuration

## SNS Topic

| Property | Value |
| --- | --- |
| Topic Name | `cloudops-sns` |
| Display Name | `NOC-topic` |
| Region | ap-south-1 |
| Account | 257074875139 |

## Topic ARN

```text
arn:aws:sns:ap-south-1:257074875139:cloudops-sns
```

SNS is used as the notification mechanism for incident emails.

The notification template contains complete operational incident information, including the SNS topic name and ARN.

---

# 17. Incident Email Template

The notification includes:

### Incident Information

- Incident ID
- Priority
- Severity
- Environment
- Service

### Detection Information

- Detection time
- Alarm state
- Alarm reason
- Alarm name
- Alarm ARN
- Detection source
- Detection metric
- Threshold

### AWS Environment

- AWS Account ID
- AWS Region

### EC2 Information

- Instance name
- Instance ID
- Private IP
- Availability Zone

### SNS Information

- SNS Topic Name
- SNS Topic ARN

### Automation Information

- Pipeline state
- SSM Command ID
- Initial command result
- Stability check result
- Final service state
- Recovery status

### Resolution Information

- Status
- Resolution time
- Manual action

### P2 Diagnostic Information

For P2 incidents, the email also contains the diagnostic output collected from SSM.

---

# 18. P1 Implementation Details

## P1 Service

```text
Apache HTTP Server (httpd)
```

## Recovery Command

```bash
systemctl restart httpd
```

## Verification Command

```bash
systemctl is-active httpd
```

---

## P1 Execution Sequence

```text
P1 ALARM
   ↓
Create incident
   ↓
Send initial notification
   ↓
SSM restart command
   ↓
Check httpd status
   ↓
Wait 15 seconds
   ↓
Run stability verification
   ↓
 ┌───────────────┬─────────────────┐
 │               │                 │
Active          Not active
 │               │
 ▼               ▼
RESOLVED       ESCALATED
```

The recovery is considered successful only when Apache is confirmed active after the stability verification.

---

# 19. P2 Implementation Details

## P2 Service

```text
EC2 CPU Utilization
```

## Threshold

```text
> 50%
```

## Diagnostic Commands

The P2 workflow collects:

```bash
uptime
```

```bash
ps aux --sort=-%cpu | head -11
```

```bash
free -h
```

The commands provide:

- System uptime and load average.
- Top CPU-consuming processes.
- Memory utilization information.

---

# 20. P2 Execution Sequence

```text
P2 ALARM
   ↓
Create incident
   ↓
Send initial notification
   ↓
SSM diagnostic command
   ↓
Collect CPU / load / memory information
   ↓
Create diagnostic report
   ↓
Send SNS notification
   ↓
Manual review / escalation
```

P2 does not execute:

```text
systemctl restart
```

and does not perform automatic corrective actions.

---

# 21. Systems Manager Configuration

Systems Manager Run Command is used to execute commands on the EC2 instance.

## Target

```text
cloudops-server
```

## Target Instance

```text
i-0b7d483631875bb1c
```

## Document

```text
AWS-RunShellScript
```

The Lambda waits for the command to reach a terminal state.

Relevant terminal states include:

- Success
- Failed
- TimedOut
- Cancelled

---

# 22. SSM Command Tracking

Each execution generates an SSM Command ID.

Example P2 command:

```text
ee9d85ea-8b61-41de-9ece-ef6e0f417a56
```

Example P1 recovery command:

```text
03c29488-e0e6-4145-9e6c-2891fbbe6613
```

The command ID and execution result are included in the incident email for traceability.

---

# 23. Logging

The solution uses AWS and operating-system logs for troubleshooting.

## Lambda Logs

Lambda execution logs provide information about:

- Event parsing
- Alarm classification
- Incident ID
- EC2 identification
- SSM command ID
- SSM execution status
- Recovery verification
- Notification delivery

## CloudWatch Agent Logs

The CloudWatch Agent logs are available under:

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

## Systems Manager Logs

SSM Agent logs are available under:

```text
/var/log/amazon/ssm/
```

System-level logs may also be reviewed during troubleshooting.

---

# 24. Error Handling

## 24.1 Invalid CloudWatch Event

If the expected alarm data is missing, Lambda stops processing the event and does not perform remediation.

---

## 24.2 Unknown Alarm

If the alarm name is not one of the approved P1/P2 alarms:

```text
No incident ID
No SSM command
No SNS notification
```

---

## 24.3 P1 Recovery Failure

If Apache is not confirmed active:

```text
Recovery Failed
       ↓
Incident Escalated
       ↓
Manual Investigation Required
```

---

## 24.4 P2 Diagnostic Failure

If no diagnostic output is captured, the final notification states that diagnostic output was unavailable and directs the operator to review SSM Run Command history.

---

## 24.5 SSM Failure

If Systems Manager cannot execute the command successfully, the incident is treated as unsuccessful and requires operational review.

---

# 25. Performance Considerations

The current implementation uses:

| Item | Configuration |
| --- | --- |
| CloudWatch Agent collection interval | 60 seconds |
| P1 stability wait | 15 seconds |
| SSM polling interval | Approximately 3 seconds |
| Lambda memory | 128 MB |
| Lambda runtime | Python |
| P1 recovery verification | Initial check + stability check |

Actual incident duration depends on CloudWatch detection, Lambda execution, SSM command execution, and service recovery time.

---

# 26. Security Considerations

The implementation follows basic AWS security practices:

- IAM roles are used instead of hardcoded AWS access keys.
- Systems Manager is used for automated remote command execution.
- IAM permissions are restricted to required AWS operations.
- CloudWatch Logs provide execution visibility.
- SNS provides controlled notification delivery.
- SSH is not required for automated remediation.
- AWS service communication uses AWS-managed secure channels.

---

# 27. Operational Test Cases

The finalized implementation was tested using the following scenarios.

## Test 1 – Unknown Alarm

Alarm name:

```text
Parser-Test
```

Expected behavior:

```text
Parse event
    ↓
Unknown alarm
    ↓
Ignore
    ↓
No SSM
No SNS
No incident
```

This test confirmed the alarm validation control.

---

## Test 2 – P1 Apache Recovery

Alarm:

```text
NOC-cloudops-automate
```

Expected behavior:

```text
P1 detected
    ↓
Incident created
    ↓
Initial email
    ↓
Restart httpd
    ↓
Verify active
    ↓
15-second stability verification
    ↓
Resolved email
```

Verified result:

```text
Incident ID: INC-20260811-0011
SSM recovery: Success
Stability check: Success
Final status: Resolved
```

---

## Test 3 – P2 CPU Diagnosis

Alarm:

```text
cpu alert
```

Threshold:

```text
> 50%
```

Expected behavior:

```text
P2 detected
    ↓
Incident created
    ↓
Initial email
    ↓
Collect diagnostics
    ↓
Diagnostic report
    ↓
Escalation / manual review
```

Verified result:

```text
Incident ID: INC-20260811-0012
SSM diagnostic command: Success
Diagnostic output: Captured
Automatic CPU remediation: Not performed
Final status: Manual review required
```

---

# 28. Technical Resource Summary

| Resource | Name / Value | Role |
| --- | --- | --- |
| VPC | `cloudops-vpc` | Network |
| Subnet | `cloudops-subnet` | EC2 network |
| Internet Gateway | `cloudops-igw` | Internet connectivity |
| Security Group | `cloudops-sg` | Network security |
| EC2 | `cloudops-server` | Application host |
| Instance ID | `i-0b7d483631875bb1c` | Automation target |
| EC2 IAM Role | `cloudops-EC2-inline-role` | EC2 AWS permissions |
| Dashboard | `cloudops-NOC-dashboard` | Monitoring |
| P1 Alarm | `NOC-cloudops-automate` | Apache recovery |
| P2 Alarm | `cpu alert` | CPU diagnosis |
| SNS Topic | `cloudops-sns` | Notification |
| SNS Display Name | `NOC-topic` | Email sender/display identity |
| Lambda | `Cloudops-NOC-automate` | Automation engine |
| SSM Document | `AWS-RunShellScript` | Command execution |

---

# 29. Technical Summary

| Component | Technical Responsibility |
| --- | --- |
| EC2 | Hosts Apache and monitoring agents |
| CloudWatch Agent | Collects system and process metrics |
| CloudWatch | Stores metrics and evaluates alarms |
| CloudWatch Alarm | Detects P1/P2 conditions |
| Lambda | Parses, validates, classifies, and orchestrates incidents |
| Systems Manager | Executes recovery or diagnostic commands |
| SNS | Sends detailed incident notifications |
| IAM | Controls AWS permissions |
| CloudWatch Logs | Stores Lambda execution information |

---

# 30. Conclusion

The Low-Level Design defines the actual technical implementation of the CloudOps NOC Automation solution.

The finalized implementation contains two controlled automation paths:

- **P1:** Apache HTTP Server recovery with service and stability verification.
- **P2:** CPU utilization diagnosis for utilization above 50%, followed by manual review.

The Lambda function acts as the central control point. It validates the incoming CloudWatch alarm, permits only approved alarm names, generates incident information, executes the appropriate Systems Manager workflow, and sends detailed SNS notifications.

The design also provides traceability through incident IDs, SSM Command IDs, alarm information, EC2 information, SNS information, execution results, and diagnostic output.

This controlled design provides a clear technical foundation for deployment, testing, troubleshooting, maintenance, and future expansion while preserving the finalized P1/P2 project scope.
