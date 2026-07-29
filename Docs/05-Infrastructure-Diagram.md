# Infrastructure Diagram

## Project Title

CloudOps NOC Automation Using AWS CloudWatch, SNS, Lambda and Systems Manager

---

# Document Information

| Item | Details |
|------|----------|
| Document Name | Infrastructure Diagram |
| Project | CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Smart Sujith |
| Date | July 2026 |

---

# 1. Purpose

This document describes the complete AWS infrastructure used for the CloudOps NOC Automation project. It explains how the AWS resources are connected and how they work together to provide automated monitoring, alerting, and remediation.

The infrastructure is designed using AWS managed services to achieve high availability, automation, security, and operational efficiency.

---

# 2. Infrastructure Overview

The solution is deployed entirely in AWS Cloud using a Virtual Private Cloud (VPC). An Amazon EC2 instance hosts the Apache web server and is continuously monitored by Amazon CloudWatch Agent.

CloudWatch collects system metrics and monitors the health of the Apache service. If an issue is detected, CloudWatch Alarm sends a notification to Amazon SNS. The SNS topic triggers an AWS Lambda function, which uses AWS Systems Manager (SSM) Run Command to restart the Apache service automatically.

Finally, Lambda sends a notification to the NOC engineer confirming whether the remediation was successful.

---

# 3. Infrastructure Components

| AWS Service | Resource Name | Purpose |
|-------------|---------------|----------|
| VPC | cloudops-vpc | Private AWS Network |
| Public Subnet | cloudops-subnet | Hosts EC2 Instance |
| Route Table | cloudops-rt | Internet Routing |
| Internet Gateway | cloudops-igw | Internet Access |
| Security Group | cloudops-sg | Firewall Rules |
| EC2 | cloudops-server | Apache Web Server |
| IAM Role | cloudops-EC2-inline-role | Secure AWS Access |
| CloudWatch Agent | Installed on EC2 | Publish Metrics |
| CloudWatch Dashboard | cloudops-NOC-dashboard | Monitoring Dashboard |
| CloudWatch Alarm | NOC-cloudops-automate | Detect Apache Failure |
| CloudWatch Alarm | cloudops-cpuutilization | CPU Monitoring |
| SNS Topic | cloudops-sns | Notification Service |
| Lambda | Cloudops-NOC-automate | Auto Remediation |
| Systems Manager | Managed Node | Remote Command Execution |

---

# 4. Infrastructure Layout

                          Internet
                              │
                     Internet Gateway
                     (cloudops-igw)
                              │
                     Route Table
                    (cloudops-rt)
                              │
                -------------------------
                |                       |
                |   cloudops-vpc        |
                |   10.0.0.0/16         |
                |                       |
                |   Public Subnet       |
                |  (cloudops-subnet)    |
                |                       |
                |     EC2 Instance      |
                |   cloudops-server     |
                |                       |
                -------------------------
                              │
                 CloudWatch Agent
                              │
                       CloudWatch
                              │
                     CloudWatch Alarm
                              │
                           SNS Topic
                        (cloudops-sns)
                              │
                  --------------------
                  |                  |
              Lambda           Email Alert
      Cloudops-NOC-automate      (NOC)
                  │
                  │
          Systems Manager
          (Run Command)
                  │
                  ▼
      Restart Apache Service (httpd)

---

# 5. Network Architecture

## VPC

| Property | Value |
|----------|-------|
| Name | cloudops-vpc |
| CIDR | 10.0.0.0/16 |

---

## Subnet

| Property | Value |
|----------|-------|
| Name | cloudops-subnet |
| Type | Public |
| CIDR | 10.0.1.0/24 |

---

## Internet Gateway

| Name |
|------|
| cloudops-igw |

Provides internet connectivity for the EC2 instance.

---

## Route Table

| Destination | Target |
|-------------|--------|
| 0.0.0.0/0 | Internet Gateway |

---

# 6. Compute Layer

Amazon EC2 hosts the Apache web application.

| Property | Value |
|----------|-------|
| Instance Name | cloudops-server |
| Instance ID | i-0b7d483631875bb1c |
| Operating System | Amazon Linux 2023 |
| IAM Role | cloudops-EC2-inline-role |

Installed Components

- Apache HTTP Server
- Amazon CloudWatch Agent
- Amazon SSM Agent

---

# 7. Monitoring Layer

CloudWatch Agent collects operating system metrics.

Collected Metrics

- CPU Utilization
- Memory Utilization
- Disk Usage
- Disk I/O
- Network Traffic
- Apache Process Status

Metrics Namespace

CWAgent

Collection Interval

60 Seconds

---

# 8. Dashboard Layer

Dashboard Name

cloudops-NOC-dashboard

Displayed Widgets

- CPU Utilization
- Memory Utilization
- Disk Usage
- Network Bytes
- Apache Process Count

---

# 9. Alerting Layer

CloudWatch continuously evaluates metrics.

Configured Alarms

| Alarm Name | Purpose |
|------------|----------|
| NOC-cloudops-automate | Apache Monitoring |
| cloudops-cpuutilization | CPU Monitoring |

When threshold is crossed,

↓

SNS Notification is generated.

---

# 10. Notification Layer

Amazon SNS

Topic Name

cloudops-sns

Display Name

NOC-topic

Subscribers

- AWS Lambda
- NOC Engineer Email

---

# 11. Automation Layer

AWS Lambda

Function Name

Cloudops-NOC-automate

Responsibilities

- Receive SNS Event
- Validate Alarm
- Execute SSM Run Command
- Restart Apache
- Verify Service Status
- Send Success Notification

---

# 12. Management Layer

AWS Systems Manager

Managed Instance

cloudops-server

Functions

- Run Command
- Session Manager
- Managed Node
- Secure Remote Execution

No SSH credentials are required.

---

# 13. Security Layer

Security is implemented using AWS IAM.

IAM Role

cloudops-EC2-inline-role

Permissions

- CloudWatch
- CloudWatch Logs
- Systems Manager
- EC2 Describe
- SNS Integration

No AWS Access Keys are stored on the EC2 instance.

---

# 14. Data Flow

Step 1

Apache Service Running

↓

CloudWatch Agent Collects Metrics

↓

Publishes Metrics to CloudWatch

↓

CloudWatch Evaluates Alarm

↓

Apache Stops

↓

Alarm Changes to ALARM State

↓

SNS Topic Receives Notification

↓

Lambda Function Executes

↓

SSM Restarts Apache

↓

Lambda Verifies Status

↓

SNS Sends Success Email

↓

Apache Running Again

---

# 15. Infrastructure Benefits

- Fully automated monitoring
- Automatic incident recovery
- Reduced downtime
- Secure remote administration
- Centralized monitoring
- Real-time notifications
- Low operational overhead
- Easy scalability

---

# 16. Design Highlights

- Single VPC Architecture
- Public EC2 Deployment
- IAM Role-based Authentication
- CloudWatch Native Monitoring
- Event-driven Automation
- Serverless Remediation using Lambda
- Secure Systems Manager Execution
- Email Notification to Operations Team

---

# 17. Conclusion

The infrastructure is designed using AWS native services to provide a secure, automated, and highly available monitoring solution. The combination of Amazon EC2, CloudWatch, SNS, Lambda, and Systems Manager enables automatic detection and recovery of Apache service failures while keeping administrators informed through email notifications.

This architecture minimizes manual intervention, improves service availability, and demonstrates a practical implementation of Cloud Operations (CloudOps) and Network Operations Center (NOC) automation using AWS.
