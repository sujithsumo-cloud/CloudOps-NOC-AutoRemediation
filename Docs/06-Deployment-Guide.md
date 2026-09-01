# CloudOps NOC Automation V2.0 — Deployment Guide (SOP)

> **Document 6 — Deployment Guide**  
> **Project:** CloudOps NOC Automation V2.0  
> **Region:** `ap-south-1` — Asia Pacific (Mumbai)  
> **Deployment style:** AWS Console + repository scripts/configuration  
> **Lambda deployment:** AWS Lambda Console editor

---

# 1. Purpose

This document is the **central deployment and implementation reference** for the CloudOps NOC Automation V2.0 project.

It explains:

- What must be deployed.
- In what order each component is deployed.
- Which commands are important.
- Which repository script performs the operation.
- Which configuration/code file is the source reference.
- How to verify each deployment step.
- How to test the P1 and P2 incident workflows.

The guide intentionally keeps the **important commands visible** while linking to the **complete implementation files**.

Example:

```text
Deployment Guide
      │
      ├── Shows important command
      │
      └── Links to full repository implementation
```

This allows a reviewer to understand the workflow without duplicating every script inside the document.

---

# 2. Final V2.0 Architecture

The current event-driven incident path is:

```text
EC2 / HTTPD
     │
     ▼
CloudWatch
     │
     ▼
CloudWatch Alarm Event
     │
     ▼
Lambda
     │
  ┌──┴─────────────┐
  ▼                ▼
 SSM              SNS
  │                │
  ▼                ▼
 EC2            Engineer
```

For P1:

```text
HTTPD Failure
     │
     ▼
CloudWatch Agent
     │
     ▼
procstat_lookup_pid_count
     │
     ▼
NOC-cloudops-automate
     │
     ▼
Lambda
     │
     ▼
SSM
     │
     ▼
systemctl restart httpd
     │
     ▼
Verification
     │
     ▼
Stability Check
     │
     ▼
SNS
```

For P2:

```text
EC2 CPUUtilization
       │
       ▼
    cpu alert
       │
       ▼
     Lambda
       │
       ▼
      SSM
       │
       ▼
CPU / Load / Process / Memory Diagnostics
       │
       ▼
      SNS
       │
       ▼
Engineer Review
```

> **Important:** SNS does **not** trigger Lambda in the current V2.0 architecture. CloudWatch sends the alarm event directly to Lambda.

---

# 3. Finalized AWS Service Scope

The project uses exactly seven primary AWS services.

| Service | Responsibility | Repository Reference |
|---|---|---|
| Amazon VPC | Network foundation | [VPC README](../VPC/README.md) |
| Amazon EC2 | Linux + HTTPD workload host | [EC2 README](../EC2/README.md) |
| Amazon CloudWatch | Monitoring and incident detection | [CloudWatch README](../CloudWatch/README.md) |
| AWS Lambda | Decision and orchestration | [Lambda README](../Lambda/README.md) |
| AWS Systems Manager | Controlled EC2 execution and diagnostics | [SSM README](../SSM/README.md) |
| Amazon SNS | Operational notification delivery | [SNS README](../SNS/README.md) |
| AWS IAM | Authorization and least privilege | [IAM README](../IAM/README.md) |

Supporting components:

```text
Apache HTTPD
CloudWatch Agent
SSM Agent
Linux systemd
Boto3
```

---

# 4. Incident Scope

| Priority | Incident | Response |
|---|---|---|
| P1 | Apache HTTPD unavailable | Automatic recovery + verification + stability check |
| P2 | High EC2 CPU utilization | Diagnostic-only + engineer review |

P3 is intentionally excluded from the V2.0 scope.

P1 alarm:

```text
NOC-cloudops-automate
```

P2 alarm:

```text
cpu alert
```

References:

- [P1 — `NOC-cloudops-automate`](../CloudWatch/NOC-cloudops-automate.md)
- [P2 — `cpu alert`](../CloudWatch/cpu%20alert.md)

---

# 5. Repository Implementation Map

The repository is organized so the deployment guide can link directly to implementation evidence.

