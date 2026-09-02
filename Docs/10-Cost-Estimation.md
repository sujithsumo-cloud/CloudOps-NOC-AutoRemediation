# Document 10 — Cost Estimation

## Project Title

**CloudOps NOC Automation V2.0**

---

## Document Information

| Item | Details |
|---|---|
| Document Name | Cost Estimation |
| Project | CloudOps NOC Automation |
| Version | 2.0 |
| Environment | AWS Cloud |
| Region | `ap-south-1` — Asia Pacific (Mumbai) |
| Estimation Method | AWS Pricing Calculator |
| Status | Current V2.0 Baseline |

---

# 1. Purpose

This document records the cost estimate for CloudOps NOC Automation V2.0 and explains the main cost drivers in the current architecture.

The current incident scope is:

```text
P1 → HTTPD automatic recovery
P2 → CPU diagnostic-only
```

P3 is intentionally excluded.

---

# 2. Current AWS Pricing Calculator Result

The current project estimate generated using the AWS Pricing Calculator is:

| Cost Item | Estimate |
|---|---:|
| Upfront Cost | **USD 0.00** |
| Estimated Monthly Cost | **USD 1.10** |
| Estimated 12-Month Cost | **USD 13.20** |

Calculation:

```text
USD 1.10 × 12 months = USD 13.20
```

This is the primary cost figure for the current project documentation and presentation.

> Actual AWS billing can differ depending on runtime, resource usage, AWS pricing changes, Free Tier eligibility, storage, data transfer, monitoring volume, and other account activity.

---

# 3. Why the Previous USD 11.50 Estimate Was Removed

The previous version manually assigned example monthly values to EC2, EBS, CloudWatch, SNS, and Lambda and calculated approximately:

```text
USD 11.50/month
```

That manually constructed planning figure no longer matches the current project AWS Pricing Calculator result.

For consistency, V2.0 now uses:

```text
AWS Pricing Calculator
        ↓
USD 1.10/month
        ↓
USD 13.20/year
```

as the authoritative project estimate.

---

# 4. Finalized AWS Service Scope

The project uses exactly seven primary AWS services.

| AWS Service | Responsibility | Cost Relevance |
|---|---|---|
| Amazon VPC | Network foundation | Networking usage/features can affect cost |
| Amazon EC2 | Workload host | Major potential compute cost driver |
| Amazon CloudWatch | Metrics, alarms, logs, dashboard | Cost depends on monitoring/log usage |
| AWS Lambda | Decision and orchestration | Cost depends on requests and duration |
| AWS Systems Manager | Controlled EC2 execution and diagnostics | Cost depends on features/usage |
| Amazon SNS | Operational notification delivery | Cost depends on publish/delivery volume |
| AWS IAM | Authorization and access control | Not treated as a variable workload-cost driver here |

Repository references:

- [VPC README](../VPC/README.md)
- [EC2 README](../EC2/README.md)
- [CloudWatch README](../CloudWatch/README.md)
- [Lambda README](../Lambda/README.md)
- [SSM README](../SSM/README.md)
- [SNS README](../SNS/README.md)
- [IAM README](../IAM/README.md)

---

# 5. Supporting Resources vs Primary Services

Some resources support the implementation but are not counted as additional top-level services:

```text
EBS root volume
Internet Gateway
Route Table
Subnet
Security Group
CloudWatch Agent
SSM Agent
CloudWatch Logs capability
CloudWatch Dashboard capability
```

For example:

```text
Amazon EC2
   └── EBS root volume
```

EBS storage can contribute to AWS cost, but it does not change the seven-service project scope.

---

# 6. Current Cost Architecture

```text
EC2 / HTTPD
     │
     ▼
CloudWatch
     │
     ▼
Lambda
     │
  ┌──┴─────────┐
  ▼            ▼
 SSM          SNS
  │            │
  ▼            ▼
 EC2        Engineer
```

The cost is driven by **resource usage**, not simply by the number of services shown in the architecture.

---

# 7. Amazon EC2 Cost Considerations

Current workload:

```text
cloudops-server
Amazon Linux 2023
t3.micro
```

