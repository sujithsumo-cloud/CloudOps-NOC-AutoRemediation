# 🚀 CloudOps NOC Auto-Remediation System on AWS

> An enterprise-style AWS Cloud Operations project that automatically detects Apache web server failures, sends notifications, and performs self-healing using AWS services.

---

# 📌 Project Overview

This project demonstrates an automated Network Operations Center (NOC) monitoring and remediation solution built on Amazon Web Services (AWS).

The system continuously monitors an Apache Web Server running on an Amazon EC2 instance. When a service failure is detected, Amazon CloudWatch triggers an alarm, Amazon SNS sends notifications, AWS Lambda invokes AWS Systems Manager (SSM), and the Apache service is restarted automatically.

The objective of this project is to minimize downtime, reduce manual intervention, and demonstrate cloud automation using AWS native services.

---

# 🎯 Project Objectives

- Build an enterprise-style cloud monitoring solution
- Automate incident detection and response
- Reduce Mean Time to Recovery (MTTR)
- Eliminate manual server intervention
- Demonstrate Infrastructure Monitoring and Auto Remediation
- Learn real-world AWS Operations workflows

---

# 🏗️ Solution Architecture

```
                   Users
                     │
                     ▼
          Apache Web Server (EC2)
                     │
                     ▼
          Amazon CloudWatch Agent
                     │
                     ▼
          Amazon CloudWatch Alarm
                     │
                     ▼
               Amazon SNS
              ┌──────────┐
              ▼          ▼
      Email Notification  AWS Lambda
                               │
                               ▼
                    AWS Systems Manager
                               │
                               ▼
                Restart Apache Service
                               │
                               ▼
                 CloudWatch Status = OK
```

> 📌 Replace this diagram with your AWS Solution Architecture image.

---

# ☁️ AWS Services Used

| Service | Purpose |
|----------|---------|
| Amazon EC2 | Hosts the Apache Web Server |
| Amazon VPC | Provides secure networking |
| Amazon IAM | Controls permissions between AWS services |
| Amazon CloudWatch | Monitors infrastructure and generates alarms |
| Amazon CloudWatch Agent | Collects OS-level metrics |
| Amazon SNS | Sends notifications and triggers Lambda |
| AWS Lambda | Executes automated remediation logic |
| AWS Systems Manager (SSM) | Executes remote commands on EC2 |
| Amazon EBS | Persistent storage for the EC2 instance |

---

# ✨ Features

- Automated Apache monitoring
- Real-time CloudWatch metrics
- CloudWatch Dashboard
- Alarm-based monitoring
- Email notifications using Amazon SNS
- Automated Apache restart
- Secure remote management using AWS Systems Manager
- HTTPS-enabled Apache Web Server
- Enterprise troubleshooting documentation
- Infrastructure automation scripts

---

# 🔄 Workflow

1. User sends a request to the Apache Web Server.
2. CloudWatch Agent collects system metrics.
3. Amazon CloudWatch evaluates the metrics.
4. A CloudWatch Alarm enters the **ALARM** state when a threshold is exceeded.
5. Amazon SNS publishes a notification.
6. An email alert is sent to the administrator.
7. AWS Lambda is invoked automatically.
8. Lambda calls AWS Systems Manager Run Command.
9. Systems Manager executes the restart command on the EC2 instance.
10. Apache service is restored.
11. CloudWatch detects recovery and returns the alarm to the **OK** state.

---

# 📁 Repository Structure

```text
CloudOps-NOC-Auto-Remediation/
│
├── apache/
├── cloudwatch/
├── sns/
├── lambda/
├── ssm/
├── iam/
├── architecture/
├── diagrams/
├── scripts/
├── screenshots/
│
├── README.md
├── LICENSE
└── .gitignore
```

---

# 🖥️ Technology Stack

- Amazon Web Services (AWS)
- Amazon Linux 2023
- Apache HTTP Server
- Python
- Boto3
- Bash
- JSON
- Linux Systemd

---

# 📊 Monitoring Components

- CPU Utilization
- Memory Utilization
- Disk Usage
- Network Traffic
- Apache Availability
- CloudWatch Dashboard
- CloudWatch Alarm

---

# 🔐 Security

- IAM Roles (No Access Keys)
- Systems Manager (No SSH Required)
- HTTPS Configuration
- Principle of Least Privilege
- CloudWatch Logging
- IAM Trust Relationships

---

# 📷 Project Screenshots

Add screenshots here:

- AWS Architecture Diagram
- EC2 Console
- CloudWatch Dashboard
- CloudWatch Alarm
- SNS Topic
- Email Notification
- Lambda Function
- Systems Manager Run Command
- Apache Web Page
- HTTPS Access

---

# 🧪 Testing

The following scenarios were tested:

- Apache service stopped manually
- CloudWatch alarm triggered
- SNS email notification received
- Lambda invoked successfully
- Systems Manager executed Run Command
- Apache service restarted automatically
- CloudWatch alarm returned to **OK** state

---

# 🛠️ Troubleshooting

Common issues documented in this repository include:

- Apache service failure
- SSM Agent offline
- CloudWatch Agent stopped
- Lambda permission errors
- IAM role configuration
- SNS notification issues
- HTTPS certificate configuration
- EC2 connectivity problems

Detailed troubleshooting guides are available inside each service folder.

---

# 📚 Learning Outcomes

This project helped develop practical knowledge of:

- AWS Cloud Architecture
- Infrastructure Monitoring
- Event-Driven Automation
- Server Administration
- IAM Security
- Linux Administration
- Cloud Operations (CloudOps)
- Incident Response
- Production Troubleshooting
- Self-Healing Infrastructure

---

# 🚀 Future Improvements

- Route 53 integration
- AWS Certificate Manager (ACM)
- Application Load Balancer (ALB)
- Auto Scaling Group
- Multi-AZ deployment
- Amazon EventBridge integration
- AWS Config compliance monitoring
- AWS X-Ray tracing
- Infrastructure as Code (Terraform)

---

# 👨‍💻 Author

**Smart Sujith**

Cloud & DevOps Engineer (Learning)

GitHub: *(Add your GitHub profile)*

LinkedIn: *(Add your LinkedIn profile)*

---

# 📄 License

This project is licensed under the MIT License.

See the **LICENSE** file for more information.
