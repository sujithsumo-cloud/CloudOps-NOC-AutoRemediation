# Amazon EC2 Configuration

## Overview

Amazon Elastic Compute Cloud (EC2) is the compute service used to host the Apache web server in this project. It acts as the central server where the application runs and is monitored by AWS CloudWatch.

---

## Purpose

The EC2 instance is responsible for:

- Hosting the Apache HTTP Server
- Serving the website to users
- Running the CloudWatch Agent
- Running the AWS Systems Manager (SSM) Agent
- Receiving remote management commands from Systems Manager
- Publishing custom metrics and logs to Amazon CloudWatch

---

## EC2 Configuration

| Property | Value |
|----------|-------|
| Operating System | Amazon Linux 2023 |
| Instance Type | t3.micro |
| Web Server | Apache HTTP Server |
| Monitoring | CloudWatch Agent |
| Remote Management | AWS Systems Manager Agent |
| IAM Role | cloudops-EC2-inline-role |
| Storage | Amazon EBS |
| Availability Zone | ap-south-1a |

---

## Software Installed

- Apache HTTP Server
- CloudWatch Agent
- AWS Systems Manager Agent
- Git
- Python 3

---

## Project Workflow

1. Users access the Apache web server.
2. CloudWatch Agent continuously monitors the Apache service.
3. If Apache stops, CloudWatch Alarm enters the ALARM state.
4. SNS sends a notification.
5. Lambda executes an SSM Run Command.
6. SSM restarts the Apache service.
7. Lambda verifies service recovery.
8. SNS sends a recovery notification.

---

## Related Components

- VPC
- Security Group
- CloudWatch
- Lambda
- SNS
- Systems Manager
- IAM

---

## Best Practices

- Use IAM Roles instead of storing AWS credentials.
- Enable detailed monitoring.
- Keep the operating system updated.
- Restrict Security Group inbound rules.
- Use Systems Manager instead of SSH whenever possible.

---

## Future Enhancements

- Deploy behind an Application Load Balancer.
- Enable Auto Scaling.
- Use HTTPS with AWS Certificate Manager (ACM).
- Integrate with Amazon RDS.
