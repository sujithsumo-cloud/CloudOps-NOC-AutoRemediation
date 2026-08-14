# Document 7 – Security Architecture

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, Amazon SNS, AWS Lambda, and AWS Systems Manager

---

# Document Information

| Item | Details |
|---|---|
| Document Name | Security Architecture |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | August 2026 |
| Environment | AWS Cloud |
| Region | ap-south-1 (Mumbai) |

---

# 1. Purpose

This document defines the security architecture for the CloudOps NOC Automation solution.

The security design protects the AWS infrastructure, controls access between users and AWS services, secures the EC2 management path, and protects the automated incident-response workflow.

The architecture supports two finalized operational workflows:

- **P1 – Critical:** Apache HTTP Server failure with automatic remediation.
- **P2 – High:** CPU utilization above 50% with diagnostic collection and manual review.

The security controls are designed to ensure that automation operates only on authorized resources and that no unnecessary automatic action is performed for P2 incidents.

---

# 2. Security Objectives

The security architecture is designed to:

- Protect AWS resources from unauthorized access.
- Apply the Principle of Least Privilege.
- Use IAM roles instead of long-term access keys.
- Secure EC2 management through AWS Systems Manager.
- Restrict network access through Security Groups.
- Authenticate AWS service-to-service communication.
- Maintain operational logs for troubleshooting and auditing.
- Restrict Lambda automation to supported NOC workflows.
- Prevent unsupported alarms from triggering operational remediation.
- Maintain a clear separation between P1 remediation and P2 diagnostics.

---

# 3. Security Architecture Overview

The solution uses multiple AWS security controls across the infrastructure and automation layers.

The primary security layers are:

1. Identity and Access Management
2. Network Security
3. EC2 Security
4. Systems Manager Security
5. Lambda Security
6. SNS Security
7. CloudWatch Security
8. Logging and Auditing
9. Automation Authorization
10. Credential Management

---

# 4. Identity and Access Management (IAM)

IAM provides authentication and authorization for AWS resources and services.

## 4.1 EC2 IAM Role

| Property | Value |
|---|---|
| Role Name | `cloudops-EC2-inline-role` |
| Attached To | `cloudops-server` |
| Policy Type | Custom Inline Policy |

The EC2 role provides the permissions required for the instance to communicate with AWS monitoring and management services.

### Required Access Areas

- CloudWatch metrics
- CloudWatch Logs
- Systems Manager
- EC2 Describe operations
- Other AWS APIs required by the implemented monitoring configuration

The actual permissions should remain limited to the operations required by the project.

## 4.2 Lambda Execution Role

The Lambda function uses an IAM execution role to access AWS services.

Required access areas include:

- Systems Manager Run Command
- Amazon SNS publishing
- CloudWatch Logs
- Required EC2 identification/describe operations

Lambda does not use hardcoded AWS credentials.

## 4.3 Least Privilege

IAM permissions should be restricted to the resources and actions required by each workflow.

The Lambda function is authorized to perform the operational actions required by the finalized project:

- P1: execute the Apache recovery workflow.
- P2: execute diagnostic collection only.

P2 does not receive permission or workflow logic for destructive or automatic recovery actions.

---

# 5. Network Security

## 5.1 VPC

| Property | Value |
|---|---|
| VPC Name | `cloudops-vpc` |
| CIDR Block | `10.0.0.0/16` |

The VPC provides network isolation for the project infrastructure.

## 5.2 Public Subnet

| Property | Value |
|---|---|
| Subnet Name | `cloudops-subnet` |
| Type | Public |
| CIDR | `10.0.0.0/28` |

The EC2 instance is deployed in the project subnet.

## 5.3 Internet Gateway

| Property | Value |
|---|---|
| Name | `cloudops-igw` |

The Internet Gateway provides internet connectivity for the public subnet.

## 5.4 Route Table

The public subnet uses a route to the Internet Gateway.

| Destination | Target |
|---|---|
| `0.0.0.0/0` | `cloudops-igw` |

## 5.5 Security Group

**Security Group:** `cloudops-sg`

### Inbound Rules

| Protocol | Port | Source |
|---|---:|---|
| SSH | 22 | Administrator's allowed IP |
| HTTP | 80 | `0.0.0.0/0` |

SSH access is restricted to the administrator's allowed source rather than being exposed to the entire internet.

HTTP is exposed because Apache is the monitored web service.

### Outbound Rules

Outbound communication required by the implementation is permitted so that the instance can communicate with AWS managed services and required external endpoints.

---