EC2 hosts:

```text
Apache HTTPD
CloudWatch Agent
SSM Agent
```

Potential EC2 cost depends on:

```text
Instance type
Running hours
Region
Pricing model
Free Tier / account eligibility
```

A practical lab optimization is:

> **Stop the EC2 instance when it is not required for testing or demonstrations.**

Operational effect:

```text
EC2 stopped
   ↓
HTTPD and agents stop
   ↓
P1 process metric stops publishing
   ↓
P1 alarm may become INSUFFICIENT_DATA
```

This behavior is expected.

---

# 8. EBS Storage Cost Consideration

The EC2 instance uses a root EBS volume.

```text
EC2
 ↓
EBS Root Volume
```

Storage can still incur cost while the EC2 instance is stopped.

Therefore:

```text
Stopping EC2 ≠ Removing all storage cost
```

Exact storage cost depends on the configured volume and current AWS pricing.

---

# 9. CloudWatch Cost Considerations

CloudWatch is used for:

```text
P1 HTTPD process monitoring
P2 CPU monitoring
Two alarms
Dashboard
Lambda execution logs
Configured CloudWatch Agent metrics
```

P1:

```text
CloudWatch Agent
      ↓
procstat_lookup_pid_count
      ↓
NOC-cloudops-automate
```

P2:

```text
AWS/EC2 CPUUtilization
      ↓
cpu alert
```

Potential CloudWatch cost grows with:

```text
More custom metrics
More alarms
More dashboards
More log ingestion
Longer log retention
More monitored resources
```

Reference:

[Monitoring & Logging Strategy](08-Monitoring-and-Logging-Strategy.md)

---

# 10. P1 Monitoring Cost Model

P1 requires process-level monitoring:

```text
HTTPD
  ↓
CloudWatch Agent
  ↓
procstat
  ↓
procstat_lookup_pid_count
```

The project keeps the canonical agent configuration focused so unnecessary monitoring is not added.

[View CloudWatch Agent configuration](../CloudWatch/cloudwatch-agent-config.json)

---

# 11. P2 Monitoring Cost Model

P2 uses the native EC2 metric:

```text
AWS/EC2
CPUUtilization
```

Current alarm:

```text
cpu alert
```

P2 is **diagnostic-only**.

Correct:

```text
High CPU
   ↓
CloudWatch
   ↓
Lambda
   ↓
SSM Diagnostics
```

It is not an automatic CPU remediation workflow.

---

# 12. Lambda Cost Considerations

Lambda is the decision and orchestration layer.

Current responsibilities:

```text
Receive CloudWatch Alarm event
Parse event["alarmData"]
Validate state
Apply Actionable Alarm Gate
Classify P1 / P2
Call Systems Manager
Process results
Publish SNS notifications
```

Correct trigger path:

```text
CloudWatch Alarm → Lambda
```

Lambda cost depends on request volume, duration, and memory allocation.

The current project has low event volume because Lambda runs only when the incident workflow requires it.

[View Lambda README](../Lambda/README.md)

---

# 13. SNS Cost Considerations

SNS is the notification layer.

Correct:

```text
Lambda → SNS → Engineer
```

SNS can deliver:

```text
P1 recovery started
P1 recovered
P1 failed / escalation
P2 diagnostics started
P2 diagnostic report
```

SNS is **not** used for:

```text
CloudWatch Alarm → Lambda triggering
```

in V2.0.

Potential cost depends on publish/delivery volume and endpoint type.

[View SNS README](../SNS/README.md)

---

# 14. Systems Manager Cost Considerations

Systems Manager is used for:

```text
P1 → HTTPD recovery and verification
P2 → Diagnostic commands
```

Current execution path:

```text
Lambda
  ↓
Boto3
  ↓
SSM SendCommand
  ↓
AWS-RunShellScript
  ↓
SSM Agent
  ↓
EC2
```

The project should not claim that every Systems Manager capability is always free.

> Cost depends on the specific Systems Manager features used and applicable AWS pricing.

The current project uses a small, low-volume Run Command workflow.

[View SSM README](../SSM/README.md)

---

# 15. IAM Cost Consideration

