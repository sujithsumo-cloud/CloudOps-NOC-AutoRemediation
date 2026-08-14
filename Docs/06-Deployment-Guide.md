# Document 6 – Deployment Guide (SOP)

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, Amazon SNS, AWS Lambda, and AWS Systems Manager

---

# Document Information

| Item | Details |
|---|---|
| Document Name | Deployment Guide (SOP) |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Environment | AWS Cloud |
| Region | ap-south-1 (Mumbai) |

---

# 1. Purpose

This Standard Operating Procedure (SOP) describes the deployment and configuration process for the CloudOps NOC Automation solution.

The solution uses AWS managed services to monitor an Amazon EC2 instance, detect operational incidents, perform automated remediation for critical Apache service failures, and perform diagnostic collection for high CPU incidents.

The deployment process is designed to provide a repeatable implementation sequence and a clear operational baseline for the project.

---

# 2. Scope

This SOP covers the deployment and configuration of:

- Amazon VPC
- Public Subnet
- Internet Gateway
- Route Table
- Security Group
- Amazon EC2
- Apache HTTP Server (`httpd`)
- IAM Role and permissions
- Amazon CloudWatch Agent
- Amazon CloudWatch Metrics
- CloudWatch Dashboard
- CloudWatch Alarms
- Amazon SNS
- AWS Lambda
- AWS Systems Manager (SSM)
- Incident detection and notification workflow
- P1 Apache auto-remediation workflow
- P2 CPU diagnostic workflow

The finalized NOC automation scope contains two severities:

- **P1 – Critical:** Apache HTTP Server failure
- **P2 – High:** CPU utilization above 50%

P3 / Unknown Service handling is not part of the finalized deployment scope.

---

# 3. Prerequisites

Before deployment, the following requirements should be available.

## 3.1 AWS Account

An active AWS account with sufficient permissions to create and configure the required resources.

## 3.2 AWS Region

The project is deployed in:

**ap-south-1 – Asia Pacific (Mumbai)**

## 3.3 Operating System

The EC2 instance uses:

**Amazon Linux 2023**

## 3.4 Required Access

The deployment operator must have sufficient permissions to configure:

- VPC resources
- EC2
- IAM
- CloudWatch
- SNS
- Lambda
- Systems Manager

## 3.5 Notification

An email address must be available for the Amazon SNS subscription, and the subscription must be confirmed.

---

# 4. Deployment Sequence

The deployment should be completed in the following sequence:

1. Create VPC
2. Create Public Subnet
3. Create Internet Gateway
4. Configure Route Table
5. Create Security Group
6. Create EC2 IAM Role
7. Launch EC2 Instance
8. Install and configure Apache
9. Verify Systems Manager Agent
10. Install and configure CloudWatch Agent
11. Verify CloudWatch Metrics
12. Create CloudWatch Dashboard
13. Configure P1 Apache Alarm
14. Configure P2 CPU Alarm
15. Create Amazon SNS Topic
16. Create AWS Lambda Function
17. Configure SNS-to-Lambda integration
18. Configure Lambda incident workflows
19. Test P1 automation
20. Test P2 diagnostic automation
21. Verify notifications and logs

---

# 5. Step 1 – Create Virtual Private Cloud

Create the project VPC.

| Property | Value |
|---|---|
| Name | `cloudops-vpc` |
| CIDR Block | `10.0.0.0/16` |

### Expected Result

The VPC is created successfully and is available for the project infrastructure.

---

# 6. Step 2 – Create Public Subnet

Create a public subnet inside the project VPC.

| Property | Value |
|---|---|
| Name | `cloudops-subnet` |
| CIDR Block | `10.0.0.0/28` |
| Type | Public |

### Expected Result

The subnet is available and associated with the project VPC.

---

# 7. Step 3 – Create Internet Gateway

Create and attach the Internet Gateway.

| Property | Value |
|---|---|
| Name | `cloudops-igw` |
| VPC | `cloudops-vpc` |

### Expected Result

The Internet Gateway is attached to the VPC.

---

# 8. Step 4 – Configure Route Table

Configure the route table for internet connectivity.

| Destination | Target |
|---|---|
| `0.0.0.0/0` | Internet Gateway |

Associate the route table with `cloudops-subnet`.

### Expected Result

The public subnet has a route to the internet.

---

# 9. Step 5 – Create Security Group

Create the security group used by the EC2 instance.

**Security Group:** `cloudops-sg`

