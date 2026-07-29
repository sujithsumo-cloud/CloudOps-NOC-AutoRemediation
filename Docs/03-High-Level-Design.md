# High-Level Design (HLD)

## Project Title

AWS CloudOps NOC Automation using Amazon CloudWatch, SNS, Lambda, Systems Manager (SSM), and EC2

---

# Document Information

| Item | Details |
|------|----------|
| Document Name | High-Level Design (HLD) |
| Project | AWS CloudOps NOC Automation |
| Version | 1.0 |
| Prepared By | Smart Sujith |
| Date | July 2026 |

---

# 1. Introduction

This document provides the High-Level Design (HLD) for the AWS CloudOps NOC Automation project.

The purpose of this design is to describe how AWS services work together to automatically detect service failures, notify the operations team, restart the failed service, and confirm recovery without manual intervention.

The document focuses on the overall architecture and interactions between AWS components rather than implementation-level details.

---

# 2. Objective

The solution is designed to:

- Monitor the Apache HTTP service continuously.
- Detect service failures automatically.
- Notify the Network Operations Center (NOC).
- Restart the failed service using AWS Systems Manager.
- Verify service recovery.
- Send a success notification after remediation.
- Reduce manual operational effort.
- Improve service availability.

---

# 3. Solution Overview

The project consists of a single Amazon EC2 instance running an Apache web server.

Amazon CloudWatch Agent collects operating system metrics from the EC2 instance and publishes them to Amazon CloudWatch.

CloudWatch Alarms continuously evaluate these metrics.

When Apache stops running, CloudWatch detects the failure and publishes an alert to an Amazon SNS topic.

The SNS topic invokes an AWS Lambda function.

The Lambda function executes an AWS Systems Manager Run Command to restart Apache.

After restarting the service, Lambda verifies that Apache is active.

Finally, Lambda sends a success notification through Amazon SNS to the NOC engineer.

---

# 4. High-Level Architecture

                   +-------------------------+
                   |       End Users         |
                   +------------+------------+
                                |
                                |
                                v
                      Amazon EC2 Instance
                (Amazon Linux 2023 + Apache)
                                |
                                |
                CloudWatch Agent + SSM Agent
                                |
                                |
                                v
                     Amazon CloudWatch Metrics
                                |
                                |
                       CloudWatch Alarm
                                |
                                |
                                v
                        Amazon SNS Topic
                                |
                                |
                                v
                        AWS Lambda Function
                                |
                                |
                 AWS Systems Manager (Run Command)
                                |
                                |
                                v
                     Restart Apache Service
                                |
                                |
                                v
                   Verify Service Status
                                |
                                |
                                v
                  Amazon SNS Success Notification
                                |
                                |
                                v
                       NOC Engineer Email
