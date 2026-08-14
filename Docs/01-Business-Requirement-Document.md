# Document 1 – Business Requirement Document (BRD)

**Project Title:** CloudOps NOC Automation using AWS CloudWatch, Lambda, Amazon SNS, and AWS Systems Manager (SSM)

| Document Information | Details |
| -------------------- | ------- |
| Document Name | Business Requirement Document (BRD) |
| Version | 2.0 |
| Project Type | AWS Cloud Infrastructure Automation |
| Prepared By | Sujith |
| Date | August 2026 |
| Status | Final |

---

# 1. Introduction

## 1.1 Purpose

The purpose of this project is to design and implement an automated Network Operations Center (NOC) solution using AWS cloud services. The solution continuously monitors an Amazon EC2 environment and automatically responds to defined infrastructure incidents.

The finalized solution uses two operational priorities:

- **P1 – Critical:** Apache HTTP Server (httpd) failure, with automatic service recovery.
- **P2 – High:** EC2 CPU utilization above the defined threshold, with automated diagnosis and escalation for manual review.

The solution demonstrates how AWS managed services can be integrated to detect incidents, perform controlled automated remediation where appropriate, collect diagnostic information, and notify operations personnel through email.

---

## 1.2 Business Background

Modern organizations depend on continuously available infrastructure and applications. Service failures and abnormal resource utilization can affect application availability, performance, and user experience.

Traditional monitoring approaches may require operations engineers to manually identify incidents, connect to affected systems, investigate the cause, and perform recovery actions. This increases operational effort and may increase Mean Time to Recovery (MTTR).

An automated NOC approach can detect defined incidents quickly, apply approved recovery procedures for suitable incidents, gather useful diagnostic information for incidents that require human investigation, and provide structured notifications to operations personnel.

---

## 1.3 Problem Statement

Without an automated NOC response process, infrastructure incidents may require manual detection, investigation, and recovery.

This can result in:

- Delayed incident detection.
- Increased manual operational effort.
- Longer recovery times for service failures.
- Limited visibility into the cause of resource-related incidents.
- Inconsistent incident notification and escalation.
- Increased risk of service downtime.

The organization requires an automated monitoring and incident-response solution that distinguishes between critical service failures and resource-related incidents and applies an appropriate response to each.

---

# 2. Business Objectives

The primary objectives of this project are:

- Continuously monitor important EC2 infrastructure and application conditions.
- Detect Apache HTTP Server failures automatically.
- Automatically recover the Apache service when a P1 incident occurs.
- Detect high CPU utilization as a P2 incident.
- Collect CPU-related diagnostic information without performing automatic CPU remediation.
- Verify automated recovery before declaring a P1 incident resolved.
- Escalate incidents that cannot be automatically resolved.
- Notify operations personnel with structured incident information.
- Reduce manual operational effort and MTTR.
- Improve service availability and monitoring visibility.
- Demonstrate practical AWS-based NOC automation.

---

# 3. Project Scope

## 3.1 In Scope

The project includes:

- Amazon EC2 infrastructure monitoring.
- Apache HTTP Server (httpd) monitoring.
- CPU utilization monitoring.
- Amazon CloudWatch metrics and alarms.
- CloudWatch Agent-based metric collection.
- CloudWatch Dashboard monitoring.
- AWS Lambda-based incident detection and response.
- Amazon SNS email notifications.
- AWS Systems Manager Run Command for controlled server-side actions.
- P1 automatic Apache recovery.
- P1 recovery verification and stability verification.
- P2 CPU diagnostic collection.
- P2 manual escalation after diagnosis.
- Structured incident identification and notification.
- Monitoring and operational logging through AWS services.

The finalized business scope contains **only P1 and P2** incident priorities. P3 and unknown-service automation are excluded.

---

## 3.2 Out of Scope

The following items are not included in this project:

- P3 incident automation.
- Unknown-service automatic remediation.
- Multi-region deployment.
- Auto Scaling Groups.
- Load Balancer configuration.
- Multi-server production orchestration.
- Database monitoring and remediation.
- Container or Kubernetes monitoring.
- Automatic CPU remediation or process termination.
- Automatic destructive remediation.
- SMS or mobile notifications.
- Third-party monitoring platforms.

---

# 4. Business Requirements

The solution shall meet the following business requirements.