IAM provides:

```text
Roles
Policies
Trust relationships
AWS API authorization
Least privilege
```

IAM is a security/control-plane component and is not treated as a variable workload-cost driver in this estimate.

[View IAM README](../IAM/README.md)

---

# 16. VPC Cost Considerations

Current network:

```text
cloudops-vpc
 ├── cloudops-subnet
 ├── cloudops-rt
 ├── cloudops-igw
 └── cloudops-sg
```

The current design does not implement:

```text
NAT Gateway
Application Load Balancer
Multi-AZ duplicated workload
```

because those are outside the current project scope.

Networking cost can still depend on separately chargeable features and data transfer.

[View VPC README](../VPC/README.md)

---

# 17. Current Cost Estimate Summary

```text
CloudOps NOC Automation V2.0

Upfront Cost
= USD 0.00

Estimated Monthly Cost
= USD 1.10

Estimated 12-Month Cost
= USD 13.20
```

These are the preferred figures for:

```text
GitHub documentation
PPT cost slide
Project discussion
Portfolio explanation
```

---

# 18. Why the Project Is Low Cost

The current design is intentionally small:

```text
One EC2 workload
Two incident alarms
One Lambda function
One SNS topic
Low event volume
Low notification volume
No Multi-AZ
No Load Balancer
No Auto Scaling
No NAT Gateway
No separate monitoring platform
```

The architecture is:

> **requirements-driven and fit-for-purpose**

rather than adding services only to increase complexity.

---

# 19. Cost Optimization Practices

- Stop EC2 when the lab is not required.
- Use an appropriately sized instance.
- Avoid unnecessary CloudWatch custom metrics.
- Avoid unnecessary log ingestion.
- Configure reasonable log retention.
- Remove unused alarms and dashboards.
- Keep Lambda limited to approved incident events.
- Keep SNS notification volume low.
- Remove unused infrastructure.
- Review AWS billing regularly.
- Recalculate when architecture assumptions change.

---

# 20. Cost vs Availability Trade-Off

Current architecture prioritizes:

```text
Learning
Low complexity
Low cost
Clear demonstration
```

rather than maximum production availability.

Example:

```text
Current:
1 EC2 instance

Possible Production:
Multiple EC2 instances + Multi-AZ
```

The production design can improve resilience but increase cost.

---

# 21. Current vs Production Cost

## Current V2.0

```text
Single EC2
Single-AZ
No Load Balancer
No Auto Scaling
Small CloudWatch footprint
Low Lambda volume
Low SNS volume
```

Current calculator estimate:

```text
USD 1.10/month
```

## Possible Production Environment

Could add:

```text
Multiple EC2 instances
Application Load Balancer
Auto Scaling
Multiple Availability Zones
Private subnets
NAT Gateway
More metrics/logs
Backup
Cross-region DR
Higher data transfer
```

These are not included in the current project estimate.

---

# 22. Future Enhancement Cost Direction

| Future Enhancement | Cost Direction |
|---|---|
| Multi-AZ EC2 | Increase |
| Application Load Balancer | Increase |
| Auto Scaling | Depends on capacity |
| NAT Gateway | Increase |
| Additional CloudWatch metrics | Increase |
| More log ingestion/retention | Increase |
| Backup / snapshots | Increase |
| Cross-region DR | Increase |
| More Lambda executions | Increase with usage |
| More SNS notifications | Increase with usage |

Exact values should be recalculated using the AWS Pricing Calculator.

---

# 23. P1 Workflow and Cost

```text
HTTPD
  ↓
CloudWatch Agent
  ↓
CloudWatch Alarm
  ↓
Lambda
  ↓
SSM
  ↓
EC2
  ↓
SNS
```

The workflow is event-driven and does not require a separate always-running automation server.

---

# 24. P2 Workflow and Cost

```text
CPUUtilization
      ↓
CloudWatch Alarm
      ↓
Lambda
      ↓
SSM Diagnostics
      ↓
SNS
```

Diagnostics execute only when needed.

---

# 25. Event-Driven Cost Principle

```text
No actionable incident
        ↓
Incident Lambda workflow is not continuously running
```