```text
CloudOps-NOC-AutoRemediation/
│
├── Docs/
│   └── 06-Deployment-Guide.md
│
├── Scripts/
│   ├── Installation/
│   │   ├── 01-install-apache.sh
│   │   ├── 02-install-cloudwatch-agent.sh
│   │   └── 03-install-ssm-agent.sh
│   │
│   ├── Configuration/
│   │   ├── 01-configure-cloudwatch-agent.sh
│   │   └── 02-enable-services.sh
│   │
│   ├── Operations/
│   │   ├── restart-httpd.sh
│   │   ├── start-httpd.sh
│   │   └── stop-httpd.sh
│   │
│   ├── Verification/
│   │   ├── health-check.sh
│   │   ├── verify-aws-agents.sh
│   │   └── verify-services.sh
│   │
│   └── Diagnostics/
│       ├── collect-logs.sh
│       ├── system-information.sh
│       └── troubleshoot.sh
│
├── Lambda/
│   └── lambda_function.py
│
├── IAM/
│   ├── cloudops-EC2-inline-role.json
│   └── cloudops-lambda-inline-policy.json
│
├── CloudWatch/
│   ├── NOC-cloudops-automate.md
│   ├── cpu alert.md
│   ├── Alarm configuration.md
│   └── loudwatch-agent-config.json
│
├── SSM/
│   ├── restart-httpd-document.json
│   ├── run-command.md
│   ├── ssm-agent.md
│   └── ssm-troubleshooting.md
│
└── apache/
    ├── index.html
    └── apache-troubleshooting.md
```

Full scripts index:

[View `Scripts/README.md`](../Scripts/README.md)

---

# 6. Deployment Method

The project intentionally uses a mixed deployment approach.

## AWS Console

Use the AWS Console for:

```text
VPC
Subnet
Route Table
Internet Gateway
Security Group
IAM
EC2
CloudWatch Alarms
CloudWatch Dashboard
SNS
Lambda
```

## EC2 Repository Scripts

Use the repository scripts for:

```text
Apache installation
CloudWatch Agent installation
SSM Agent verification/installation
CloudWatch Agent configuration
Linux service enablement
Operational testing
Health verification
Diagnostics
```

## Lambda

Use the **AWS Lambda Console editor** to edit, deploy, and test:

[View `Lambda/lambda_function.py`](../Lambda/lambda_function.py)

---

# 7. Deployment Sequence

Recommended order:

```text
1.  VPC
2.  Subnet
3.  Internet Gateway
4.  Route Table
5.  Security Group
6.  EC2 IAM Role
7.  EC2 Instance
8.  Repository / scripts on EC2
9.  Apache HTTPD
10. SSM Agent
11. CloudWatch Agent
12. CloudWatch Agent configuration
13. Service verification
14. CloudWatch metrics/log verification
15. CloudWatch Dashboard
16. P1 Alarm
17. P2 Alarm
18. SNS Topic + Subscription
19. Lambda IAM Role
20. Lambda Function
21. Direct CloudWatch Alarm → Lambda actions
22. P1 test
23. P2 test
24. Final verification
```

---

# 8. Step 1 — Create the VPC

Create:

```text
Name : cloudops-vpc
CIDR : 10.0.0.0/16
```

### Repository Reference

[View VPC implementation details](../VPC/README.md)

### Expected Result

```text
cloudops-vpc
10.0.0.0/16
```

is available.

---

# 9. Step 2 — Create the Public Subnet

Create:

```text
Name : cloudops-subnet
CIDR : 10.0.0.0/28
AZ   : ap-south-1a
```

The subnet is public because the associated route table provides a default route to the Internet Gateway.

### Repository Reference

[View VPC subnet design](../VPC/README.md)

---

# 10. Step 3 — Create the Internet Gateway

Create:

```text
cloudops-igw
```

Attach it to:

```text
cloudops-vpc
```

### Repository Reference

[View Internet Gateway design](../VPC/README.md)

---

# 11. Step 4 — Create the Route Table

Create:

```text
cloudops-rt
```

Important routes:

| Destination | Target |
|---|---|
| `10.0.0.0/16` | Local |
| `0.0.0.0/0` | `cloudops-igw` |

Associate it with:

```text
cloudops-subnet
```

### Repository Reference

[View route-table design](../VPC/README.md)

---

# 12. Step 5 — Create the Security Group

Create:

```text
cloudops-sg
```

Current project intent:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 22 | Trusted administrator IP | Administrative access |
| TCP | 80 | `0.0.0.0/0` | Apache HTTP access |

### Important Concept

```text
Route Table
= Where should traffic go?

Security Group
= Is the traffic allowed?
```

### Repository Reference

[View Security Group / VPC details](../VPC/README.md)

---

# 13. Step 6 — Create the EC2 IAM Role

Current role:

```text
cloudops-EC2-inline-role
```

This role provides the permissions required by:

```text
CloudWatch Agent
SSM Agent
```

### Policy Reference

