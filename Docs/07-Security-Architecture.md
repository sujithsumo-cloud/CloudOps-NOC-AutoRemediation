# Document 7 — Security Architecture

## Project Title

**CloudOps NOC Automation V2.0**

---

## Document Information

| Item | Details |
|---|---|
| Document Name | Security Architecture |
| Project | CloudOps NOC Automation |
| Version | 2.0 |
| Environment | AWS Cloud |
| Region | `ap-south-1` — Asia Pacific (Mumbai) |
| Status | Current V2.0 Baseline |

---

# 1. Purpose

This document defines the security architecture for CloudOps NOC Automation V2.0.

The security design protects:

- The AWS network and EC2 workload.
- AWS service-to-service API access.
- The automated incident-response workflow.
- EC2 management operations.
- Operational notifications.
- Monitoring and execution logs.
- Credentials and role-based access.

The architecture supports exactly two finalized incident workflows:

| Priority | Incident | Security-Controlled Response |
|---|---|---|
| P1 | Apache HTTPD unavailable | Approved automatic recovery + verification |
| P2 | High CPU utilization | Diagnostic-only + manual review |

The security model is designed around one important principle:

> **Automation must be authorized, limited, verifiable, and safe within the approved workflow.**

---

# 2. Security Objectives

The security architecture is designed to:

- Apply the **Principle of Least Privilege**.
- Use IAM roles instead of long-term AWS access keys.
- Restrict network access with VPC and Security Groups.
- Avoid direct Lambda-to-EC2 SSH automation.
- Use Systems Manager for controlled EC2 command execution.
- Restrict Lambda to approved P1/P2 workflows.
- Prevent unsupported alarms from starting automation.
- Separate P1 remediation from P2 diagnostics.
- Validate recovery instead of assuming command success.
- Protect operational notification paths.
- Maintain troubleshooting and execution visibility.
- Reduce unnecessary exposure of infrastructure identifiers in public documentation.

---

# 3. Security Architecture Overview

```text
                              IAM
                               │
                    Authorization / Roles
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
         VPC                  EC2                Lambda
          │                    │                    │
   Network Controls      Runtime Security      Action Control
          │                    │                    │
          ▼                    ▼                    ▼
   Security Group       CW Agent / SSM Agent   Actionable Gate
                                                    │
                                                    ▼
                                              Approved P1/P2
                                                    │
                                          ┌─────────┴─────────┐
                                          ▼                   ▼
                                         SSM                 SNS
                                          │                   │
                                          ▼                   ▼
                                      EC2 Linux           Engineer
```

The security model uses multiple layers rather than relying on a single control.

---

# 4. Correct V2.0 Event and Notification Paths

The current incident event path is:

```text
CloudWatch Alarm
      │
      ▼
Direct Alarm Event
      │
      ▼
Lambda
```

The notification path is:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

The old path:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

is **not** the current V2.0 design.

This distinction matters for security because:

```text
CloudWatch
= Detection source

Lambda
= Decision / orchestration

SNS
= Notification transport
```

SNS is not the incident-processing trigger for Lambda.

---

# 5. Identity and Access Management (IAM)

IAM provides the authorization model for AWS API operations used by the project.

In simple terms:

> **Which identity or AWS service is allowed to perform which action on which resource?**

The project uses separate runtime roles for:

```text
EC2
Lambda
```

Repository reference:

[View IAM README](../IAM/README.md)

---

# 6. EC2 IAM Role

Current project role:

```text
cloudops-EC2-inline-role
```

The EC2 role supports the AWS permissions required by:

```text
CloudWatch Agent
SSM Agent
```

The instance should use temporary credentials from its IAM role rather than permanent access keys stored on disk.

### Policy Reference

[View EC2 IAM policy](../IAM/cloudops-EC2-inline-role.json)

### Security Purpose

```text
EC2
 │
 ▼
IAM Role
 │
 ├── CloudWatch Agent permissions
 └── SSM Agent permissions
```

The role should contain only the permissions required by the implemented monitoring and management functions.

---

# 7. Lambda Execution Role

Lambda uses a separate execution role.

The current workflow requires permissions for capabilities such as:

```text
SSM Run Command
SSM command-result retrieval
SNS publishing
EC2 read operations
Parameter Store incident counter
CloudWatch Logs
```

### Policy Reference

[View Lambda IAM policy](../IAM/cloudops-lambda-inline-policy.json)

### Security Principle

Lambda does not require broad administrator access.

It should be able to perform only the operations required by:

```text
P1
→ Recovery + verification

P2
→ Diagnostics
```

---

# 8. Trust Policy vs Permission Policy

