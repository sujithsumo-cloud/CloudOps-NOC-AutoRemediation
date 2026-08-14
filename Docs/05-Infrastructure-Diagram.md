# Document 5 – Infrastructure Diagram

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda and Systems Manager

---

# Document Information

| Item | Details |
| --- | --- |
| Document Name | Infrastructure Diagram |
| Project | CloudOps NOC Automation |
| Version | 2.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Status | Final |

---

# 1. Purpose

This document describes the AWS infrastructure used by the CloudOps NOC Automation solution and shows how the infrastructure components interact with the monitoring and incident-response workflow.

The architecture supports two finalized NOC automation use cases:

- **P1 – Apache HTTP Server (httpd) failure:** automatic remediation and recovery verification.
- **P2 – CPU utilization above 50%:** automated diagnostic collection followed by manual review; no automatic CPU remediation is performed.

The infrastructure uses AWS managed services to provide monitoring, event-driven incident handling, secure remote execution, logging, and operational notification.

---

# 2. Infrastructure Overview

The solution is deployed in the AWS Asia Pacific (Mumbai) Region (`ap-south-1`).

An Amazon EC2 instance named `cloudops-server` hosts the Apache HTTP Server. The CloudWatch Agent collects system and application-related metrics and publishes them to Amazon CloudWatch.

CloudWatch alarms detect the two supported incident conditions:

- `NOC-cloudops-automate` – P1 Apache service/process failure.
- `cpu alert` – P2 CPU utilization greater than 50%.

When an alarm event is received, the Lambda function identifies the supported priority and executes the corresponding workflow.

For P1, Lambda uses AWS Systems Manager Run Command to restart Apache and then performs a stability verification.

For P2, Lambda uses Systems Manager to collect CPU diagnostic information. The diagnostic result is sent to the operations team for manual review. No automatic restart or destructive remediation is performed for CPU incidents.

---

# 3. Infrastructure Components

| AWS Service / Component | Resource Name / Identifier | Purpose |
| --- | --- | --- |
| VPC | `cloudops-vpc` | Network boundary for the EC2 environment |
| Public Subnet | `cloudops-subnet` | Hosts the EC2 instance |
| Route Table | `cloudops-rt` | Provides subnet routing |
| Internet Gateway | `cloudops-igw` | Internet connectivity |
| Security Group | `cloudops-sg` | Network access control |
| EC2 | `cloudops-server` | Hosts Apache and monitoring agents |
| IAM Role | `cloudops-EC2-inline-role` | EC2 permissions for AWS services |
| CloudWatch Agent | Installed on EC2 | Publishes system/application metrics |
| CloudWatch Dashboard | `cloudops-NOC-dashboard` | Operational monitoring |
| P1 CloudWatch Alarm | `NOC-cloudops-automate` | Detects Apache failure |
| P2 CloudWatch Alarm | `cpu alert` | Detects CPU utilization > 50% |
| SNS Topic | `cloudops-sns` | Notification and Lambda integration |
| SNS Display Name | `NOC-topic` | Notification identity |
| Lambda | `Cloudops-NOC-automate` | Incident detection and automation logic |
| Systems Manager | `cloudops-server` managed node | Remote diagnostic/remediation execution |
| CloudWatch Logs | Lambda and AWS service logs | Execution and troubleshooting visibility |

---

# 4. Infrastructure Layout

```text
                              AWS Cloud
                                  │
                         ap-south-1 (Mumbai)
                                  │
                    ┌─────────────┴─────────────┐
                    │        cloudops-vpc        │
                    │        10.0.0.0/16         │
                    │                            │
                    │   cloudops-subnet          │
                    │      Public Subnet         │
                    │            │                │
                    │            ▼                │
                    │     EC2: cloudops-server   │
                    │     i-0b7d483631875bb1c     │
                    │            │                │
                    │     ┌──────┴──────┐         │
                    │     │             │         │
                    │  httpd       CW Agent       │
                    │     │             │         │
                    └─────┼─────────────┼─────────┘
                          │             │
                          │        CloudWatch
                          │             │
                          │     ┌───────┴────────┐
                          │     │                │
                          │   P1 Alarm         P2 Alarm
                          │ NOC-cloudops-     cpu alert
                          │   automate       CPU > 50%
                          │     │                │
                          └─────┴───────┬────────┘
                                        │
                                   SNS: cloudops-sns
                                        │
                              ┌─────────┴─────────┐
                              │                   │
                         Email Alert         Lambda
                         NOC-topic       Cloudops-NOC-automate
                                                  │
                                           AWS Systems Manager
                                                  │
                                      ┌───────────┴───────────┐
                                      │                       │
                                  P1 Workflow             P2 Workflow
                                      │                       │
                              Restart httpd             Collect CPU
                              + stability check         diagnostics
                                      │                       │
                                      └───────────┬───────────┘
                                                  │
                                           SNS Notifications
```