[View EC2 IAM policy](../IAM/cloudops-EC2-inline-role.json)

### IAM Documentation

[View IAM README](../IAM/README.md)

### Expected Result

The role is available and can be attached to `cloudops-server`.

---

# 14. Step 7 — Launch the EC2 Instance

Current project configuration:

```text
Name          : cloudops-server
OS            : Amazon Linux 2023
Instance Type : t3.micro
VPC           : cloudops-vpc
Subnet        : cloudops-subnet
Security Group: cloudops-sg
IAM Role      : cloudops-EC2-inline-role
Region        : ap-south-1
```

### Repository Reference

[View EC2 implementation details](../EC2/README.md)

### Expected Result

The instance is:

```text
RUNNING
```

inside the correct VPC/subnet.

---

# 15. Step 8 — Get the Repository on EC2

If the repository is not already available on the server:

```bash
git clone https://github.com/sujithsumo-cloud/CloudOps-NOC-AutoRemediation.git
cd CloudOps-NOC-AutoRemediation
```

Make the shell scripts executable:

```bash
chmod +x Scripts/Installation/*.sh
chmod +x Scripts/Configuration/*.sh
chmod +x Scripts/Operations/*.sh
chmod +x Scripts/Verification/*.sh
chmod +x Scripts/Diagnostics/*.sh
```

### Repository Reference

[View all scripts](../Scripts/README.md)

---

# 16. Step 9 — Install Apache HTTPD

## Purpose

Apache HTTPD is the project workload used for the P1 service-availability scenario.

## Main Commands

The installation script performs the equivalent of:

```bash
dnf install -y httpd
systemctl enable httpd
systemctl start httpd
systemctl is-active httpd
```

## Run the Repository Script

```bash
sudo bash Scripts/Installation/01-install-apache.sh
```

## Script Reference

[View `01-install-apache.sh`](../Scripts/Installation/01-install-apache.sh)

## Apache Web Page

The repository contains the project web page:

[View `apache/index.html`](../apache/index.html)

If the repository has been cloned onto EC2, copy it into Apache's document root:

```bash
sudo cp apache/index.html /var/www/html/index.html
```

## Verification

```bash
systemctl is-active httpd
curl http://localhost
```

Expected:

```text
active
```

and a valid HTTP response.

## Additional Reference

[Apache documentation and troubleshooting](../apache/readme.md)

[Apache troubleshooting guide](../apache/apache-troubleshooting.md)

---

# 17. Step 10 — Install / Verify the SSM Agent

The project uses the SSM Agent to receive Systems Manager Run Command instructions.

The installation script first checks whether the agent already exists.

## Main Commands

```bash
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl is-active amazon-ssm-agent
```

## Run the Repository Script

```bash
sudo bash Scripts/Installation/03-install-ssm-agent.sh
```

## Script Reference

[View `03-install-ssm-agent.sh`](../Scripts/Installation/03-install-ssm-agent.sh)

## SSM References

- [SSM README](../SSM/README.md)
- [SSM Agent guide](../SSM/ssm-agent.md)
- [Run Command guide](../SSM/run-command.md)
- [SSM troubleshooting](../SSM/ssm-troubleshooting.md)

## Verification

```bash
systemctl is-active amazon-ssm-agent
```

Then confirm the EC2 instance appears as a Systems Manager managed node.

---

# 18. Step 11 — Install the CloudWatch Agent

## Purpose

The CloudWatch Agent provides the process-level monitoring required for P1 and can provide additional operating-system/log visibility.

## Main Command

The repository script installs the package when required:

```bash
dnf install -y amazon-cloudwatch-agent
```

## Run the Repository Script

```bash
sudo bash Scripts/Installation/02-install-cloudwatch-agent.sh
```

## Script Reference

[View `02-install-cloudwatch-agent.sh`](../Scripts/Installation/02-install-cloudwatch-agent.sh)

## Verification

```bash
sudo systemctl status amazon-cloudwatch-agent --no-pager
```

---

# 19. Step 12 — Configure the CloudWatch Agent

## Current Repository Configuration Script

Run:

```bash
sudo bash Scripts/Configuration/01-configure-cloudwatch-agent.sh
```

### Script Reference

