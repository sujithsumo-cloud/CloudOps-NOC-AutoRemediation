# Document 1 – Business Requirement Document (BRD)

**Project Title:** CloudOps NOC Automation using AWS CloudWatch, Lambda, Amazon SNS, and AWS Systems Manager (SSM)

| Document Information | Details |
|----------------------|---------|
| Document Name | Business Requirement Document (BRD) |
| Version | 1.0 |
| Project Type | AWS Cloud Infrastructure Automation |
| Prepared By | Sujith |
| Date | July 2026 |
| Status | Final |

---

# 1. Introduction

## 1.1 Purpose

The purpose of this project is to design and implement an automated Network Operations Center (NOC) solution using AWS cloud services. The solution continuously monitors an Amazon EC2 instance running the Apache (httpd) web server. When the Apache service stops unexpectedly, the system automatically detects the issue, restarts the service using AWS Systems Manager, and sends an email notification to the operations team through Amazon SNS.

The project demonstrates how AWS managed services can be integrated to reduce manual operational tasks, improve service availability, and automate incident response.

---

## 1.2 Business Background

Modern organizations rely on web servers to deliver business applications and services. If a web server becomes unavailable due to a service failure, users may experience downtime, resulting in reduced productivity and poor customer experience.

Traditionally, operations engineers monitor servers manually or respond only after receiving incident reports. This approach increases recovery time and operational effort.

An automated monitoring and remediation solution helps organizations detect failures immediately, restore services automatically, and notify engineers without requiring manual intervention.

---

## 1.3 Problem Statement

The existing environment does not provide automated monitoring or recovery for critical services running on the EC2 instance.

As a result:

- Service failures may go unnoticed.
- Engineers must manually connect to the server.
- Recovery time increases.
- Service availability decreases.
- Manual operations consume valuable time.

The organization requires an automated solution that detects service failures, restores services automatically, and informs the operations team immediately.

---

# 2. Business Objectives

The primary objectives of this project are:

- Monitor the Apache (httpd) service continuously.
- Detect service failures automatically.
- Restart the Apache service without manual intervention.
- Notify the operations team after successful remediation.
- Reduce service downtime.
- Improve system availability.
- Reduce operational effort.
- Demonstrate AWS automation using managed services.

---

# 3. Project Scope

## 3.1 In Scope

The project includes the following AWS services and components:

- Amazon EC2 instance
- Amazon Linux 2023 operating system
- Apache (httpd) web server
- Amazon CloudWatch Agent
- CloudWatch Metrics
- CloudWatch Dashboard
- CloudWatch Alarm
- Amazon SNS Topic
- AWS Lambda Function
- AWS Systems Manager (SSM)
- IAM Role with Inline Policy
- Email notification for successful remediation

---

## 3.2 Out of Scope

The following items are not included in this project:

- Multi-region deployment
- Auto Scaling Groups
- Load Balancer configuration
- Multi-server monitoring
- Database monitoring
- Container or Kubernetes monitoring
- SMS or mobile notifications
- Third-party monitoring tools

---

# 4. Business Requirements

The solution shall meet the following business requirements.

| Requirement ID | Business Requirement |
|----------------|----------------------|
| BR-01 | Monitor the Apache service running on the EC2 instance. |
| BR-02 | Collect operating system and application metrics using the CloudWatch Agent. |
| BR-03 | Detect when the Apache service stops running. |
| BR-04 | Generate a CloudWatch Alarm for the detected failure. |
| BR-05 | Publish the alarm notification to Amazon SNS. |
| BR-06 | Trigger an AWS Lambda function automatically. |
| BR-07 | Execute an AWS Systems Manager Run Command to restart Apache. |
| BR-08 | Verify that the Apache service has restarted successfully. |
| BR-09 | Send an email notification to the operations engineer after successful remediation. |
| BR-10 | Display monitoring metrics on a CloudWatch Dashboard. |

---

# 5. Functional Requirements

The solution shall provide the following functionality.