---

# 5. Network Architecture

## 5.1 VPC

| Property | Value |
| --- | --- |
| Name | `cloudops-vpc` |
| CIDR Block | `10.0.0.0/16` |
| Region | `ap-south-1` |

The VPC provides the network boundary for the EC2-based monitoring environment.

---

## 5.2 Public Subnet

| Property | Value |
| --- | --- |
| Name | `cloudops-subnet` |
| CIDR Block | `10.0.0.0/28` |
| Type | Public |

The subnet contains the EC2 instance used for the project.

---

## 5.3 Internet Gateway

| Property | Value |
| --- | --- |
| Name | `cloudops-igw` |
| Purpose | Internet connectivity for the public subnet |

---

## 5.4 Route Table

The public subnet uses a route to the Internet Gateway.

| Destination | Target |
| --- | --- |
| `0.0.0.0/0` | `cloudops-igw` |

---

## 5.5 Security Group

| Property | Value |
| --- | --- |
| Name | `cloudops-sg` |

Inbound access includes:

| Port | Protocol | Source | Purpose |
| --- | --- | --- | --- |
| 22 | SSH | My IP | Administrative access |
| 80 | HTTP | Anywhere | Apache web access |

Outbound traffic is allowed as configured for the project environment.

---

# 6. Compute Layer

The EC2 instance hosts the Apache HTTP Server and the agents required for monitoring and Systems Manager management.

| Property | Value |
| --- | --- |
| Instance Name | `cloudops-server` |
| Instance ID | `i-0b7d483631875bb1c` |
| Operating System | Amazon Linux 2023 |
| Instance Type | `t3.micro` |
| IAM Role | `cloudops-EC2-inline-role` |
| Availability Zone | `ap-south-1a` |
| Private IP | `10.0.0.13` |

Installed components include:

- Apache HTTP Server (`httpd`)
- Amazon CloudWatch Agent
- AWS Systems Manager Agent

---

# 7. Monitoring Layer

The CloudWatch Agent collects operating system and application-related metrics from the EC2 instance.

Configured monitoring includes:

- CPU utilization
- Memory utilization
- Disk usage
- Disk I/O
- Network traffic
- Apache process status

The metrics are published to Amazon CloudWatch.

The monitoring data supports both the P1 Apache availability workflow and the P2 CPU utilization workflow.

---

# 8. Dashboard Layer

## CloudWatch Dashboard

Dashboard Name:

`cloudops-NOC-dashboard`

The dashboard provides operational visibility into metrics such as:

- CPU utilization
- Memory utilization
- Disk utilization
- Network traffic
- Apache process count/status

The dashboard is used for monitoring and troubleshooting and does not itself perform remediation.

---

# 9. Alerting Layer

The finalized solution contains **two supported severities**.

## 9.1 P1 – Apache HTTP Server Failure

| Property | Value |
| --- | --- |
| Alarm Name | `NOC-cloudops-automate` |
| Priority | P1 |
| Condition | Apache/httpd process unavailable |
| Response | Automatic remediation |
| Remediation | Restart Apache through SSM |
| Verification | Initial check + stability recheck |

When the alarm enters the `ALARM` state, the event is processed as a P1 incident.

---

## 9.2 P2 – High CPU Utilization

| Property | Value |
| --- | --- |
| Alarm Name | `cpu alert` |
| Priority | P2 |
| Metric | `CPUUtilization` |
| Threshold | Greater than 50% |
| Response | Diagnostic collection |
| Automatic CPU remediation | Not implemented |
| Manual review | Required |

When the alarm enters the `ALARM` state, Lambda collects diagnostic information using SSM.

The diagnostic information includes:

- Uptime and load
- Top CPU-consuming processes
- Memory usage

The P2 workflow does not automatically restart services or perform destructive remediation.

---

# 10. Notification Layer

## Amazon SNS

| Property | Value |
| --- | --- |
| Topic Name | `cloudops-sns` |
| Display Name | `NOC-topic` |
| Region | `ap-south-1` |

SNS is used to:

- Deliver incident notifications by email.
- Provide the event integration used by the Lambda workflow.
- Deliver P1 recovery notifications.
- Deliver P2 diagnostic and manual-review notifications.

Notifications include incident information such as priority, alarm name, instance information, detection time, and remediation/diagnostic status.

---

# 11. Automation Layer

## AWS Lambda

| Property | Value |
| --- | --- |
| Function Name | `Cloudops-NOC-automate` |
| Runtime | Python |
| Trigger | CloudWatch alarm event through the configured notification path |

The Lambda function is the central incident-processing component.

Its workflow includes:

1. Parse the CloudWatch alarm event.
2. Extract the alarm name and alarm state.
3. Identify the supported priority.
4. Create an incident record.
5. Send the appropriate detection notification.
6. Execute the P1 or P2 workflow.
7. Record the SSM command result.
8. Send the appropriate final notification.