These are different controls.

## Trust Policy

Answers:

> **Who can assume this role?**

Examples:

```text
EC2 role
→ trusted by EC2 service

Lambda role
→ trusted by Lambda service
```

## Permission Policy

Answers:

> **What can the role do after it is assumed?**

Examples:

```text
ssm:SendCommand
ssm:GetCommandInvocation
sns:Publish
ec2:DescribeInstances
```

Easy memory:

```text
Trust Policy
= WHO can become the role?

Permission Policy
= WHAT can the role do?
```

---

# 9. Principle of Least Privilege

Least privilege means:

> **Grant only the minimum permissions required for the assigned responsibility.**

Examples:

### Lambda

Allowed:

```text
Request approved SSM operations
Read command results
Read required EC2 details
Publish to project SNS topic
Read/write approved incident-counter path
Write execution logs
```

Not required:

```text
Full EC2 administrator access
Unrestricted resource deletion
Broad wildcard administrative access
```

### EC2

Allowed:

```text
CloudWatch Agent communication
SSM Agent communication
Required supporting reads
```

This reduces the potential blast radius of compromised or misused credentials.

---

# 10. Network Security

The network layer is provided by:

```text
cloudops-vpc
```

with:

```text
CIDR: 10.0.0.0/16
```

The EC2 instance is deployed in:

```text
cloudops-subnet
CIDR: 10.0.0.0/28
```

Repository reference:

[View VPC README](../VPC/README.md)

---

# 11. Internet Gateway and Routing

The project uses:

```text
cloudops-igw
cloudops-rt
```

The public subnet route includes:

```text
0.0.0.0/0
      │
      ▼
cloudops-igw
```

Security distinction:

```text
Route Table
= Where can traffic go?

Security Group
= Is the traffic allowed?
```

A valid route does not automatically authorize inbound traffic.

---

# 12. Security Group

Current Security Group:

```text
cloudops-sg
```

Current project intent:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 22 | Trusted administrator IP | Administrative access |
| TCP | 80 | `0.0.0.0/0` | Apache HTTP access |

Port `22` should remain restricted to a trusted administrative source.

The automation workflow itself does not depend on direct SSH access because SSM is used for managed operations.

---

# 13. Defense in Depth

The project applies multiple independent controls.

```text
VPC
 ↓
Network boundary

Security Group
 ↓
Traffic filtering

IAM
 ↓
AWS API authorization

Lambda Actionable Alarm Gate
 ↓
Automation authorization

SSM
 ↓
Controlled remote execution

Verification + Stability Check
 ↓
Operational safety
```

No single layer is treated as the only security control.

---

# 14. EC2 Security

The EC2 workload runs:

```text
Amazon Linux 2023
Apache HTTPD
CloudWatch Agent
SSM Agent
```

The public documentation should avoid exposing unnecessary environment-specific identifiers.

Use:

```text
<INSTANCE_ID>
```

instead of publishing a real EC2 instance ID unless the identifier is intentionally required as evidence.

Repository reference:

[View EC2 README](../EC2/README.md)

---

# 15. Credential Security on EC2

The instance should not store permanent credentials such as:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

The preferred model is:

```text
EC2
 │
 ▼
IAM Role / Instance Profile
 │
 ▼
Temporary AWS Credentials
 │
 ▼
Authorized AWS APIs
```

This reduces credential-leak and manual-rotation risk.

---

# 16. Systems Manager Security

AWS Systems Manager provides the controlled EC2 management path.

Current operational path:

```text
Lambda
   │
   ▼
Boto3
   │
   ▼
SSM API
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2 Linux
```

Repository reference:

[View SSM README](../SSM/README.md)

---

# 17. Why SSM Instead of Direct SSH Automation

The project avoids this automated design:

```text
Lambda
   │
   ▼
SSH Key
   │
   ▼
Port 22
   │
   ▼
EC2
```

The current design uses:

```text
Lambda
   │
   ▼
IAM-Authorized AWS API
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2
```

Security benefits include:

- IAM-based authorization.
- No Lambda-managed SSH private key.
- No direct Lambda-to-EC2 SSH session.
- Central command status and output.
- Controlled AWS-native management path.

---

# 18. P1 Command Security

P1 is associated with:

```text
NOC-cloudops-automate
```

The approved corrective action is:

```bash
systemctl restart httpd
```

The workflow then verifies:

```bash
systemctl is-active httpd
```

Security path:

```text
Approved P1 Alarm
      │
      ▼
Lambda
      │
      ▼
Actionable Alarm Gate
      │
      ▼
SSM
      │
      ▼
Approved Command
      │
      ▼
HTTPD
```

