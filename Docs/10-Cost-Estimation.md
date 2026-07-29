# Document 10 – Cost Estimation (AWS Pricing Calculator)

## Project Title

CloudOps NOC Automation using AWS CloudWatch, Lambda, SNS and Systems Manager (SSM)

---

# 1. Purpose

This document provides the estimated monthly AWS cost for the CloudOps NOC Automation project.

The purpose of this estimation is to understand the operational cost of the solution before production deployment. The project is designed for a small environment with one Amazon EC2 instance and a server monitoring automation workflow.

The pricing shown below is based on the AWS Pricing Calculator for the Mumbai Region (ap-south-1). Actual charges may vary depending on resource usage.

---

# 2. AWS Region

Region:

- Asia Pacific (Mumbai)
- Region Code: ap-south-1

---

# 3. Services Used

The following AWS services are included in this project.

| AWS Service | Purpose |
|-------------|----------|
| Amazon EC2 | Application Server |
| Amazon EBS | Root Volume Storage |
| Amazon CloudWatch | Monitoring and Alarms |
| Amazon SNS | Email Notifications |
| AWS Lambda | Auto Remediation |
| AWS Systems Manager | Remote Management |
| IAM | Secure Permissions |
| VPC | Network Infrastructure |
| Internet Gateway | Internet Connectivity |
| Route Table | Routing |
| Security Group | Firewall Rules |

---

# 4. Estimated Monthly Cost

## 4.1 Amazon EC2

Configuration

- Instance Type: t2.micro
- Operating System: Amazon Linux 2023
- Usage: 730 Hours per Month

Estimated Monthly Cost

Approximately

**USD 8.50**

---

## 4.2 Amazon EBS

Configuration

- GP3 Volume
- Size: 8 GB

Estimated Monthly Cost

Approximately

**USD 0.70**

---

## 4.3 Amazon CloudWatch

Used For

- Custom Metrics
- Dashboard
- Alarms
- CloudWatch Agent

Estimated Monthly Cost

Approximately

**USD 2.00**

---

## 4.4 Amazon SNS

Used For

- Email Notifications

Expected Usage

- Few notifications per day

Estimated Monthly Cost

Free Tier

or

Less than

**USD 0.10**

---

## 4.5 AWS Lambda

Used For

- Auto Restart Apache Service
- Send Success Notification

Expected Usage

- Very low execution count

Estimated Monthly Cost

Free Tier

or

Less than

**USD 0.20**

---

## 4.6 AWS Systems Manager (SSM)

Used For

- Run Command
- Remote Command Execution

Estimated Monthly Cost

No additional cost for the services used in this project.

---

## 4.7 IAM

Purpose

- Access Management

Estimated Monthly Cost

Free

---

## 4.8 Amazon VPC

Components

- VPC
- Subnet
- Route Table
- Internet Gateway

Estimated Monthly Cost

Free

---

## 4.9 Security Groups

Purpose

- Firewall Rules

Estimated Monthly Cost

Free

---

# 5. Monthly Cost Summary

| AWS Service | Estimated Cost (USD) |
|-------------|----------------------|
| Amazon EC2 | 8.50 |
| Amazon EBS | 0.70 |
| CloudWatch | 2.00 |
| SNS | 0.10 |
| Lambda | 0.20 |
| Systems Manager | 0.00 |
| IAM | 0.00 |
| VPC | 0.00 |
| Security Groups | 0.00 |

---

# Total Estimated Monthly Cost

| Description | Cost |
|-------------|------|
| Total | **Approximately USD 11.50 per month** |

---

# 6. Cost Optimization

The following practices can reduce the monthly AWS cost.

- Use t2.micro or t3.micro instance.
- Delete unused CloudWatch logs.
- Remove unused CloudWatch alarms.
- Delete unused Lambda versions.
- Use Free Tier services whenever possible.
- Stop the EC2 instance when not required.
- Monitor AWS billing regularly.

---

# 7. Pricing Assumptions

This estimate assumes:

- One EC2 instance
- One Lambda function
- One SNS Topic
- One CloudWatch Dashboard
- Two CloudWatch Alarms
- One CloudWatch Agent
- One Amazon Linux server
- One EBS volume
- Normal lab usage

Large production environments will have higher costs depending on:

- Number of EC2 instances
- Number of alarms
- Custom metrics
- Log storage
- Lambda invocations
- Notification volume

---

# 8. Conclusion

The CloudOps NOC Automation project is a low-cost monitoring and auto-remediation solution built using AWS native services.

The estimated monthly infrastructure cost is approximately **USD 11.50**, making it suitable for learning, demonstrations, academic submissions, and small production environments.

The architecture is scalable and additional EC2 instances, CloudWatch alarms, Lambda functions, and SNS notifications can be added without changing the overall solution design.
