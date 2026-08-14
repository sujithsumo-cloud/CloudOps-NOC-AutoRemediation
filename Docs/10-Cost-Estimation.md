# Document 10 – Cost Estimation (AWS Pricing Calculator)

## Project Title

CloudOps NOC Automation using AWS CloudWatch, Lambda, SNS and Systems Manager (SSM)

---

# 1. Purpose

This document provides the estimated monthly AWS cost for the CloudOps NOC Automation project.

The purpose of this estimation is to understand the operational cost of the solution before production deployment. The project is designed for a small environment with one Amazon EC2 instance and an automated monitoring and incident-response workflow.

The finalized project scope contains two automation levels:

- **P1 – HTTPD service automation**
- **P2 – CPU utilization automation**

The pricing shown below is an estimate for the Mumbai Region (ap-south-1). Actual charges may vary depending on resource usage, AWS pricing changes, and applicable Free Tier benefits.

---

# 2. AWS Region

Region:

- Asia Pacific (Mumbai)
- Region Code: ap-south-1

---

# 3. Services Used

The following AWS services support the finalized solution.

| AWS Service         | Purpose                                      |
| ------------------- | -------------------------------------------- |
| Amazon EC2          | Hosts the monitored application environment  |
| Amazon EBS          | Root volume storage                          |
| Amazon CloudWatch   | Metrics, dashboards, and alarms              |
| Amazon SNS          | Operational notifications and event delivery |
| AWS Lambda          | Automation and remediation logic             |
| AWS Systems Manager | Remote command execution                     |
| IAM                 | Secure permissions                            |
| VPC                 | Network infrastructure                       |
| Internet Gateway    | Internet connectivity                        |
| Route Table         | Network routing                              |
| Security Group      | Network access control                       |

---

# 4. Estimated Monthly Cost

## 4.1 Amazon EC2

Configuration

- Instance Type: t3.micro
- Operating System: Amazon Linux 2023
- Usage: 730 hours per month

Estimated Monthly Cost

Approximately

**USD 8.50**

---

## 4.2 Amazon EBS

Configuration

- GP3 volume
- Size: 8 GB

Estimated Monthly Cost

Approximately

**USD 0.70**

---

## 4.3 Amazon CloudWatch

CloudWatch is used for:

- System and application monitoring
- Custom metrics
- CloudWatch Dashboard
- P1 HTTPD monitoring alarm
- P2 CPU utilization alarm
- Monitoring data required by the automation workflow

Estimated Monthly Cost

Approximately

**USD 2.00**

---

## 4.4 Amazon SNS

SNS is used for:

- Operational notifications
- Alarm event delivery
- Lambda event triggering
- Success or failure notifications

Expected Usage

- Low notification volume suitable for a small lab environment

Estimated Monthly Cost

Free Tier

or

Less than

**USD 0.10**

---

## 4.5 AWS Lambda

Lambda is used for:

- P1 HTTPD remediation
- P2 CPU utilization automation
- Processing monitoring events
- Executing the configured remediation workflow
- Sending operational notifications

Expected Usage

- Low execution volume

Estimated Monthly Cost

Free Tier

or

Less than

**USD 0.20**

---

## 4.6 AWS Systems Manager (SSM)

Systems Manager is used for:

- Run Command
- Remote command execution
- Automated service remediation

Estimated Monthly Cost

No additional cost is expected for the Systems Manager capabilities used in this project, subject to AWS pricing and usage conditions.

---

## 4.7 IAM

Purpose

- Secure access management
- Service authorization
- Role-based authentication

Estimated Monthly Cost

**USD 0.00**

---

## 4.8 Amazon VPC

Components

- VPC
- Subnet
- Route Table
- Internet Gateway

Estimated Monthly Cost

**USD 0.00** for the listed VPC components, excluding any separately chargeable networking services or usage.

---

## 4.9 Security Groups

Purpose

- Network access control
- Firewall rules

Estimated Monthly Cost

**USD 0.00**

---

# 5. Monthly Cost Summary

| AWS Service     | Estimated Cost (USD) |
| --------------- | -------------------- |
| Amazon EC2      | 8.50                 |
| Amazon EBS      | 0.70                 |
| CloudWatch      | 2.00                 |
| SNS             | 0.10                 |
| Lambda          | 0.20                 |
| Systems Manager | 0.00                 |
| IAM             | 0.00                 |
| VPC             | 0.00                 |
| Security Groups | 0.00                 |

---

# Total Estimated Monthly Cost

| Description | Cost                                  |
| ----------- | ------------------------------------- |
| Total       | **Approximately USD 11.50 per month** |

The total is an approximate planning estimate based on the assumptions in this document. Actual AWS billing may differ.

---

# 6. Cost Optimization

The following practices can help reduce the monthly AWS cost:

- Use an appropriately sized EC2 instance for the workload.
- Stop the EC2 instance when it is not required for testing or demonstrations.
- Remove unused CloudWatch logs and monitoring data where appropriate.
- Review unused CloudWatch alarms and dashboards.
- Keep Lambda execution volume low by triggering automation only for required incidents.
- Use AWS Free Tier benefits where applicable.
- Review AWS billing and usage regularly.
- Avoid unnecessary custom metrics and excessive log retention.
- Remove unused resources after project testing.

---

# 7. Pricing Assumptions

This estimate assumes:

- One EC2 instance.
- One Lambda function.
- One SNS topic.
- One CloudWatch Dashboard.
- Two CloudWatch alarms.
- One CloudWatch Agent.
- One Amazon Linux server.
- One EBS volume.
- Low-volume notification traffic.
- Low Lambda execution volume.
- Normal academic or lab usage.
- Mumbai Region (ap-south-1).

The two CloudWatch alarms correspond to the finalized project scope:

- **P1 – HTTPD service monitoring and automation**
- **P2 – CPU utilization monitoring and automation**

P3 or unknown-service automation is excluded and therefore does not introduce additional cost into this estimate.

Production environments may have higher costs depending on:

- Number of EC2 instances
- Number of monitored metrics
- Number of CloudWatch alarms
- Log ingestion and retention
- Lambda invocations and execution duration
- SNS notification volume
- Storage requirements
- Network usage

---

# 8. Cost Considerations for the Finalized Scope

The project has been intentionally limited to two automation levels to keep the solution operationally focused and cost controlled.

The P1 HTTPD automation uses monitoring, notification, Lambda, and Systems Manager capabilities to recover the web service.

The P2 CPU utilization automation extends the monitoring and automation workflow to CPU-related incidents without introducing an additional severity level or separate monitoring platform.

This approach keeps the project within a small AWS environment while demonstrating both application-level and infrastructure-performance automation.

---

# 9. Conclusion

The CloudOps NOC Automation project is a low-cost monitoring and auto-remediation solution built using AWS native services.

The finalized implementation covers **P1 HTTPD service automation** and **P2 CPU utilization automation**. The estimated monthly infrastructure cost remains approximately **USD 11.50**, based on the assumptions stated in this document.

The solution is suitable for learning, demonstrations, academic submissions, and small-scale operational environments. The architecture can be extended in the future by increasing the number of monitored resources or automation workflows as business requirements grow.
