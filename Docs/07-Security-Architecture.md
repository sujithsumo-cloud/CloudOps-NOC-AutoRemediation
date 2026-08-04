# Security Architecture

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda, and AWS Systems Manager

---

# Document Information

| Item | Details |
|------|----------|
| Document Name | Security Architecture |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Sujith |
| Date | July 2026 |

---

# 1. Purpose

This document describes the security architecture implemented for the CloudOps NOC Automation solution. It explains how AWS security services and best practices are used to protect infrastructure, control access, secure communication, and maintain operational integrity.

The objective is to ensure that only authorized users and AWS services can access project resources while reducing security risks.

---

# 2. Security Objectives

The security architecture is designed to achieve the following objectives:

- Protect AWS resources from unauthorized access.
- Implement secure communication between AWS services.
- Apply the Principle of Least Privilege.
- Secure management of the EC2 instance.
- Enable monitoring and auditing of system activities.
- Protect automation workflows from unauthorized execution.

---

# 3. Security Architecture Overview

The solution uses AWS Identity and Access Management (IAM), Security Groups, Systems Manager, CloudWatch, and Lambda to provide a secure automation environment.

Main security layers include:

- Identity Security
- Network Security
- Instance Security
- Monitoring Security
- Automation Security
- Logging and Auditing

---

# 4. Identity and Access Management (IAM)

## IAM Role

| Property | Value |
|----------|-------|
| Role Name | cloudops-EC2-inline-role |
| Attachment Type | Instance Profile |
| Attached To | EC2 Instance |

### Purpose

The IAM role allows the EC2 instance to securely communicate with AWS services without storing AWS access keys on the server.

### Permissions Granted

The custom inline policy provides access to:

- Amazon CloudWatch
- CloudWatch Logs
- Amazon Systems Manager (SSM)
- EC2 Describe APIs
- Amazon SNS (through Lambda workflow)

### Security Benefits

- No hardcoded credentials.
- Temporary AWS credentials from Instance Metadata Service (IMDSv2).
- Reduced risk of credential exposure.
- Centralized permission management.

---

# 5. Network Security

## Virtual Private Cloud (VPC)

| Property | Value |
|----------|-------|
| VPC Name | cloudops-vpc |
| CIDR Block | 10.0.0.0/16 |

The VPC provides logical isolation for all project resources.

---

## Public Subnet

| Property | Value |
|----------|-------|
| Name | cloudops-subnet |
| Type | Public |

The EC2 instance is deployed inside the public subnet with controlled access through Security Groups.

---

## Security Group

Security Group Name

cloudops-sg

### Inbound Rules

| Service | Port | Source |
|----------|------|--------|
| SSH | 22 | Administrator IP |
| HTTP | 80 | 0.0.0.0/0 |

### Outbound Rules

All outbound traffic is allowed to enable communication with AWS managed services.

### Security Benefits

- Restricts administrative access.
- Allows only required application traffic.
- Blocks unnecessary inbound connections.

---

# 6. EC2 Instance Security

Instance Name

cloudops-server

Operating System

Amazon Linux 2023

### Security Features

- Latest Amazon Linux AMI
- Automatic IAM authentication
- SSM Agent installed
- CloudWatch Agent installed
- Minimal software installation
- Apache service monitored continuously

The EC2 instance does not store AWS Access Keys or Secret Keys.

---

# 7. Systems Manager Security

AWS Systems Manager replaces direct SSH-based administration for automation tasks.

### Features Used

- Managed Node
- Run Command
- Session Manager

### Benefits

- No password-based remote administration.
- Secure communication over HTTPS.
- IAM-based authorization.
- Command execution logging.
- Reduced attack surface.

---

# 8. CloudWatch Security

CloudWatch securely receives metrics from the CloudWatch Agent using IAM authentication.

### Protected Resources

- System Metrics
- Apache Process Metrics
- Dashboard Data
- CloudWatch Alarms

Only authorized AWS services can publish and access monitoring data.

---

# 9. Lambda Security

Lambda Function