[View `01-configure-cloudwatch-agent.sh`](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

The current script creates:

```text
/opt/aws/amazon-cloudwatch-agent/etc/p1-p2-final.json
```

and configures:

```text
Namespace                : CWAgent
Collection interval      : 60 seconds
HTTPD lookup             : httpd
HTTPD measurement        : pid_count
Generated P1 metric      : procstat_lookup_pid_count
CPU agent measurements   : cpu_usage_idle / user / system
```

The script then loads the configuration with:

```bash
amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/p1-p2-final.json \
  -s
```

## Expanded Repository Agent Configuration

The CloudWatch folder also currently contains a larger JSON configuration with memory, disk, `ens5` network, procstat, and selected Apache/Linux log collection:

[View current CloudWatch Agent JSON](../CloudWatch/loudwatch-agent-config.json)

### Repository Consistency Note

At the moment, these two repository artifacts are **not identical**:

```text
Scripts/Configuration/01-configure-cloudwatch-agent.sh
```

creates a focused CPU + HTTPD procstat configuration, while:

```text
CloudWatch/loudwatch-agent-config.json
```

contains the expanded metrics/log configuration.

For the final repository baseline, these should be synchronized so there is one clear source of truth.

Until that cleanup is completed, use the deployment script as the reference for what the current script actually configures, and use the CloudWatch JSON as the reference for the expanded stored configuration.

---

# 20. Step 13 — Enable and Start Required Linux Services

The project requires:

```text
httpd
amazon-cloudwatch-agent
amazon-ssm-agent
```

Run:

```bash
sudo bash Scripts/Configuration/02-enable-services.sh
```

### Script Reference

[View `02-enable-services.sh`](../Scripts/Configuration/02-enable-services.sh)

The script:

```text
Checks service files
      ↓
Enables services
      ↓
Starts services
      ↓
Verifies active/enabled state
```

---

# 21. Step 14 — Verify Linux Services

## Full Service Verification

Run:

```bash
sudo bash Scripts/Verification/verify-services.sh
```

Reference:

[View `verify-services.sh`](../Scripts/Verification/verify-services.sh)

This verifies:

```text
httpd
amazon-cloudwatch-agent
amazon-ssm-agent
```

## AWS Agent Verification

Run:

```bash
sudo bash Scripts/Verification/verify-aws-agents.sh
```

Reference:

[View `verify-aws-agents.sh`](../Scripts/Verification/verify-aws-agents.sh)

## EC2 Health Check

Run:

```bash
sudo bash Scripts/Verification/health-check.sh
```

Reference:

[View `health-check.sh`](../Scripts/Verification/health-check.sh)

The health-check script includes checks such as:

```text
Hostname
Uptime
CPU load
Memory
Filesystem
HTTPD health
```

---

# 22. Step 15 — Verify CloudWatch Data

In the CloudWatch Console, verify the required monitoring data.

## P1

Check namespace:

```text
CWAgent
```

Check:

```text
procstat_lookup_pid_count
```

The P1 signal should represent matching HTTPD process presence.

## P2

Check the native EC2 metric:

```text
AWS/EC2
CPUUtilization
```

### CloudWatch Reference

[View CloudWatch README](../CloudWatch/README.md)

### Alarm Configuration Reference

[View `Alarm configuration.md`](../CloudWatch/Alarm%20configuration.md)

---

# 23. Step 16 — Create / Verify the CloudWatch Dashboard

Current dashboard:

```text
cloudops-NOC-dashboard
```

Use the dashboard for monitoring visibility.

Recommended project visibility includes the relevant:

```text
CPU
HTTPD process count
Memory
Disk
Network
```

depending on the active CloudWatch Agent configuration.

### Reference

[View CloudWatch README](../CloudWatch/README.md)

---

# 24. Step 17 — Configure the P1 Alarm

Current P1 alarm:

```text
Alarm Name : NOC-cloudops-automate
Metric     : procstat_lookup_pid_count
Condition  : < 1
Priority   : P1
```

### P1 Documentation

[View `NOC-cloudops-automate.md`](../CloudWatch/NOC-cloudops-automate.md)

### Detection Path

```text
HTTPD
  │
  ▼
CloudWatch Agent
  │
  ▼
procstat
  │
  ▼
procstat_lookup_pid_count
  │
  ▼
NOC-cloudops-automate
```

At this stage the alarm can be created before Lambda, then its Lambda action can be configured after the function exists.

---

# 25. Step 18 — Configure the P2 Alarm

Current P2 alarm:

```text
Alarm Name : cpu alert
Namespace  : AWS/EC2
Metric     : CPUUtilization
Threshold  : > 50%
Priority   : P2
```

### P2 Documentation

[View `cpu alert.md`](../CloudWatch/cpu%20alert.md)

### Important

P2 is:

```text
DIAGNOSTIC-ONLY
```

It does not automatically:

```text
Restart HTTPD
Reboot EC2
Kill a process
Perform destructive remediation
```

---

# 26. Step 19 — Create the SNS Topic

Current topic:

```text
Topic Name   : cloudops-sns
Display Name : NOC-topic
```

Create the required subscription and confirm it.

### SNS Reference

[View SNS README](../SNS/README.md)

### Correct SNS Role

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

SNS is the notification transport.

It is not the CloudWatch-to-Lambda trigger.

---

# 27. Step 20 — Create the Lambda IAM Role / Policy

The Lambda execution role must allow only the operations required by the workflow.

Current project policy reference:

[View `cloudops-lambda-inline-policy.json`](../IAM/cloudops-lambda-inline-policy.json)

Relevant capabilities include:

```text
ssm:SendCommand
ssm:GetCommandInvocation
ssm:GetParameter
ssm:PutParameter
ec2:DescribeInstances
sns:Publish
CloudWatch Logs write permissions
```

### IAM Reference

[View IAM README](../IAM/README.md)

---

# 28. Step 21 — Create and Deploy Lambda

Current function:

```text
Cloudops-NOC-automate
```

Use the **AWS Lambda Console editor**.

### Source Code

[View `lambda_function.py`](../Lambda/lambda_function.py)

### Lambda Documentation

[View Lambda README](../Lambda/README.md)

### Current Logic

```text
CloudWatch Alarm Event
       │
       ▼
event["alarmData"]
       │
       ▼
Alarm Parser
       │
       ▼
State Validation
       │
       ▼
Actionable Alarm Gate
       │
    ┌──┴──┐
    ▼     ▼
   P1     P2
```

### Current Approved Alarms

```text
P1 : NOC-cloudops-automate
P2 : cpu alert
```

### Environment Configuration

Configure the SNS topic ARN according to the current Lambda implementation:

```text
TOPIC_ARN
```

and verify any other environment values required by the current code.

---

# 29. Step 22 — Configure Direct CloudWatch Alarm → Lambda Actions

This is a critical V2.0 step.

Correct:

```text
NOC-cloudops-automate ─────┐
                           ├──► Cloudops-NOC-automate
cpu alert ──────────────────┘
```

Incorrect old design:

```text
CloudWatch → SNS → Lambda
```

The current design is:

```text
CloudWatch → Lambda
```

After processing:

```text
Lambda → SNS
```

Verify Lambda's resource-based invocation permission is configured for the CloudWatch alarm action.

---

# 30. Step 23 — Verify SSM Run Command Path

The Lambda code uses Boto3 to call Systems Manager.

Conceptually:

```text
Lambda
   │
   ▼
Boto3
   │
   ▼
ssm.send_command()
   │
   ▼
AWS-RunShellScript
   │
   ▼
SSM Agent
   │
   ▼
Linux
```

### SSM References

- [SSM README](../SSM/README.md)
- [Run Command guide](../SSM/run-command.md)
- [SSM Agent guide](../SSM/ssm-agent.md)

The repository also contains:

[View `restart-httpd-document.json`](../SSM/restart-httpd-document.json)

### Runtime Note

The current Lambda runtime code uses the AWS-managed:

```text
AWS-RunShellScript
```

document.

---

# 31. Step 24 — P1 Controlled Failure Test

## Purpose

Validate the full automatic HTTPD recovery path.

## Pre-check

```bash
systemctl is-active httpd
```

Expected:

```text
active
```

## Failure Injection Command

```bash
systemctl stop httpd
```

### Repository Operation Script

Run:

```bash
sudo bash Scripts/Operations/stop-httpd.sh
```

Reference:

[View `stop-httpd.sh`](../Scripts/Operations/stop-httpd.sh)

## Expected Flow

```text
HTTPD Stops
    │
    ▼
Matching HTTPD PIDs disappear
    │
    ▼
CloudWatch Agent publishes process metric
    │
    ▼
NOC-cloudops-automate = ALARM
    │
    ▼
Lambda invoked directly
    │
    ▼
Actionable Alarm Gate accepts P1
    │
    ▼
SSM SendCommand
    │
    ▼
systemctl restart httpd
    │
    ▼
Verification
    │
    ▼
Stability Check
    │
    ▼
SNS Notification
```

---

# 32. P1 Recovery Command Reference

The core P1 recovery command is:

```bash
systemctl restart httpd
```

A manual equivalent is available in:

[View `restart-httpd.sh`](../Scripts/Operations/restart-httpd.sh)

The script:

```text
Checks current HTTPD state
      ↓
Restarts HTTPD
      ↓
Verifies HTTPD
```

### Important

The Lambda function does not execute this local script file directly.

The Lambda implementation requests the equivalent approved Linux command through SSM Run Command.

---

# 33. P1 Verification

The automation verifies:

```bash
systemctl is-active httpd
```

Expected:

```text
active
```

The current P1 workflow also includes:

```text
One bounded retry when required
15-second stability recheck
```

### Manual Verification References

- [Service verification](../Scripts/Verification/verify-services.sh)
- [EC2 health check](../Scripts/Verification/health-check.sh)

---

# 34. P1 Successful Outcome

Expected:

```text
Detected
   ↓
Recovering
   ↓
Recovered
   ↓
Verified
   ↓
Stable
   ↓
Resolved
   ↓
SNS Notification
```

Verify:

```bash
systemctl is-active httpd
```

and:

```bash
curl http://localhost
```

---

# 35. P1 Failed Outcome

If HTTPD cannot remain healthy after the configured recovery attempts:

```text
Recovery Failed
      │
      ▼
Lambda Decides to Escalate
      │
      ▼
SNS
      │
      ▼
Engineer
```

SNS delivers the notification; Lambda makes the escalation decision.

---

# 36. Step 25 — P2 Controlled CPU Test

## Purpose

Validate the diagnostic-only P2 workflow.

A simple lab command can generate CPU load:

```bash
yes > /dev/null &
```

Check:

```bash
pgrep -a yes
```

Stop after testing:

```bash
pkill yes
```

> A single `yes` process may not be enough to cross the configured alarm threshold on every instance/vCPU configuration. Perform only controlled lab testing.

## Expected Flow

```text
CPU Increases
    │
    ▼
CPUUtilization
    │
    ▼
cpu alert
    │
    ▼
Lambda
    │
    ▼
P2 Diagnosis
    │
    ▼
SSM
    │
    ▼
Diagnostic Commands
    │
    ▼
SNS
    │
    ▼
Engineer Review
```

---

# 37. P2 Diagnostic Commands

The current Lambda code collects evidence using commands equivalent to:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

Purpose:

| Command | Information |
|---|---|
| `uptime` | System uptime and load averages |
| `ps aux --sort=-%cpu | head -11` | Highest CPU-consuming processes |
| `free -h` | Memory state |

### Repository Diagnostic Scripts

For additional host-level diagnosis:

- [View `system-information.sh`](../Scripts/Diagnostics/system-information.sh)
- [View `collect-logs.sh`](../Scripts/Diagnostics/collect-logs.sh)
- [View `troubleshoot.sh`](../Scripts/Diagnostics/troubleshoot.sh)

These scripts are operational troubleshooting tools and are not automatically executed by the P2 Lambda path unless explicitly implemented.

---

# 38. P2 Expected Outcome

Expected:

```text
Detected
   ↓
Diagnosing
   ↓
Diagnostic Evidence Collected
   ↓
SNS Report
   ↓
Manual Review
```

No automatic HTTPD restart or EC2 reboot should occur.

---

# 39. Operations Script Reference

## Start HTTPD

Command:

```bash
systemctl start httpd
```

Repository:

[View `start-httpd.sh`](../Scripts/Operations/start-httpd.sh)

## Stop HTTPD

Command:

```bash
systemctl stop httpd
```

Repository:

[View `stop-httpd.sh`](../Scripts/Operations/stop-httpd.sh)

## Restart HTTPD

Command:

```bash
systemctl restart httpd
```

Repository:

[View `restart-httpd.sh`](../Scripts/Operations/restart-httpd.sh)

---

# 40. Verification Script Reference

## Verify All Required Services

```bash
sudo bash Scripts/Verification/verify-services.sh
```

[View `verify-services.sh`](../Scripts/Verification/verify-services.sh)

## Verify AWS Agents

```bash
sudo bash Scripts/Verification/verify-aws-agents.sh
```

[View `verify-aws-agents.sh`](../Scripts/Verification/verify-aws-agents.sh)

## EC2 Health Check

```bash
sudo bash Scripts/Verification/health-check.sh
```

[View `health-check.sh`](../Scripts/Verification/health-check.sh)

---

# 41. Diagnostic Script Reference

## System Information

```bash
sudo bash Scripts/Diagnostics/system-information.sh
```

[View `system-information.sh`](../Scripts/Diagnostics/system-information.sh)

## Collect Logs

```bash
sudo bash Scripts/Diagnostics/collect-logs.sh
```

[View `collect-logs.sh`](../Scripts/Diagnostics/collect-logs.sh)

## Troubleshooting

```bash
sudo bash Scripts/Diagnostics/troubleshoot.sh
```

[View `troubleshoot.sh`](../Scripts/Diagnostics/troubleshoot.sh)

---

# 42. Final Deployment Verification Checklist

| Verification | Expected Result | Reference |
|---|---|---|
| VPC exists | `cloudops-vpc` | [VPC](../VPC/README.md) |
| Public subnet exists | `cloudops-subnet` | [VPC](../VPC/README.md) |
| Internet Gateway attached | `cloudops-igw` | [VPC](../VPC/README.md) |
| Route table configured | `cloudops-rt` | [VPC](../VPC/README.md) |
| Security Group attached | `cloudops-sg` | [VPC](../VPC/README.md) |
| EC2 running | `cloudops-server` | [EC2](../EC2/README.md) |
| HTTPD active | `active` | [Apache install script](../Scripts/Installation/01-install-apache.sh) |
| SSM Agent active | `active` | [SSM install script](../Scripts/Installation/03-install-ssm-agent.sh) |
| CloudWatch Agent active | `active` | [CW install script](../Scripts/Installation/02-install-cloudwatch-agent.sh) |
| HTTPD procstat metric visible | `procstat_lookup_pid_count` | [CloudWatch](../CloudWatch/README.md) |
| P1 alarm configured | `NOC-cloudops-automate` | [P1 doc](../CloudWatch/NOC-cloudops-automate.md) |
| P2 alarm configured | `cpu alert` | [P2 doc](../CloudWatch/cpu%20alert.md) |
| SNS topic configured | `cloudops-sns` | [SNS](../SNS/README.md) |
| Lambda deployed | `Cloudops-NOC-automate` | [Lambda code](../Lambda/lambda_function.py) |
| CloudWatch invokes Lambda directly | Confirmed | [Lambda](../Lambda/README.md) |
| P1 auto-remediation tested | Successful | [P1 doc](../CloudWatch/NOC-cloudops-automate.md) |
| P2 diagnostic workflow tested | Successful | [P2 doc](../CloudWatch/cpu%20alert.md) |
| SNS notifications received | Confirmed | [SNS](../SNS/README.md) |

---

# 43. Troubleshooting Navigation

Use this approach:

```text
Problem
  │
  ▼
Identify Layer
  │
  ├── Network
  ├── EC2/Linux
  ├── Monitoring
  ├── Lambda
  ├── SSM
  ├── IAM
  └── SNS
```

## Website Not Reachable

Check:

```bash
systemctl is-active httpd
ss -lntp | grep :80
curl http://localhost
```

References:

- [VPC README](../VPC/README.md)
- [EC2 README](../EC2/README.md)
- [Apache troubleshooting](../apache/apache-troubleshooting.md)

## CloudWatch Metric Missing

Check:

```bash
systemctl is-active amazon-cloudwatch-agent
```

References:

- [CloudWatch README](../CloudWatch/README.md)
- [CloudWatch Agent install script](../Scripts/Installation/02-install-cloudwatch-agent.sh)
- [CloudWatch Agent config script](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

## Lambda Not Invoked

Check:

```text
CloudWatch alarm state
Alarm action
Lambda resource-based invocation permission
Direct event format
event["alarmData"]
```

References:

- [Lambda README](../Lambda/README.md)
- [Lambda source](../Lambda/lambda_function.py)
- [CloudWatch README](../CloudWatch/README.md)

Do **not** troubleshoot an SNS → Lambda subscription for the current V2.0 path.

## SSM Command Fails

Check:

```bash
systemctl is-active amazon-ssm-agent
```

References:

- [SSM troubleshooting](../SSM/ssm-troubleshooting.md)
- [SSM README](../SSM/README.md)
- [IAM Lambda policy](../IAM/cloudops-lambda-inline-policy.json)

## SNS Notification Missing

Check:

```text
TOPIC_ARN
sns:Publish
Subscription confirmed
Lambda logs
```

Reference:

[View SNS README](../SNS/README.md)

---

# 44. Important Responsibility Separation

```text
VPC
= Network foundation

EC2
= Workload host

CloudWatch
= Monitor + Detect

Lambda
= Parse + Validate + Decide + Orchestrate

SSM
= Controlled remote execution

systemd
= Actual Linux service management

SNS
= Notification delivery

IAM
= Authorization
```

For the common review question:

> **Which service restarts HTTPD?**

Use:

> **Lambda decides and requests the recovery through Systems Manager. Systems Manager provides the controlled remote execution path, while Linux systemd performs the actual HTTPD service restart through `systemctl restart httpd`.**

---

# 45. Repository Review Navigation

If a reviewer asks **“Where is the implementation?”**, use this map.

### Apache Installation

[Scripts/Installation/01-install-apache.sh](../Scripts/Installation/01-install-apache.sh)

### CloudWatch Agent Installation

[Scripts/Installation/02-install-cloudwatch-agent.sh](../Scripts/Installation/02-install-cloudwatch-agent.sh)

### SSM Agent Installation

[Scripts/Installation/03-install-ssm-agent.sh](../Scripts/Installation/03-install-ssm-agent.sh)

### CloudWatch Agent Configuration

[Scripts/Configuration/01-configure-cloudwatch-agent.sh](../Scripts/Configuration/01-configure-cloudwatch-agent.sh)

### Linux Service Enablement

[Scripts/Configuration/02-enable-services.sh](../Scripts/Configuration/02-enable-services.sh)

### Lambda Logic

[Lambda/lambda_function.py](../Lambda/lambda_function.py)

### EC2 IAM Policy

[IAM/cloudops-EC2-inline-role.json](../IAM/cloudops-EC2-inline-role.json)

### Lambda IAM Policy

[IAM/cloudops-lambda-inline-policy.json](../IAM/cloudops-lambda-inline-policy.json)

### P1 Alarm

[CloudWatch/NOC-cloudops-automate.md](../CloudWatch/NOC-cloudops-automate.md)

### P2 Alarm

[CloudWatch/cpu alert.md](../CloudWatch/cpu%20alert.md)

### SSM Run Command

[SSM/run-command.md](../SSM/run-command.md)

### P1 Manual Stop Test

[Scripts/Operations/stop-httpd.sh](../Scripts/Operations/stop-httpd.sh)

### HTTPD Recovery Command

[Scripts/Operations/restart-httpd.sh](../Scripts/Operations/restart-httpd.sh)

### Service Verification

[Scripts/Verification/verify-services.sh](../Scripts/Verification/verify-services.sh)

### AWS Agent Verification

[Scripts/Verification/verify-aws-agents.sh](../Scripts/Verification/verify-aws-agents.sh)

### Host Health

[Scripts/Verification/health-check.sh](../Scripts/Verification/health-check.sh)

### Troubleshooting

[Scripts/Diagnostics/troubleshoot.sh](../Scripts/Diagnostics/troubleshoot.sh)

---

# 46. Current Repository Cleanup Note

Two filename/content consistency items should still be cleaned before calling the repository fully finalized:

```text
CloudWatch/loudwatch-agent-config.json
```

has a filename typo (`loudwatch` instead of `cloudwatch`), and:

```text
CloudWatch/cpu alert.md
```

contains a space.

Recommended future names:

```text
CloudWatch/cloudwatch-agent-config.json
CloudWatch/cpu-alert.md
```

After those files are renamed, update the relative links in this deployment guide.

There is also currently a configuration difference between:

```text
Scripts/Configuration/01-configure-cloudwatch-agent.sh
```

and:

```text
CloudWatch/loudwatch-agent-config.json
```

The final repository should choose one canonical CloudWatch Agent configuration and keep both artifacts synchronized.

---

# 47. Final End-to-End Deployment Outcome

After deployment:

```text
User
 │
 ▼
VPC
 │
 ▼
EC2 / HTTPD
 │
 ├─────────────── User Traffic
 │
 ▼
CloudWatch Agent / CPUUtilization
 │
 ▼
CloudWatch
 │
 ▼
Alarm Event
 │
 ▼
Lambda
 │
 ├──────────────► SSM ─────► EC2 / Linux
 │
 └──────────────► SNS ─────► Engineer
```

P1:

```text
Detect
  ↓
Validate
  ↓
Remediate
  ↓
Verify
  ↓
Stability Check
  ↓
Resolve / Escalate
```

P2:

```text
Detect
  ↓
Validate
  ↓
Diagnose
  ↓
Collect Evidence
  ↓
Notify
  ↓
Engineer Decision
```

---

# 48. Key Design Statement

> **The deployment is traceable from documentation to implementation. Each major operational step shows the important command and links directly to the corresponding repository script, configuration, policy, Lambda code, or service document. CloudWatch detects incidents, Lambda decides the approved workflow, Systems Manager executes controlled EC2 operations, Linux systemd manages HTTPD, SNS communicates the result, and IAM authorizes the AWS interactions.**
