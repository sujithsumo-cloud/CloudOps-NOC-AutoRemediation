# Deployment Guide (SOP)

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda, and AWS Systems Manager

---

# Document Information

| Item | Details |
|------|----------|
| Document Name | Deployment Guide (SOP) |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Smart Sujith |
| Date | July 2026 |

---

# 1. Purpose

This Standard Operating Procedure (SOP) describes the deployment process for the CloudOps NOC Automation solution on AWS. The document provides the sequence of implementation steps required to deploy the complete monitoring and auto-remediation environment.

---

# 2. Scope

This deployment guide covers the following AWS services:

- Amazon VPC
- Amazon EC2
- IAM
- Amazon CloudWatch
- CloudWatch Agent
- Amazon SNS
- AWS Lambda
- AWS Systems Manager (SSM)

---

# 3. Prerequisites

Before deployment, ensure the following requirements are available.

## AWS Account

- Active AWS Account

## Region

- ap-south-1 (Mumbai)

## User Permissions

The deployment user should have administrative permissions to create and manage AWS resources.

---

# 4. Deployment Sequence

The deployment should be completed in the following order.

1. Create VPC
2. Create Subnet
3. Configure Route Table
4. Attach Internet Gateway
5. Create Security Group
6. Create IAM Role
7. Launch EC2 Instance
8. Install Apache
9. Install CloudWatch Agent
10. Verify SSM Agent
11. Configure CloudWatch Agent
12. Create CloudWatch Dashboard
13. Create CloudWatch Alarm
14. Create SNS Topic
15. Create Lambda Function
16. Configure Lambda Trigger
17. Test Automation

---

# 5. Step 1 – Create Virtual Private Cloud

Create a custom VPC.

| Property | Value |
|----------|-------|
| Name | cloudops-vpc |
| CIDR | 10.0.0.0/16 |

Expected Result

- VPC created successfully.

---

# 6. Step 2 – Create Public Subnet

Create a public subnet inside the VPC.

| Property | Value |
|----------|-------|
| Name | cloudops-subnet |
| CIDR | 10.0.1.0/24 |

Expected Result

- Public subnet available.

---

# 7. Step 3 – Create Internet Gateway

Create an Internet Gateway.

Name

cloudops-igw

Attach the Internet Gateway to the VPC.

Expected Result

- Internet connectivity enabled.

---

# 8. Step 4 – Configure Route Table

Create a route table.

| Destination | Target |
|-------------|--------|
| 0.0.0.0/0 | Internet Gateway |

Associate the route table with the public subnet.

Expected Result

- Public subnet can access the internet.

---

# 9. Step 5 – Create Security Group

Security Group Name

cloudops-sg

Inbound Rules

| Port | Protocol | Source |
|------|----------|--------|
| 22 | SSH | My IP |
| 80 | HTTP | Anywhere |

Outbound Rules

Allow All

Expected Result

- Security group configured.

---

# 10. Step 6 – Create IAM Role

Create an IAM Role for EC2.

Role Name

cloudops-EC2-inline-role

Attach the required inline policy for:

- CloudWatch
- CloudWatch Logs
- Systems Manager
- EC2 Describe permissions

Expected Result

- IAM Role attached successfully.

---

# 11. Step 7 – Launch EC2 Instance

Launch an EC2 instance.

Configuration

| Property | Value |
|----------|-------|
| AMI | Amazon Linux 2023 |
| Instance Type | t2.micro |
| IAM Role | cloudops-EC2-inline-role |
| Security Group | cloudops-sg |

Expected Result

- EC2 instance running.

---

# 12. Step 8 – Install Apache Web Server

Install Apache.

Enable the service.

Start the service.

Verify that Apache is active.

Expected Result

- Apache running successfully.

---

# 13. Step 9 – Install CloudWatch Agent

Install Amazon CloudWatch Agent.

Verify installation.

Configure the agent.

Start the service.

Expected Result

- CloudWatch Agent running.

---

# 14. Step 10 – Verify Systems Manager Agent

Verify that Amazon SSM Agent is installed and running.

Confirm the instance appears as a Managed Node.

Expected Result

- EC2 managed successfully through Systems Manager.

---

# 15. Step 11 – Configure CloudWatch Agent

Configure metrics collection for:

- CPU
- Memory
- Disk
- Disk I/O
- Network
- Apache Process

Metric Collection Interval

60 Seconds

Expected Result

- Metrics published to CloudWatch.

---

# 16. Step 12 – Create CloudWatch Dashboard

Dashboard Name

cloudops-NOC-dashboard

Include widgets for:

- CPU
- Memory
- Disk
- Network
- Apache Process

Expected Result

- Dashboard displays live metrics.

---

# 17. Step 13 – Create CloudWatch Alarm

Alarm Name

NOC-cloudops-automate

Monitor

Apache Process Count

Condition

Process Count equals Zero

Action

Publish notification to SNS.

Expected Result

- Alarm changes state when Apache stops.

---

# 18. Step 14 – Create SNS Topic

Topic Name

cloudops-sns

Display Name

NOC-topic

Create an Email Subscription.

Confirm the subscription.

Expected Result

- SNS notifications delivered successfully.

---

# 19. Step 15 – Create Lambda Function

Function Name

Cloudops-NOC-automate

Runtime

Python

Configure Environment Variables.

Grant IAM permissions to:

- Execute Systems Manager Run Command
- Publish SNS notifications

Expected Result

- Lambda function deployed successfully.

---

# 20. Step 16 – Configure SNS Trigger

Configure SNS as the event source for Lambda.

Expected Result

- SNS invokes Lambda automatically.

---

# 21. Step 17 – Test the Solution

Stop the Apache service manually.

CloudWatch detects the failure.

CloudWatch Alarm enters the ALARM state.

SNS publishes a notification.

Lambda executes automatically.

Lambda runs an SSM Run Command.

Apache service is restarted.

Lambda verifies the service status.

SNS sends a success notification.

Expected Result

- Apache restarts automatically without manual intervention.

---

# 22. Deployment Verification Checklist

| Verification Item | Status |
|-------------------|--------|
| EC2 Running | Completed |
| Apache Installed | Completed |
| CloudWatch Agent Running | Completed |
| SSM Agent Running | Completed |
| Managed Node Available | Completed |
| Dashboard Created | Completed |
| Alarm Created | Completed |
| SNS Topic Created | Completed |
| Lambda Created | Completed |
| Auto Remediation Working | Completed |
| Success Email Received | Completed |

---

# 23. Rollback Procedure

If deployment fails:

1. Delete Lambda Function.
2. Delete SNS Topic.
3. Delete CloudWatch Alarm.
4. Delete Dashboard.
5. Stop CloudWatch Agent.
6. Terminate EC2 Instance.
7. Remove IAM Role.
8. Delete Security Group.
9. Delete Route Table.
10. Delete Internet Gateway.
11. Delete Subnet.
12. Delete VPC.

---

# 24. Deployment Outcome

The CloudOps NOC Automation solution has been successfully deployed using AWS managed services. The environment continuously monitors the Apache web server, detects failures automatically, restarts the service through AWS Systems Manager, and notifies the operations team using Amazon SNS.

The deployment demonstrates an automated monitoring and remediation solution that reduces downtime, improves operational efficiency, and follows AWS best practices.