## Inbound Rules

| Protocol | Port | Source |
|---|---:|---|
| SSH | 22 | My IP |
| HTTP | 80 | Anywhere |

## Outbound Rules

Allow required outbound traffic according to the project configuration.

### Expected Result

The security group is available and attached to the EC2 instance.

---

# 10. Step 6 – Create IAM Role

Create the EC2 IAM role.

**Role Name:** `cloudops-EC2-inline-role`

The role provides the permissions required for:

- CloudWatch metric publishing
- CloudWatch Logs
- Systems Manager
- EC2 describe operations
- Required management operations used by the project

The project uses IAM roles rather than storing long-term AWS credentials on the EC2 instance.

### Expected Result

The IAM role is available for attachment to the EC2 instance.

---

# 11. Step 7 – Launch EC2 Instance

Launch the project EC2 instance.

| Property | Value |
|---|---|
| Instance Name | `cloudops-server` |
| Operating System | Amazon Linux 2023 |
| Instance Type | `t3.micro` |
| IAM Role | `cloudops-EC2-inline-role` |
| Security Group | `cloudops-sg` |

The instance used in the completed implementation is:

**Instance ID:** `i-0b7d483631875bb1c`

### Expected Result

The EC2 instance is running and reachable through the configured management method.

---

# 12. Step 8 – Install and Configure Apache

Install the Apache HTTP Server package.

The service name used by the project is:

`httpd`

Perform the following operations:

1. Install Apache.
2. Enable the service.
3. Start the service.
4. Verify that the service is active.
5. Verify HTTP availability.

### Expected Result

Apache is running successfully on `cloudops-server`.

---

# 13. Step 9 – Verify Systems Manager Agent

Verify that the AWS Systems Manager Agent is installed and running on the EC2 instance.

Confirm that the instance appears as a managed node in AWS Systems Manager.

The completed environment uses Systems Manager for remote command execution.

### Expected Result

`cloudops-server` is available as an online managed node.

---

# 14. Step 10 – Install and Configure CloudWatch Agent

Install the Amazon CloudWatch Agent on the EC2 instance.

The agent collects system and process-level metrics required by the NOC monitoring workflow.

The completed configuration includes metrics for:

- CPU utilization
- Memory utilization
- Disk usage
- Disk I/O
- Network traffic
- Apache process status

The primary network interface monitored by the configuration is:

`ens5`

The collection interval is:

**60 seconds**

### Expected Result

The CloudWatch Agent is running and publishing metrics to CloudWatch.

---

# 15. Step 11 – Verify CloudWatch Metrics

Verify that the expected metrics are being published successfully.

The project uses the `CWAgent` namespace for CloudWatch Agent metrics.

Verify:

- CPU metrics
- Memory metrics
- Disk metrics
- Network metrics
- Apache process count

### Expected Result

Current metric values are visible in Amazon CloudWatch.

---

# 16. Step 12 – Create CloudWatch Dashboard

Create the monitoring dashboard.

**Dashboard Name:** `cloudops-NOC-dashboard`

The dashboard should provide operational visibility for:

- CPU utilization
- Memory utilization
- Disk utilization
- Network traffic
- Apache process count

### Expected Result

The dashboard displays current and historical monitoring data.

---

# 17. Step 13 – Configure P1 Apache Alarm

The P1 workflow monitors Apache service availability.

**Alarm Name:** `NOC-cloudops-automate`

The alarm is associated with the Apache process monitoring metric.

### P1 Condition

Apache process becomes unavailable.

Operationally, the monitored Apache process count reaches zero.

### P1 Response

When the alarm enters the `ALARM` state:

1. CloudWatch sends the alarm event to SNS.
2. Lambda receives and parses the event.
3. Lambda identifies the incident as P1.
4. An incident ID is generated.
5. A P1 notification is sent.
6. Lambda sends an SSM Run Command.
7. SSM restarts `httpd`.
8. Lambda verifies the initial service status.
9. Lambda performs a stability recheck.
10. A resolved notification is sent when recovery is confirmed.

### Expected Result

An Apache service failure is automatically detected and remediated.

---

# 18. Step 14 – Configure P2 CPU Alarm

The P2 workflow monitors EC2 CPU utilization.

**Alarm Name:** `cpu alert`

### P2 Condition

CPU utilization:

**> 50%**

The alarm is associated with the EC2 CPU utilization metric.

### P2 Response

When the alarm enters the `ALARM` state:

1. CloudWatch sends the alarm event to SNS.
2. Lambda receives and parses the event.
3. Lambda identifies the incident as P2.
4. An incident ID is generated.
5. A P2 detection notification is sent.
6. Lambda executes an SSM diagnostic command.
7. Diagnostic output is collected.
8. CPU-related process information is reported.
9. A diagnostic report is sent to the operations team.
10. Manual review is required.

### Important Operational Rule

**P2 CPU automation is diagnostic-only.**

The workflow does **not** automatically restart services, terminate processes, reboot the instance, or perform destructive remediation.

### Expected Result

A CPU incident above 50% generates a diagnostic report for manual investigation.

---

# 19. Step 15 – Create Amazon SNS Topic

Create the project notification topic.

| Property | Value |
|---|---|
| Topic Name | `cloudops-sns` |
| Display Name | `NOC-topic` |

Configure the required email subscription and confirm it.

SNS is used to:

- Receive CloudWatch alarm notifications
- Trigger the Lambda automation
- Deliver operational incident notifications
- Deliver P1 recovery notifications
- Deliver P2 diagnostic reports

### Expected Result

SNS successfully delivers notifications to the configured subscriber.

---

# 20. Step 16 – Create AWS Lambda Function

Create the automation Lambda function.

| Property | Value |
|---|---|
| Function Name | `Cloudops-NOC-automate` |
| Runtime | Python |
| Trigger | Amazon SNS |

The Lambda function acts as the incident-processing and automation engine.

Its responsibilities include:

- Parse CloudWatch alarm events
- Identify supported alarm names
- Assign P1 or P2 severity
- Generate incident records
- Identify the target EC2 instance
- Publish notifications
- Execute SSM commands
- Verify P1 recovery
- Collect P2 diagnostics
- Publish final incident status

### Deployment Method

Lambda code is maintained and deployed using the **AWS Lambda Console editor**.

The deployment model is not changed to an external CLI-based deployment process.

### Expected Result

The Lambda function is deployed successfully and ready to receive SNS events.

---

# 21. Step 17 – Configure SNS-to-Lambda Integration

Configure the SNS topic as an event source for the Lambda function.

Flow:

```text
CloudWatch Alarm
       ↓
   SNS Topic
       ↓
Lambda Function
```

### Expected Result

SNS successfully invokes `Cloudops-NOC-automate` when a supported alarm event is published.

---

# 22. Step 18 – Configure Lambda Incident Workflows

The Lambda function uses the alarm name to determine the supported incident type.

## Supported Alarm Mapping

| Alarm | Severity | Workflow |
|---|---|---|
| `NOC-cloudops-automate` | P1 | Apache auto-remediation |
| `cpu alert` | P2 | CPU diagnostics |

Unsupported alarms are ignored and do not generate an operational notification.

This prevents unrelated test alarms or obsolete alarm types from entering the finalized NOC workflow.

---

# 23. Step 19 – Test P1 Automation

Perform a controlled Apache failure test.

### Test Procedure

1. Confirm Apache is running.
2. Stop the `httpd` service on the EC2 instance.
3. Wait for the CloudWatch metric to reflect the failure.
4. Confirm `NOC-cloudops-automate` enters the `ALARM` state.
5. Confirm SNS receives the alarm event.
6. Confirm Lambda identifies the incident as P1.
7. Confirm the P1 incident notification is delivered.
8. Confirm Lambda starts an SSM Run Command.
9. Confirm the command restarts `httpd`.
10. Confirm the initial service check succeeds.
11. Confirm the stability recheck succeeds.
12. Confirm the P1 resolved notification is delivered.

### Expected Result

Apache is automatically restored and the operations team receives both incident and recovery notifications.

---

# 24. Step 20 – Test P2 Diagnostic Automation

Perform a controlled CPU alarm test using the CloudWatch alarm configuration or a test event.

### Test Alarm

**Alarm Name:** `cpu alert`

### Test Condition

**CPU utilization > 50%**

### Test Event Structure

The following event format was used to validate the Lambda event parser and P2 workflow:

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

### Expected P2 Workflow

```text
CPU Alarm
   ↓
P2 Detection
   ↓
Incident Created
   ↓
Notification Sent
   ↓
SSM Diagnostic Command
   ↓
Diagnostic Output
   ↓
Manual Review Required
```

### Expected Result

The Lambda function identifies `cpu alert` as P2, collects CPU diagnostics through SSM, and sends a diagnostic report without applying automatic remediation.