Unsupported alarm names are ignored and do not generate operational notifications.

This behavior prevents unrelated test alarms, such as `Parser-Test`, from entering the production incident workflow.

---

# 12. Management and Remediation Layer

AWS Systems Manager provides secure command execution against the EC2 managed node.

## P1 Workflow

For an Apache failure:

```text
Lambda
  ↓
SSM Run Command
  ↓
Restart httpd
  ↓
Initial httpd check
  ↓
15-second stability recheck
  ↓
Resolved notification
```

The verified P1 test demonstrated:

- SSM command execution succeeded.
- Apache initial check passed.
- Stability recheck passed.
- A P1 resolved notification was generated.

---

## P2 Workflow

For CPU utilization above 50%:

```text
Lambda
  ↓
SSM Run Command
  ↓
Collect CPU diagnostics
  ↓
Diagnostic report
  ↓
Manual review required
```

The verified P2 test demonstrated:

- SSM diagnostic command succeeded.
- CPU diagnostic information was collected.
- A P2 diagnostic report was generated.
- No automatic CPU remediation was performed.

---

# 13. IAM and Security Layer

IAM provides authentication and authorization for AWS service interactions.

The EC2 instance uses:

`cloudops-EC2-inline-role`

The environment is designed around role-based AWS access rather than storing long-term AWS access keys on the EC2 instance.

Systems Manager is used for remote command execution, reducing the operational need to use SSH for automated remediation.

Security controls include:

- IAM role-based access
- Least-privilege permissions
- Security Group network controls
- CloudWatch Logs for audit and troubleshooting
- Systems Manager for managed remote execution
- No hardcoded AWS credentials in the automation workflow

---

# 14. Data and Incident Flow

## P1 – Apache Failure

```text
Apache/httpd failure
        ↓
CloudWatch detects condition
        ↓
NOC-cloudops-automate → ALARM
        ↓
CloudWatch alarm event
        ↓
Lambda
        ↓
P1 incident created
        ↓
Detection notification
        ↓
SSM Run Command
        ↓
Restart httpd
        ↓
Initial verification
        ↓
15-second stability verification
        ↓
P1 Resolved notification
```

---

## P2 – CPU > 50%

```text
CPUUtilization > 50%
        ↓
cpu alert → ALARM
        ↓
CloudWatch alarm event
        ↓
Lambda
        ↓
P2 incident created
        ↓
Detection notification
        ↓
SSM diagnostic command
        ↓
CPU / load / process / memory collection
        ↓
Diagnostic report
        ↓
Manual review required
```

---

# 15. Logging and Operational Visibility

The infrastructure uses CloudWatch Logs and service-level execution records to support troubleshooting.

Important information recorded by the Lambda workflow includes:

- Alarm name
- Alarm state
- Incident ID
- Priority
- Instance name and ID
- SSM Command ID
- SSM execution status
- Diagnostic or remediation result
- Notification status
- Resolution or review status

The verified P1 and P2 tests produced traceable incident records and SSM command identifiers.

---

# 16. Infrastructure Benefits

The infrastructure provides:

- Automated Apache failure recovery for P1 incidents
- Automated CPU diagnostics for P2 incidents
- Reduced manual intervention for known P1 failures
- Faster incident detection
- Centralized monitoring
- Structured incident notifications
- Secure remote command execution
- Operational logging and traceability
- Clear separation between automatic remediation and manual review

---

# 17. Design Highlights

- Single-region AWS architecture
- Single EC2 workload
- Event-driven incident processing
- CloudWatch-based monitoring
- SNS-based notification and integration
- Lambda-based incident automation
- Systems Manager-based remote execution
- IAM role-based authentication
- Two finalized severity levels: P1 and P2
- P1 automatic remediation
- P2 diagnostic-only handling
- Unsupported alarms ignored by the automation workflow

---

# 18. Limitations

The current infrastructure is intentionally limited to the finalized project scope.

- Single AWS Region
- Single EC2 instance
- No Auto Scaling Group
- No Application Load Balancer
- No multi-AZ high-availability deployment
- Apache is the only automatically remediated service
- CPU incidents are diagnostic-only
- Email is the operational notification channel
- Infrastructure is manually deployed

---

# 19. Conclusion

The CloudOps NOC Automation infrastructure integrates Amazon EC2, Amazon CloudWatch, Amazon SNS, AWS Lambda, AWS Systems Manager, and IAM into an event-driven operational workflow.

The finalized architecture supports two NOC use cases. P1 Apache failures are automatically remediated through Systems Manager and verified for stability. P2 CPU utilization alarms above 50% trigger automated diagnostics and escalation for manual review, without applying automatic CPU remediation.

This infrastructure provides a practical foundation for cloud operations monitoring, incident handling, automation, troubleshooting, and operational reporting.