- Collect CPU, memory, disk, network, and Apache process metrics.
- Publish custom metrics to Amazon CloudWatch.
- Continuously evaluate CloudWatch alarms.
- Trigger Amazon SNS when an alarm enters the ALARM state.
- Invoke an AWS Lambda function through SNS.
- Execute AWS Systems Manager Run Command.
- Restart the Apache service.
- Verify the service status.
- Send a success notification to the operations engineer.
- Maintain monitoring data within CloudWatch.

---

# 6. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Availability | The monitoring system should operate continuously. |
| Reliability | The solution should automatically recover the Apache service after failure. |
| Performance | Incident detection and recovery should occur within a few minutes. |
| Scalability | The architecture should support additional EC2 instances in the future. |
| Security | Access should follow the principle of least privilege using IAM inline policies. |
| Maintainability | Configuration changes should be simple and manageable. |
| Cost Efficiency | The solution should use AWS managed services to minimize operational cost. |

---

# 7. Stakeholders

| Stakeholder | Responsibility |
|-------------|----------------|
| Project Owner | Approves the project and reviews deliverables. |
| AWS Administrator | Configures AWS infrastructure and IAM permissions. |
| Operations Engineer | Receives notifications and monitors system health. |
| System Administrator | Maintains the EC2 instance and Apache service. |

---

# 8. Assumptions

The project assumes the following:

- An active AWS account is available.
- Amazon Linux 2023 is installed on the EC2 instance.
- Apache (httpd) is installed.
- CloudWatch Agent is installed and configured.
- Systems Manager Agent is installed and running.
- IAM role with the required inline policy is attached to the EC2 instance.
- Internet connectivity is available.
- Email subscription for Amazon SNS is confirmed.

---

# 9. Constraints

The following constraints apply to this project:

- Single AWS Region (Asia Pacific – Mumbai).
- Single EC2 instance.
- Apache (httpd) is the only monitored application.
- Email notification is the only notification method.
- Infrastructure is deployed manually.

---

# 10. Business Benefits

The implemented solution provides the following benefits:

- Faster detection of application failures.
- Automatic service recovery.
- Reduced operational effort.
- Lower Mean Time to Recovery (MTTR).
- Improved server availability.
- Better monitoring visibility.
- Centralized monitoring dashboard.
- Practical implementation of AWS automation.

---

# 11. Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Incorrect IAM permissions | Validate IAM inline policies before deployment. |
| CloudWatch Agent failure | Monitor the CloudWatch Agent service regularly. |
| Lambda execution failure | Review Lambda logs in Amazon CloudWatch Logs. |
| SSM Agent failure | Verify that the SSM Agent is running and registered. |
| Alarm misconfiguration | Test alarms before production deployment. |

---

# 12. Success Criteria

The project will be considered successful when:

- The CloudWatch Agent publishes metrics successfully.
- CloudWatch detects Apache service failures.
- CloudWatch Alarm changes to the ALARM state.
- Amazon SNS receives the alarm notification.
- AWS Lambda is triggered automatically.
- AWS Systems Manager restarts the Apache service successfully.
- Apache returns to the running state.
- A success notification email is delivered to the operations engineer.
- The CloudWatch Dashboard displays the latest monitoring metrics.

---

# 13. Expected Business Outcome

After implementation, the organization will have an automated monitoring and remediation solution capable of detecting Apache service failures, restoring the service automatically, and notifying the operations team without manual intervention.

The solution improves service availability, reduces downtime, and provides a scalable foundation for future cloud infrastructure automation.

---

# 14. Conclusion

The CloudOps NOC Automation project delivers a reliable and automated monitoring solution using AWS managed services. By integrating Amazon CloudWatch, AWS Lambda, Amazon SNS, and AWS Systems Manager, the project reduces manual operational tasks, improves service availability, and enables faster incident response.

The solution is scalable, cost-effective, and suitable for academic projects, internship submissions, and small to medium production environments.