# 6. EC2 Instance Security

## 6.1 Instance

| Property | Value |
|---|---|
| Instance Name | `cloudops-server` |
| Instance ID | `i-0b7d483631875bb1c` |
| Operating System | Amazon Linux 2023 |
| Instance Type | `t3.micro` |

## 6.2 Security Controls

The EC2 instance uses:

- IAM role-based AWS authentication
- Systems Manager Agent
- CloudWatch Agent
- Security Group controls
- Amazon Linux 2023
- Apache service monitoring

The instance does not require permanent AWS access keys.

## 6.3 Application Security

The project monitors the Apache service (`httpd`) as the P1 application service.

The monitoring workflow detects Apache process failure and allows Lambda to initiate recovery through Systems Manager.

---

# 7. Systems Manager Security

AWS Systems Manager provides the controlled management path between Lambda and the EC2 instance.

## 7.1 Functions Used

- Managed Node
- Run Command
- Session Manager

## 7.2 Security Benefits

Systems Manager reduces dependence on direct SSH-based automation by providing:

- IAM-based authorization
- Authenticated AWS API requests
- Secure communication
- Centralized command execution
- Command execution status
- Operational logging

## 7.3 P1 Command Authorization

For P1 incidents, Lambda uses Systems Manager to execute the Apache recovery operation.

The recovery action is:

```text
systemctl restart httpd
```

The workflow then verifies the service and performs a stability recheck.

## 7.4 P2 Command Authorization

For P2 incidents, Systems Manager is used for diagnostic collection.

The P2 workflow is intentionally diagnostic-only.

It does not automatically:

- Restart arbitrary services
- Terminate processes
- Reboot the instance
- Perform destructive remediation

---

# 8. Lambda Security

## Lambda Function

**Function Name:** `Cloudops-NOC-automate`

Lambda is the central incident-processing component.

## Security Controls

- IAM execution role
- No hardcoded AWS credentials
- AWS API authentication through IAM
- CloudWatch Logs for execution auditing
- Restricted operational actions
- Alarm-name validation
- Separate P1 and P2 workflows

## Alarm Validation

Lambda recognizes only the finalized project alarms:

| Alarm | Severity | Authorized Workflow |
|---|---|---|
| `NOC-cloudops-automate` | P1 | Apache auto-remediation |
| `cpu alert` | P2 | CPU diagnostics |

Unsupported alarms are ignored.

This control prevents unrelated alarms, obsolete test alarms, or unsupported service conditions from entering the NOC automation workflow.

---

# 9. Amazon SNS Security

## SNS Topic

| Property | Value |
|---|---|
| Topic Name | `cloudops-sns` |
| Display Name | `NOC-topic` |

SNS provides controlled message distribution between CloudWatch, Lambda, and the operational email subscriber.

## Security Controls

- IAM-controlled AWS service access
- Confirmed email subscription
- AWS-authenticated service integration
- HTTPS-based service communication
- Event-driven message delivery

SNS is used for both incident notification and the downstream Lambda trigger.

---

# 10. CloudWatch Security

Amazon CloudWatch is responsible for receiving metrics, evaluating alarms, and providing monitoring visibility.

## Protected Monitoring Areas

- CPU utilization
- Memory utilization
- Disk metrics
- Network metrics
- Apache process count
- CloudWatch Alarm states
- Lambda execution logs

The CloudWatch Agent uses the EC2 IAM role to publish monitoring information without storing AWS access keys on the instance.

---

# 11. CloudWatch Agent Security

The CloudWatch Agent runs on the EC2 instance as a system service.

## Configuration Location

```text
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_file_amazon-cloudwatch-agent.json
```

## Metrics Collected

- CPU utilization
- Memory utilization
- Disk usage
- Disk I/O
- Network traffic
- Apache process count

## Security Measures

- IAM-based authentication
- No embedded AWS credentials
- Secure communication with AWS services
- Limited monitoring permissions
- Local configuration controlled by the operating system

---

# 12. Credential Management

The project does not depend on permanent AWS access keys stored on the EC2 instance or inside Lambda code.

AWS authentication is performed through IAM roles and temporary credentials.

This reduces the risk associated with:

- Credential leakage
- Hardcoded keys
- Manual credential rotation
- Unauthorized reuse of static credentials

Where supported by the deployed EC2 configuration, the instance uses the AWS Instance Metadata Service for temporary credentials.

---

# 13. Logging and Auditing

Operational logging is required to investigate failures and validate automation behavior.

## Log Sources

