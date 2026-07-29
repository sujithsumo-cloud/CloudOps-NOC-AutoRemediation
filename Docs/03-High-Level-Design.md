# High-Level Design (HLD)

# CloudOps NOC Auto-Remediation System

---

# 1. Overview

The CloudOps NOC Auto-Remediation System is an event-driven cloud operations solution built on Amazon Web Services (AWS). The project continuously monitors the health of an Apache Web Server hosted on an Amazon EC2 instance. When a service disruption occurs, the monitoring system automatically detects the failure, generates an alarm, notifies the operations team, and initiates an automated recovery process without requiring manual intervention.

The primary objective of this solution is to improve service availability, reduce operational effort, and minimize the Mean Time to Recovery (MTTR) by leveraging AWS-native services.

---

# 2. Business Objective

Traditional server management requires engineers to manually investigate and recover failed services, increasing downtime and operational costs.

This solution demonstrates how AWS services can work together to:

- Detect infrastructure failures in real time
- Notify the operations team immediately
- Automatically remediate service failures
- Restore application availability without manual intervention
- Improve operational efficiency and system reliability

---

# 3. Solution Architecture

The solution is composed of the following AWS services:

- Amazon EC2
- Apache HTTP Server
- Amazon CloudWatch Agent
- Amazon CloudWatch
- Amazon SNS
- AWS Lambda
- AWS Systems Manager (SSM)
- AWS Identity and Access Management (IAM)
- Amazon Elastic Block Store (EBS)

Each service performs a specific role within the monitoring and remediation workflow.

---

# 4. Architecture Diagram

Insert the High-Level Architecture Diagram here.

```
Users
   │
   ▼
Amazon EC2 (Apache)
   │
   ▼
CloudWatch Agent
   │
   ▼
Amazon CloudWatch
   │
   ▼
CloudWatch Alarm
   │
   ▼
Amazon SNS
   │
   ├────────► Email Notification
   │
   ▼
AWS Lambda
   │
   ▼
AWS Systems Manager
   │
   ▼
Restart Apache Service
```

---

# 5. Component Description

## Amazon EC2

Hosts the Apache Web Server that serves client requests.

---

## Apache HTTP Server

Processes incoming HTTP and HTTPS requests from users.

---

## CloudWatch Agent

Collects operating system metrics such as CPU utilization, memory usage, disk utilization, and service health, then publishes the metrics to Amazon CloudWatch.

---

## Amazon CloudWatch

Monitors collected metrics and evaluates alarm conditions based on predefined thresholds.

---

## CloudWatch Alarm

Transitions from the **OK** state to the **ALARM** state whenever the monitored service becomes unavailable or exceeds configured thresholds.

---

## Amazon SNS

Receives alarm notifications from CloudWatch and distributes them to multiple subscribers.

In this project, SNS:

- Sends an email notification
- Invokes AWS Lambda

---

## AWS Lambda

Acts as the automation engine.

Upon receiving an SNS notification, Lambda invokes AWS Systems Manager to execute the required remediation commands.

---

## AWS Systems Manager (SSM)

Securely executes remote shell commands on the EC2 instance without requiring SSH access.

The Run Command service restarts the Apache Web Server.

---

## IAM

Provides secure authentication and authorization between AWS services using IAM Roles instead of long-term access keys.

---

## Amazon EBS

Provides persistent block storage for the EC2 instance, ensuring that application data remains available after instance stop/start operations.

---

# 6. End-to-End Workflow

1. A user sends a request to the Apache Web Server.
2. Apache serves the request.
3. CloudWatch Agent continuously collects operating system metrics.
4. Metrics are published to Amazon CloudWatch.
5. CloudWatch evaluates the configured alarm thresholds.
6. If Apache becomes unavailable, the CloudWatch Alarm enters the **ALARM** state.
7. CloudWatch publishes an event to Amazon SNS.
8. SNS sends an email notification to the administrator.
9. SNS invokes the AWS Lambda function.
10. Lambda sends an SSM Run Command.
11. AWS Systems Manager delivers the command to the SSM Agent running on the EC2 instance.
12. The SSM Agent executes the command to restart the Apache service.
13. Apache returns to the **Running** state.
14. CloudWatch detects normal operation and changes the alarm state back to **OK**.

---

# 7. Security Design

The solution follows AWS security best practices.

- IAM Roles are used instead of access keys.
- Systems Manager eliminates the need for SSH access.
- HTTPS provides encrypted communication.
- Security Groups restrict inbound traffic.
- Least Privilege access is implemented for AWS services.

---

# 8. Benefits

- Automated incident detection
- Automated remediation
- Reduced downtime
- Improved service availability
- Reduced manual intervention
- Secure remote administration
- Event-driven architecture
- Scalable cloud-native design

---

# 9. Assumptions

- The EC2 instance is running.
- Apache is installed.
- CloudWatch Agent is configured correctly.
- Amazon SSM Agent is active.
- IAM Roles are attached correctly.
- Internet connectivity is available for AWS service communication.

---

# 10. Limitations

- Designed for a single EC2 instance.
- Does not include Auto Scaling.
- Uses a self-managed Apache Web Server.
- High Availability (Multi-AZ) is not implemented.

---

# 11. Future Enhancements

- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- AWS Certificate Manager (ACM)
- Amazon Route 53
- Multi-AZ Deployment
- AWS Config
- AWS X-Ray
- Infrastructure as Code (Terraform)
- CI/CD Pipeline using GitHub Actions

---

# 12. Conclusion

The CloudOps NOC Auto-Remediation System demonstrates how AWS managed services can be integrated to build an automated monitoring and self-healing infrastructure. By combining Amazon CloudWatch, Amazon SNS, AWS Lambda, and AWS Systems Manager, the solution minimizes manual operational effort while improving application availability and operational reliability.

This project provides practical experience in cloud monitoring, incident response, infrastructure automation, and cloud operations engineering using AWS.