| Requirement ID | Business Requirement |
| -------------- | -------------------- |
| BR-01 | Monitor the EC2 environment and relevant application/resource metrics. |
| BR-02 | Monitor Apache HTTP Server availability. |
| BR-03 | Detect Apache service failure as a P1 critical incident. |
| BR-04 | Automatically initiate approved Apache recovery for a P1 incident. |
| BR-05 | Verify that Apache has successfully recovered before declaring the incident resolved. |
| BR-06 | Perform a stability verification after initial Apache recovery. |
| BR-07 | Detect CPU utilization above the defined P2 threshold. |
| BR-08 | Collect CPU diagnostic information when a P2 incident occurs. |
| BR-09 | Avoid automatic restart or destructive remediation for P2 CPU incidents. |
| BR-10 | Escalate P2 CPU incidents for manual operational review. |
| BR-11 | Generate a unique incident identifier for actionable incidents. |
| BR-12 | Notify operations personnel when an incident is detected. |
| BR-13 | Notify operations personnel when a P1 incident is successfully resolved or requires escalation. |
| BR-14 | Provide diagnostic details for P2 incidents in the incident notification. |
| BR-15 | Ignore unknown or non-actionable alarm names without initiating remediation or notification. |
| BR-16 | Maintain monitoring and operational visibility through AWS monitoring and logging services. |

---

# 5. Functional Requirements

The solution shall provide the following functionality.

- Collect infrastructure and application-related monitoring metrics.
- Continuously evaluate defined CloudWatch alarm conditions.
- Classify actionable incidents according to the approved P1 and P2 scope.
- Trigger automated incident processing when an actionable alarm enters the ALARM state.
- Create a unique incident record identifier for actionable incidents.
- For P1 Apache incidents, initiate automated Apache service recovery.
- Verify the Apache service after recovery.
- Perform a stability recheck before confirming P1 resolution.
- Send a P1 resolution notification when recovery is successful.
- Escalate the P1 incident when recovery or verification fails.
- For P2 CPU incidents, collect system diagnostics such as uptime/load, high CPU processes, and memory information.
- Send the P2 diagnostic report to operations personnel.
- Escalate P2 CPU incidents for manual review.
- Avoid automatic CPU restart, process termination, or destructive remediation.
- Ignore test or unknown alarm names that are outside the approved automation scope.
- Record Lambda execution and automation activity in operational logs.

---

# 6. Non-Functional Requirements

| Category | Requirement |
| -------- | ----------- |
| Availability | Monitoring and incident processing should operate continuously. |
| Reliability | P1 recovery should include service verification and stability verification before resolution. |
| Performance | Incident detection and response should occur within a few minutes under normal operating conditions. |
| Safety | Automated remediation shall be limited to approved P1 Apache recovery actions. |
| Controlled Automation | P2 CPU incidents shall remain diagnostic-only and require manual review. |
| Maintainability | Incident priorities and response behavior should be clearly separated and manageable. |
| Security | AWS IAM permissions should follow the principle of least privilege. |
| Auditability | Incident processing, recovery actions, diagnostic execution, and outcomes should be observable through AWS logs and notifications. |
| Cost Efficiency | The solution should use AWS managed services and avoid unnecessary infrastructure components. |

---

# 7. Stakeholders

| Stakeholder | Responsibility |
| ----------- | -------------- |
| Project Owner | Approves the project and reviews the final deliverables. |
| AWS Administrator | Manages AWS infrastructure, services, and permissions. |
| Operations Engineer | Receives incident notifications and performs manual investigation when required. |
| System Administrator | Maintains the EC2 operating environment and application services. |
| NOC Engineer | Monitors incidents, reviews automated actions, and handles escalated incidents. |

---

# 8. Assumptions

The project assumes the following:

- An active AWS account is available.
- The monitored EC2 environment is operational.
- Required AWS monitoring services are configured.
- CloudWatch Agent is installed and configured where required for metric collection.
- AWS Systems Manager Agent is installed and the EC2 instance is available as a managed node.
- Required IAM permissions are configured.
- Amazon SNS email subscription is confirmed.
- The Apache HTTP Server is installed on the monitored EC2 instance.
- Operations personnel have access to the notification email destination.
- The solution operates within a single AWS Region.
- P1 and P2 are the only approved automated NOC priorities for this project.

---

# 9. Constraints

The following constraints apply to this project:

- The solution operates in a single AWS Region.
- The project focuses on a single EC2 environment.
- Apache HTTP Server is the only application covered by automatic P1 remediation.
- CPU utilization is handled as a diagnostic-only P2 incident.
- No P3 automation is implemented.
- Unknown alarm names are ignored.
- Email is the notification method used for operational communication.
- P2 CPU incidents require human review after automated diagnostics.
- Automatic remediation is intentionally limited to controlled Apache recovery.
- The infrastructure is intended primarily as an internship/project implementation rather than a full enterprise multi-region NOC platform.

---

# 10. Business Benefits

The implemented solution provides the following benefits:

- Faster detection of critical service failures.
- Automatic recovery of Apache service failures.
- Reduced Mean Time to Recovery (MTTR) for P1 incidents.
- Reduced manual intervention for known and safe recovery scenarios.
- Improved visibility into high CPU incidents.
- Structured diagnostic information for operations engineers.
- Controlled separation between automated remediation and manual escalation.
- Reduced risk of inappropriate automatic actions.
- Consistent incident identification and notification.
- Better operational visibility through AWS monitoring and logging.
- Practical demonstration of NOC incident-management principles using AWS services.

---

# 11. Risks and Mitigation

| Risk | Mitigation |
| ---- | ---------- |
| Incorrect IAM permissions | Validate required IAM permissions and follow least-privilege principles. |
| CloudWatch Agent failure | Verify agent health and confirm that expected metrics are being published. |
| Lambda execution failure | Monitor Lambda execution logs and validate the incident-processing workflow. |
| SSM Agent failure | Verify that the SSM Agent is running and that the EC2 instance is registered as a managed node. |
| Alarm misconfiguration | Test alarm conditions and validate the expected incident classification before operational use. |
| Incorrect P1 recovery behavior | Restrict automatic remediation to the approved Apache recovery procedure and perform post-recovery verification. |
| False CPU alerts | Review the CPU alarm threshold and use diagnostic output for manual investigation. |
| Unsafe CPU remediation | Keep P2 CPU automation diagnostic-only with no automatic restart or destructive action. |
| Unknown/test alarm triggering unwanted actions | Apply strict alarm-name classification so unknown alarms are ignored without notification or remediation. |
| Recovery failure | Escalate the P1 incident for manual investigation when Apache cannot be confirmed active and stable. |

---

# 12. Success Criteria

The project will be considered successful when:

- Monitoring metrics are published successfully.
- The Apache monitoring condition can detect an Apache service failure.
- The P1 CloudWatch alarm enters the ALARM state when Apache is unavailable.
- The NOC automation correctly classifies the incident as P1.
- AWS Systems Manager successfully executes the approved Apache recovery action.
- Apache returns to the active state.
- A stability verification confirms that Apache remains active.
- A P1 resolution notification is delivered after successful recovery.
- A failed P1 recovery results in an escalation notification.
- The CPU alarm correctly identifies the `cpu alert` condition as P2.
- The P2 workflow collects CPU diagnostic information successfully.
- The P2 workflow does not perform automatic CPU remediation.
- A P2 diagnostic report is delivered for manual review.
- Unknown/test alarm names are ignored without initiating remediation or notification.
- Incident notifications provide sufficient information for operations personnel to understand and act on the incident.

---

# 13. Expected Business Outcome

After implementation, the organization will have a controlled automated NOC incident-response solution that can distinguish between different operational conditions and apply an appropriate response.

Critical Apache service failures are automatically detected, recovered, and verified where possible. High CPU incidents are detected and investigated automatically through diagnostic collection, while remediation remains under human control.

This approach provides a balance between automation and operational safety, reducing downtime for known service failures while avoiding potentially unsafe automatic actions for resource-related incidents.

---

# 14. Conclusion

The CloudOps NOC Automation project provides a practical AWS-based approach to automated monitoring, incident detection, remediation, diagnosis, and escalation.

The finalized solution is intentionally limited to two operational priorities:

- **P1 – Critical:** Apache HTTP Server failure with controlled automatic recovery and stability verification.
- **P2 – High:** CPU utilization above the defined threshold with automated diagnosis and manual escalation.

By combining AWS monitoring, server-management, serverless automation, and notification capabilities, the project demonstrates how a NOC can reduce operational effort, improve incident response, and maintain controlled automation boundaries.

The solution provides a foundation for future expansion while keeping the current implementation focused, auditable, and appropriate for the project's defined requirements.