| Component | Log Source |
|---|---|
| Lambda | Amazon CloudWatch Logs |
| CloudWatch Agent | `/opt/aws/amazon-cloudwatch-agent/logs/` |
| SSM Agent | `/var/log/amazon/ssm/` |
| System | `/var/log/messages` |

## Lambda Audit Information

Lambda execution logs provide visibility into:

- Alarm parsing
- Alarm identification
- Severity detection
- Incident ID generation
- Notification delivery
- SSM Command ID
- SSM command status
- P1 verification
- P2 diagnostic collection
- Final workflow status

These logs support troubleshooting and operational verification.

---

# 14. Data Protection

The solution primarily processes operational monitoring and incident information.

Security controls include:

- IAM authorization
- HTTPS/TLS communication with AWS APIs
- Controlled access to CloudWatch Logs
- Controlled access to SNS
- No permanent AWS credentials in application code
- Restricted access to infrastructure resources

The automation workflow does not intentionally store sensitive application data.

---

# 15. Automation Security

Automation itself is treated as a security-sensitive capability because Lambda can execute commands on the EC2 instance.

The project therefore uses controlled alarm recognition.

## P1

Only the recognized P1 alarm can invoke the Apache recovery workflow:

```text
NOC-cloudops-automate
        ↓
P1
        ↓
SSM
        ↓
Restart httpd
```

## P2

Only the recognized P2 alarm can invoke the CPU diagnostic workflow:

```text
cpu alert
     ↓
P2
     ↓
SSM Diagnostics
     ↓
Manual Review
```

This design reduces the risk of an unexpected alarm causing an unintended remediation action.

---

# 16. Security Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Unauthorized AWS API access | IAM roles with required permissions only |
| Exposed AWS credentials | No static credentials stored on EC2 or Lambda |
| Unauthorized SSH access | SSH restricted by Security Group source |
| Apache failure | Controlled P1 auto-remediation through SSM |
| Excessive CPU usage | P2 diagnostic workflow with manual review |
| Unsupported alarm triggering automation | Alarm-name validation in Lambda |
| SSM command failure | Command status logging and operational review |
| Lambda execution failure | CloudWatch Logs and notification workflow |
| CloudWatch Agent failure | Agent monitoring and log review |
| Missing operational visibility | CloudWatch Dashboard and Logs |

---

# 17. Security Workflow

The security-controlled operational flow is:

```text
CloudWatch Metric
       ↓
CloudWatch Alarm
       ↓
SNS Topic
       ↓
Lambda
       ↓
Alarm Validation
       ↓
 ┌───────────────┬────────────────┐
 │               │                │
P1              P2          Unsupported
 │               │                │
SSM Recovery   SSM Diagnostics  Ignore
 │               │
Verify          Manual Review
 │
SNS Notification
```

Every supported automation path uses AWS service authentication and IAM authorization.

---

# 18. Security Best Practices Implemented

The project implements the following security practices:

- Principle of Least Privilege
- IAM roles instead of permanent access keys
- Security Group-based network controls
- Systems Manager for controlled remote execution
- CloudWatch monitoring and logging
- Alarm validation before automated action
- Separation of remediation and diagnostic workflows
- Secure AWS API communication
- Centralized operational logs
- Restricted administrative network access

---

# 19. Security Verification Checklist

| Security Control | Verification |
|---|---|
| EC2 IAM role attached | Completed |
| No static AWS credentials on EC2 | Verified |
| Lambda uses IAM execution role | Verified |
| SSH restricted | Configured |
| HTTP restricted to required application exposure | Configured |
| SSM managed node online | Verified |
| SSM Run Command available | Verified |
| CloudWatch Agent authenticated through IAM | Verified |
| SNS subscription confirmed | Verified |
| Lambda alarm validation implemented | Verified |
| P1 remediation restricted to supported alarm | Verified |
| P2 restricted to diagnostics | Verified |
| CloudWatch Logs available | Verified |

---

# 20. Conclusion

The CloudOps NOC Automation security architecture provides layered protection across identity, network, compute, monitoring, notification, and automation components.

The design uses IAM-based authentication, Security Groups, Systems Manager, CloudWatch, SNS, Lambda, and centralized logging to control access and maintain operational visibility.

Most importantly, the finalized automation scope separates the two incident types by risk:

- **P1 Apache failure** is authorized for automatic service recovery.
- **P2 CPU utilization above 50%** is limited to automated diagnostics and manual review.

This separation reduces the possibility of unsafe automated actions while preserving the operational benefits of AWS-based NOC automation.