When an alarm becomes actionable:

```text
Alarm Event
   ↓
Lambda
   ↓
Workflow
```

This supports operational simplicity and cost control.

---

# 26. Free Tier Consideration

Free Tier eligibility can reduce actual project billing.

However:

> **Free Tier is not a permanent architecture guarantee.**

Eligibility depends on the AWS account, service, usage, and current AWS terms.

Use:

```text
Free Tier may reduce actual billing where applicable.
```

rather than assuming every environment receives the same benefit.

---

# 27. Estimate vs Actual Bill

```text
AWS Pricing Calculator
= Planning estimate

AWS Billing / Cost Management
= Actual incurred charges
```

Differences may result from:

```text
Actual runtime
Storage
Network transfer
Metric volume
Log ingestion
Lambda duration
Notifications
Pricing changes
Free Tier
Taxes
Other account resources
```

---

# 28. Cost Verification Procedure

For review:

1. Open the AWS Pricing Calculator estimate.
2. Verify region: `ap-south-1`.
3. Verify the current resource assumptions.
4. Confirm the estimate summary.
5. Record upfront, monthly, and 12-month values.
6. Update this document if the architecture changes.

Current recorded result:

```text
Upfront   : USD 0.00
Monthly   : USD 1.10
12 Months : USD 13.20
```

---

# 29. When to Recalculate

Recalculate if any of these change:

```text
EC2 instance type
EC2 running schedule
EBS size/type
Number of instances
Region
CloudWatch metrics
CloudWatch alarms
Log volume
Lambda execution volume
SNS volume
Network architecture
Backup architecture
Multi-AZ design
```

---

# 30. Repository Cost References

| Area | Reference |
|---|---|
| Solution architecture | [Solution Architecture](02-Solution-Architecture.md) |
| Deployment assumptions | [Deployment Guide](06-Deployment-Guide.md) |
| Monitoring | [Monitoring Strategy](08-Monitoring-and-Logging-Strategy.md) |
| VPC | [VPC README](../VPC/README.md) |
| EC2 | [EC2 README](../EC2/README.md) |
| CloudWatch | [CloudWatch README](../CloudWatch/README.md) |
| Lambda | [Lambda README](../Lambda/README.md) |
| SSM | [SSM README](../SSM/README.md) |
| SNS | [SNS README](../SNS/README.md) |
| IAM | [IAM README](../IAM/README.md) |

---

# 31. Three-Level Cost Answer

## Level 1

> **The current AWS Pricing Calculator estimate for my V2.0 project is approximately USD 1.10 per month, or USD 13.20 for 12 months.**

## Level 2

> **The architecture is intentionally small: one EC2 workload, two CloudWatch alarms, one Lambda function, one SNS topic, Systems Manager operations, IAM, and a simple VPC. The main variable cost drivers are compute, storage, monitoring/logging, network usage, and event volume.**

## Level 3

> **The calculator result is a planning estimate rather than a guaranteed bill. Actual cost depends on EC2 runtime, EBS storage, CloudWatch custom metrics and log ingestion, Lambda execution duration, SNS delivery volume, data transfer, Free Tier eligibility, and current AWS pricing. Production features such as Multi-AZ, load balancing, Auto Scaling, expanded observability, backup, and disaster recovery would require a new estimate.**

---

# 32. Final Cost Summary

```text
Region
→ ap-south-1

Upfront Cost
→ USD 0.00

Monthly Estimate
→ USD 1.10

12-Month Estimate
→ USD 13.20
```

P1:

```text
HTTPD → CloudWatch → Lambda → SSM → EC2
                           └──→ SNS → Engineer
```

P2:

```text
CPUUtilization → CloudWatch → Lambda → SSM Diagnostics
                                    └──→ SNS → Engineer
```

---

## Key Design Statement

> **The current CloudOps NOC Automation V2.0 AWS Pricing Calculator estimate is USD 1.10 per month and USD 13.20 for 12 months. This represents the current small lab architecture. Production features such as Multi-AZ resources, load balancing, Auto Scaling, expanded observability, centralized backup, and disaster recovery would require a new cost estimate.**