---

# 25. Deployment Verification Checklist

| Verification Item | Status |
|---|---|
| VPC created | Completed |
| Public subnet configured | Completed |
| Internet Gateway attached | Completed |
| Route table configured | Completed |
| Security group configured | Completed |
| EC2 instance running | Completed |
| Apache installed | Completed |
| Apache service verified | Completed |
| IAM role configured | Completed |
| CloudWatch Agent running | Completed |
| CloudWatch metrics available | Completed |
| CloudWatch dashboard created | Completed |
| P1 Apache alarm configured | Completed |
| P2 CPU alarm configured | Completed |
| SNS topic created | Completed |
| SNS email subscription confirmed | Completed |
| Lambda function deployed | Completed |
| SNS-to-Lambda integration configured | Completed |
| P1 auto-remediation tested | Completed |
| P1 recovery notification tested | Completed |
| P2 diagnostic workflow tested | Completed |
| P2 diagnostic notification tested | Completed |

---

# 26. Troubleshooting Procedure

## 26.1 Lambda Does Not Receive the Alarm

Check:

1. CloudWatch Alarm state.
2. SNS topic delivery.
3. SNS-to-Lambda subscription.
4. Lambda CloudWatch Logs.
5. Lambda event parsing.

The Lambda logs should confirm successful event parsing.

---

## 26.2 Unsupported Alarm Is Received

If Lambda logs show:

```text
Unrecognized alarm '<alarm-name>'. Ignoring it.
```

verify that the alarm is one of the supported project alarms:

- `NOC-cloudops-automate`
- `cpu alert`

Unrelated test alarms should not be added to the production workflow unless the project scope is intentionally changed.

---

## 26.3 P1 SSM Command Fails

Check:

- EC2 managed-node status
- SSM Agent status
- IAM permissions
- SSM command status
- Lambda CloudWatch Logs

Manual investigation is required if Apache cannot be restored automatically.

---

## 26.4 P2 Diagnostic Command Fails

Check:

- EC2 managed-node status
- SSM Agent status
- IAM permissions
- SSM command status
- Lambda CloudWatch Logs

The P2 workflow should remain diagnostic-only.

---

## 26.5 CloudWatch Metrics Are Missing

Check:

- CloudWatch Agent service status
- Agent configuration
- `CWAgent` namespace
- Metric dimensions
- Collection interval
- CloudWatch Agent logs

---

# 27. Rollback Procedure

If the deployment must be removed, perform the cleanup in dependency order.

1. Disable or remove the Lambda trigger.
2. Remove the Lambda function if required.
3. Remove SNS subscriptions and topic.
4. Remove CloudWatch alarms.
5. Remove the CloudWatch dashboard.
6. Stop or remove the CloudWatch Agent configuration.
7. Remove or terminate the EC2 instance if required.
8. Detach and remove IAM resources that are no longer required.
9. Remove the security group after dependent resources are removed.
10. Remove the route table association.
11. Remove the route table.
12. Detach and delete the Internet Gateway.
13. Delete the subnet.
14. Delete the VPC.

Rollback should be performed carefully to avoid deleting resources that are required by other workloads.

---

# 28. Operational Verification

After deployment, verify the complete NOC workflow.

## P1 Verification

```text
Apache Failure
      ↓
CloudWatch Alarm
      ↓
SNS
      ↓
Lambda
      ↓
P1 Incident
      ↓
SSM Restart
      ↓
Initial Check
      ↓
Stability Recheck
      ↓
Resolved Notification
```

## P2 Verification

```text
CPU > 50%
      ↓
CloudWatch Alarm
      ↓
SNS
      ↓
Lambda
      ↓
P2 Incident
      ↓
SSM Diagnostics
      ↓
Diagnostic Report
      ↓
Manual Review
```

---

# 29. Deployment Outcome

The CloudOps NOC Automation environment is deployed as an event-driven AWS monitoring and incident-response solution.

The finalized implementation supports two operational workflows:

- **P1 Apache failure:** automatic restart through AWS Systems Manager with post-recovery verification.
- **P2 CPU utilization above 50%:** automated diagnostic collection followed by manual review.

The deployment provides centralized monitoring, incident identification, automated P1 remediation, P2 diagnostic escalation, and email-based operational notifications.

The resulting environment demonstrates a practical AWS CloudOps/NOC workflow while maintaining a clear separation between automatically remediated incidents and incidents requiring human investigation.