Cloudops-NOC-automate

### Responsibilities

- Receive SNS events.
- Execute SSM Run Command.
- Restart Apache service.
- Publish notification.

### Security Controls

- IAM execution role.
- Environment variables for configuration.
- No embedded credentials.
- Limited permissions following least privilege.

---

# 10. SNS Security

SNS Topic

cloudops-sns

### Subscribers

- AWS Lambda
- Email Subscription

### Security Features

- IAM-controlled publishing.
- Verified email subscription.
- Secure HTTPS communication.
- Event-driven notifications.

---

# 11. CloudWatch Agent Security

The CloudWatch Agent runs as a system service on the EC2 instance.

### Configuration

Configuration File

```
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/file_file_amazon-cloudwatch-agent.json
```

### Metrics Collected

- CPU Utilization
- Memory Utilization
- Disk Utilization
- Network Metrics
- Apache Process Count

### Security Measures

- Uses IAM role authentication.
- No stored AWS credentials.
- Secure communication with CloudWatch.
- Read-only access to system performance data.

---

# 12. Logging and Auditing

The project maintains operational logs for monitoring and troubleshooting.

### Log Sources

| Component | Log Location |
|-----------|--------------|
| CloudWatch Agent | /opt/aws/amazon-cloudwatch-agent/logs/ |
| SSM Agent | /var/log/amazon/ssm/ |
| System Logs | /var/log/messages |
| Lambda Logs | Amazon CloudWatch Logs |

### Benefits

- Centralized log management.
- Event tracking.
- Operational auditing.
- Faster troubleshooting.

---

# 13. Credential Management

The project does not use permanent AWS credentials.

Authentication is performed through:

- IAM Role
- Instance Metadata Service Version 2 (IMDSv2)

Advantages:

- Temporary credentials.
- Automatic credential rotation.
- Improved security.
- No manual key management.

---

# 14. Data Protection

The solution protects operational data by using AWS managed services.

Security measures include:

- Encrypted HTTPS communication.
- IAM authorization.
- Controlled access to AWS APIs.
- Secure service-to-service communication.

No sensitive application data is stored within the automation workflow.

---

# 15. Security Best Practices Implemented

The following AWS security best practices are implemented:

- Principle of Least Privilege.
- IAM Role instead of Access Keys.
- Security Group-based firewall.
- Systems Manager for remote management.
- CloudWatch monitoring.
- Centralized logging.
- Event-driven automation.
- Temporary IAM credentials.
- Secure API communication over HTTPS.

---

# 16. Security Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Unauthorized AWS API access | IAM Role with limited permissions |
| Exposed credentials | No static access keys used |
| Apache service failure | Automatic restart through Lambda and SSM |
| Unauthorized server access | Security Group restrictions |
| Lack of monitoring | CloudWatch Dashboard and Alarms |
| Manual operational delays | Automated remediation workflow |

---

# 17. Security Workflow

Administrator

↓

IAM Authentication

↓

AWS Services

↓

CloudWatch Agent

↓

CloudWatch Monitoring

↓

CloudWatch Alarm

↓

SNS Topic

↓

Lambda Function

↓

Systems Manager

↓

Restart Apache

↓

Success Notification

All communication between AWS services is authenticated using IAM roles and secured over HTTPS.

---

# 18. Compliance with AWS Best Practices

The implemented solution follows AWS recommended operational and security practices by:

- Using managed AWS services.
- Applying least privilege access.
- Eliminating hardcoded credentials.
- Using IAM roles for authentication.
- Monitoring infrastructure continuously.
- Automating operational response.
- Maintaining centralized logging.

---

# 19. Conclusion

The security architecture for the CloudOps NOC Automation project provides a secure and reliable environment for automated monitoring and remediation. By integrating IAM, Security Groups, Systems Manager, CloudWatch, SNS, and Lambda, the solution minimizes security risks while ensuring operational efficiency.

The use of IAM roles, secure communication, centralized logging, and automated recovery demonstrates adherence to AWS security best practices and provides a strong foundation for enterprise cloud operations.