The command should remain predefined rather than being dynamically constructed from untrusted alarm text.

---

# 19. P2 Command Security

P2 is associated with:

```text
cpu alert
```

P2 is intentionally diagnostic-only.

It may collect evidence such as:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

It does not automatically:

```text
Restart arbitrary services
Kill processes
Reboot EC2
Perform destructive remediation
```

This maintains a **human-in-the-loop** decision for an ambiguous operational symptom.

---

# 20. Lambda Security

Lambda is the decision and orchestration layer.

Security controls include:

- IAM execution role.
- No hardcoded AWS credentials.
- Direct CloudWatch Alarm event validation.
- Alarm-state validation.
- Alarm-name allow-listing.
- Separate P1 and P2 workflows.
- Predefined command paths.
- Bounded retry behavior.
- Recovery verification.
- Stability verification.
- CloudWatch Logs visibility.

Repository references:

- [Lambda README](../Lambda/README.md)
- [Lambda source code](../Lambda/lambda_function.py)

---

# 21. Direct CloudWatch Alarm → Lambda Invocation Security

The current invocation path is:

```text
CloudWatch Alarm
      │
      ▼
Lambda
```

The Lambda function should have the required resource-based invocation permission for the configured CloudWatch alarm integration.

Verification should confirm that:

- The intended CloudWatch alarm can invoke the Lambda function.
- Unsupported sources are not unintentionally granted broad invocation access.
- The Lambda Actionable Alarm Gate still validates the received alarm identity and state.

The two controls serve different purposes:

```text
Lambda Resource-Based Permission
= Who may invoke the function?

Actionable Alarm Gate
= Which received alarm is allowed to start an operational workflow?
```

---

# 22. Actionable Alarm Gate

The Actionable Alarm Gate is an application-level automation safety control.

Current approved alarms:

| Alarm | Priority | Allowed Workflow |
|---|---|---|
| `NOC-cloudops-automate` | P1 | HTTPD recovery |
| `cpu alert` | P2 | CPU diagnostics |
| Unknown/Test | Unsupported | Ignore |

Conceptually:

```text
Incoming Alarm
      │
      ▼
State = ALARM?
   /        \
 NO         YES
 │           │
 ▼           ▼
Ignore    Approved Alarm?
           /        \
         NO          YES
         │            │
         ▼            ▼
       Ignore       Continue
```

The gate is not a replacement for IAM.

It is an additional automation guardrail.

---

# 23. CloudWatch Security

Amazon CloudWatch is responsible for monitoring and alarm evaluation.

P1:

```text
CloudWatch Agent
      │
      ▼
procstat_lookup_pid_count
      │
      ▼
NOC-cloudops-automate
```

P2:

```text
AWS/EC2
CPUUtilization
      │
      ▼
cpu alert
```

CloudWatch detects the condition.

It does not execute remediation commands.

Repository reference:

[View CloudWatch README](../CloudWatch/README.md)

---

# 24. CloudWatch Agent Security

The CloudWatch Agent runs as a system service on EC2.

The canonical repository configuration is:

[View CloudWatch Agent configuration](../CloudWatch/cloudwatch-agent-config.json)

The deployment script is:

[View CloudWatch Agent configuration script](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

Security controls include:

- EC2 IAM role-based AWS access.
- No embedded permanent AWS access keys.
- Local configuration protected by Linux file permissions.
- Only the required monitoring configuration enabled.
- Agent communication with AWS endpoints through authenticated AWS service requests.

For the finalized P1 requirement, the important process-monitoring configuration is:

```text
httpd
  │
  ▼
procstat pid_count
  │
  ▼
procstat_lookup_pid_count
```

---

# 25. SNS Security

Current SNS topic:

```text
cloudops-sns
```

SNS is used for **operational notification delivery**.

Correct path:

```text
Lambda
   │
   ▼
sns:Publish
   │
   ▼
cloudops-sns
   │
   ▼
Confirmed Subscriber
```

Security controls include:

- IAM-controlled `sns:Publish`.
- Restricted topic access.
- Confirmed subscriptions.
- HTTPS/TLS-backed AWS API communication.
- Avoiding sensitive secrets in notification content.

Repository reference:

[View SNS README](../SNS/README.md)

---

# 26. SNS Is Not the Lambda Trigger

This is a key V2.0 correction.

Incorrect old description:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

Correct:

```text
CloudWatch
   │
   ▼
Lambda
   │
   ▼
SNS
```

Therefore:

> **SNS provides notification delivery after Lambda processing; it is not the downstream Lambda trigger for the current incident workflow.**

---

# 27. Logging and Operational Auditability

The project uses operational logs to investigate failures and validate automation behavior.

Important sources include:

| Component | Log / Evidence Source |
|---|---|
| Lambda | CloudWatch Logs |
| Systems Manager | Run Command result/status |
| SSM Agent | `/var/log/amazon/ssm/` |
| CloudWatch Agent | `/opt/aws/amazon-cloudwatch-agent/logs/` |
| Linux | `/var/log/messages` |
| Apache | Apache access/error logs where configured |

Lambda execution logging can provide evidence for:

```text
Alarm parsing
Alarm identification
Incident classification
Incident ID
SSM Command ID
SSM execution status
P1 verification
P1 stability result
P2 diagnostics
SNS notification result
Final workflow state
```

---

# 28. CloudWatch Logs vs CloudTrail

CloudWatch Logs is part of the current CloudWatch observability implementation.

CloudTrail is **not** part of the finalized seven-service implementation baseline.

Conceptually:

```text
CloudWatch Logs
= Application / execution / operational logs

CloudTrail
= AWS API activity auditing
```

CloudTrail may be considered as a future governance enhancement, but it should not be documented as currently implemented unless explicitly added to the project.

---

# 29. Credential Management

The project should not contain permanent AWS credentials in:

```text
Lambda source code
Shell scripts
CloudWatch Agent config
GitHub files
Apache files
Documentation
```

Preferred model:

```text
AWS Service
   │
   ▼
IAM Role
   │
   ▼
Temporary Credentials
```

Secrets, tokens, passwords, and private keys should not be committed to the public repository.

---

# 30. Public Repository Security

Because the project repository is public, documentation should avoid unnecessary exposure of:

```text
AWS Account IDs
Real EC2 Instance IDs
Private IP addresses
Email addresses
Access keys
Secret keys
Session tokens
SSH private keys
Sensitive ARNs
```

Use placeholders where possible:

```text
<AWS_ACCOUNT_ID>
<INSTANCE_ID>
<PRIVATE_IP>
<SNS_TOPIC_ARN>
<LAMBDA_ARN>
```

Resource names such as:

```text
NOC-cloudops-automate
cpu alert
cloudops-sns
cloudops-vpc
```

can remain because they are part of the project design and do not provide credentials.

---

# 31. Automation Security

Automation is treated as a security-sensitive capability.

P1:

```text
NOC-cloudops-automate
        │
        ▼
Actionable Alarm Gate
        │
        ▼
P1
        │
        ▼
SSM
        │
        ▼
Restart HTTPD
        │
        ▼
Verify
        │
        ▼
Stability Check
```

P2:

```text
cpu alert
    │
    ▼
Actionable Alarm Gate
    │
    ▼
P2
    │
    ▼
SSM Diagnostics
    │
    ▼
Manual Review
```

This reduces the chance that an unsupported alarm causes an unintended operational action.

---

# 32. Bounded Retry Security

Unlimited retries can create:

```text
Repeated disruption
Resource waste
Automation loops
Hidden persistent failure
```

The P1 workflow therefore uses bounded retry behavior.

Conceptually:

```text
Attempt
  │
  ▼
Failed?
 /    \
No    Yes
│      │
▼      ▼
Done  Limited Retry
          │
          ▼
       Still Failed?
          │
          ▼
       Escalate
```

The goal is controlled recovery, not endless automation.

---

# 33. Verification as a Security and Reliability Control

Command execution alone is not treated as successful recovery.

After remediation:

```bash
systemctl is-active httpd
```

is used to validate the service.

Then the workflow performs a stability recheck.

This helps prevent:

```text
Command accepted
      ↓
Assumed success
```

from being confused with:

```text
Service actually healthy
```

---

# 34. Security Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Unauthorized AWS API access | IAM roles + least privilege |
| Hardcoded credentials | Role-based temporary credentials |
| Broad SSH exposure | Restrict port 22 to trusted source |
| Lambda acts on unsupported alarm | Actionable Alarm Gate |
| Broad SSM command capability | Predefined commands + IAM scoping |
| P1 remediation fails | Verification + bounded retry + escalation |
| P2 unsafe automatic action | Diagnostic-only workflow |
| SNS unauthorized publishing | Scoped `sns:Publish` |
| Lambda invocation from unintended source | Resource-based invocation control + alarm validation |
| Missing execution visibility | CloudWatch Logs + SSM command results |
| Public repository leaks identifiers | Use placeholders and secret review |
| Unlimited automation loop | Bounded retry policy |

---

# 35. Security-Controlled Operational Flow

```text
CloudWatch Metric
       │
       ▼
CloudWatch Alarm
       │
       ▼
Direct Alarm Event
       │
       ▼
Lambda
       │
       ▼
Alarm Parsing
       │
       ▼
Actionable Alarm Gate
       │
  ┌────┴──────────────┐
  ▼                   ▼
Supported          Unsupported
  │                   │
  ▼                   ▼
P1 / P2              Ignore
  │
  ├──── P1 ───► SSM Recovery ───► Verify ───► Stability
  │
  └──── P2 ───► SSM Diagnostics ─────────────► Manual Review
  │
  ▼
Lambda determines result
  │
  ▼
SNS
  │
  ▼
Engineer
```

Every AWS API step still depends on IAM authorization.

---

# 36. Security Verification Checklist

| Security Control | Verification |
|---|---|
| EC2 IAM role attached | Verify |
| Lambda execution role attached | Verify |
| No permanent AWS credentials committed | Verify |
| SSH restricted to trusted source | Verify |
| HTTP exposure limited to project requirement | Verify |
| SSM Agent online | Verify |
| EC2 visible as SSM managed node | Verify |
| Lambda `ssm:SendCommand` scoped appropriately | Verify |
| Lambda `sns:Publish` scoped appropriately | Verify |
| Direct CloudWatch Alarm → Lambda configured | Verify |
| Lambda invocation permission restricted appropriately | Verify |
| `event["alarmData"]` parsing active | Verify |
| Actionable Alarm Gate implemented | Verify |
| Unknown alarms ignored | Verify |
| P1 recovery command predefined | Verify |
| P1 verification implemented | Verify |
| P1 stability check implemented | Verify |
| P1 retry bounded | Verify |
| P2 diagnostic-only | Verify |
| SNS subscription confirmed | Verify |
| CloudWatch/Lambda logs available | Verify |
| Public docs use placeholders for unnecessary identifiers | Verify |

---

# 37. Repository Security References

| Area | Repository Reference |
|---|---|
| IAM architecture | [IAM README](../IAM/README.md) |
| EC2 IAM policy | [EC2 IAM policy](../IAM/cloudops-EC2-inline-role.json) |
| Lambda IAM policy | [Lambda IAM policy](../IAM/cloudops-lambda-inline-policy.json) |
| VPC security | [VPC README](../VPC/README.md) |
| EC2 security | [EC2 README](../EC2/README.md) |
| Lambda security | [Lambda README](../Lambda/README.md) |
| Lambda implementation | [Lambda source](../Lambda/lambda_function.py) |
| SSM security | [SSM README](../SSM/README.md) |
| SNS security | [SNS README](../SNS/README.md) |
| CloudWatch security | [CloudWatch README](../CloudWatch/README.md) |
| P1 alarm | [P1 alarm](../CloudWatch/NOC-cloudops-automate.md) |
| P2 alarm | [P2 alarm](../CloudWatch/cpu%20alert.md) |
| Deployment | [Deployment Guide](06-Deployment-Guide.md) |

---

# 38. Three-Level Security Answer

## Level 1

> **The project uses layered security with VPC and Security Groups for network control, IAM for authorization, SSM for controlled EC2 management, and an Actionable Alarm Gate to restrict automation to approved incidents.**

## Level 2

> **EC2 and Lambda use separate IAM roles with least-privilege permissions. CloudWatch sends alarm events directly to Lambda, Lambda validates the event and approved alarm name, and only then can it request predefined SSM operations. P1 allows controlled HTTPD recovery, while P2 is restricted to diagnostics. SNS is used only to deliver operational notifications.**

## Level 3

> **The security model combines network controls, role-based temporary credentials, scoped AWS API permissions, Lambda invocation control, alarm allow-listing, predefined SSM Run Command actions, bounded retry, recovery verification, stability validation, and downstream SNS notification. Lambda does not directly SSH into EC2; SSM Agent receives approved commands through Systems Manager, and Linux systemd performs the actual HTTPD service management.**

---

# 39. Final Security Summary

```text
VPC
= Network boundary

Security Group
= Traffic control

IAM
= AWS authorization

CloudWatch
= Detection

Lambda
= Validation + decision

Actionable Alarm Gate
= Automation guardrail

SSM
= Controlled execution

systemd
= Linux service management

Verification
= Confirm recovery

SNS
= Notify engineer
```

---

## Key Design Statement

> **Security is enforced at multiple layers. Network access is restricted by VPC and Security Groups, AWS API access is authorized through IAM roles, Lambda validates the alarm before any action is allowed, Systems Manager provides controlled EC2 execution, P1 recovery is verified and bounded, P2 remains diagnostic-only, and SNS delivers the operational result after processing rather than triggering Lambda.**
