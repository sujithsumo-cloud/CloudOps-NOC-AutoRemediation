# AWS Systems Manager (SSM) — Controlled EC2 Execution and Diagnostics

## Overview

AWS Systems Manager (SSM) is the **controlled execution and diagnostic layer** of the CloudOps NOC Automation V2.0 project.

The current architecture uses a direct CloudWatch Alarm → Lambda event path:

```text
CloudWatch Alarm
      │
      ▼
Lambda
      │
      ▼
Boto3 / SSM API
      │
      ▼
AWS Systems Manager
      │
      ▼
SSM Agent
      │
      ▼
EC2 Linux
```

SSM does **not** decide whether an incident is P1 or P2.

Lambda makes the decision.  
SSM performs the approved command execution requested by Lambda.

In simple terms:

> **CloudWatch detects. Lambda decides. SSM executes. Linux performs the local service operation.**

---

## 1. Role in the Project

Systems Manager is used to:

- Execute approved Linux commands on the EC2 instance.
- Avoid direct Lambda-to-EC2 SSH access.
- Support P1 HTTPD remediation.
- Support P1 verification and stability checks.
- Support P2 CPU diagnostic collection.
- Return command status and output to Lambda.
- Provide managed-node communication through the SSM Agent.
- Support the project incident counter through Systems Manager Parameter Store.

SSM is the **execution layer**, not the monitoring or decision layer.

---

## 2. Correct V2.0 Architecture

The current project flow is:

```text
CloudWatch
    │
    ▼
Lambda
    │
    ▼
Actionable Alarm Gate
    │
 ┌──┴──┐
 ▼     ▼
P1     P2
 │      │
 ▼      ▼
SSM    SSM
 │      │
Recovery Diagnostics
 │      │
 └──┬───┘
    ▼
   EC2
```

Amazon SNS is **not** between CloudWatch and Lambda.

SNS is used later for operational notifications:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

---

## 3. Systems Manager Components Used

| Component | Responsibility |
|---|---|
| Systems Manager service | Receives and manages command requests |
| Run Command | Executes remote commands on the managed EC2 instance |
| `AWS-RunShellScript` | AWS-managed SSM document used by the current Lambda code |
| SSM Agent | Runs on EC2 and receives/executes SSM instructions |
| Managed Node | The EC2 instance registered with Systems Manager |
| Parameter Store | Maintains the project incident counter |
| IAM | Authorizes Lambda and EC2 SSM interactions |
| Lambda | Requests and coordinates SSM operations |

---

## 4. Managed Node

The EC2 instance must be available to Systems Manager as a **managed node**.

The project EC2 instance runs:

```text
Amazon Linux
Apache HTTPD
CloudWatch Agent
SSM Agent
```

For SSM automation to work, the instance must have:

- SSM Agent installed and running.
- An appropriate EC2 IAM role.
- Network connectivity to the required AWS Systems Manager service endpoints.
- A running EC2 operating system.

Conceptually:

```text
EC2
 │
 ├── Linux
 ├── HTTPD
 └── SSM Agent
        │
        ▼
AWS Systems Manager
```

---

## 5. SSM Agent

The SSM Agent is the software component running on the EC2 instance that enables Systems Manager operations.

Its responsibilities include:

- Maintaining communication with Systems Manager.
- Receiving Run Command instructions.
- Executing approved commands locally.
- Returning command output.
- Returning command execution status.

### Verify SSM Agent

```bash
sudo systemctl status amazon-ssm-agent
```

### Start SSM Agent

```bash
sudo systemctl start amazon-ssm-agent
```

### Enable at Boot

```bash
sudo systemctl enable amazon-ssm-agent
```

### Restart SSM Agent

```bash
sudo systemctl restart amazon-ssm-agent
```

---

## 6. Lambda → Boto3 → SSM API

The Lambda function is written in Python and uses Boto3.

The current Lambda helper calls:

```python
ssm.send_command(...)
```

with:

```text
DocumentName = AWS-RunShellScript
```

and the target EC2 instance ID.

Conceptually:

```text
Lambda Python Code
        │
        ▼
      Boto3
        │
        ▼
 ssm:SendCommand API
        │
        ▼
Systems Manager
```

Lambda then reads command execution status using:

```python
ssm.get_command_invocation(...)
```

This allows Lambda to determine whether the remote command:

- Succeeded
- Failed
- Timed out
- Was cancelled

---

## 7. `AWS-RunShellScript`

The current Lambda implementation uses the AWS-managed Systems Manager document:

```text
AWS-RunShellScript
```

This document allows Systems Manager Run Command to execute Linux shell commands on the managed EC2 instance.

Current runtime path:

```text
Lambda
   │
   ▼
AWS-RunShellScript
   │
   ▼
SSM Agent
   │
   ▼
Linux Shell
```

The repository may also contain custom/reference SSM document files, but the **current Lambda runtime code uses `AWS-RunShellScript`**.

---

## 8. P1 — HTTPD Recovery

P1 is associated with:

```text
Alarm  : NOC-cloudops-automate
Metric : procstat_lookup_pid_count
Rule   : < 1
```

After Lambda validates the alarm through the Actionable Alarm Gate, it requests the P1 recovery command through SSM.

### Recovery command

```bash
systemctl restart httpd
```

Flow:

```text
P1 Alarm
   │
   ▼
Lambda
   │
   ▼
ssm:SendCommand
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
systemctl restart httpd
   │
   ▼
systemd
   │
   ▼
Apache HTTPD
```

Important:

> **SSM provides the remote execution path. Linux `systemd` performs the actual HTTPD service restart.**

---

## 9. P1 Verification

The project does not treat successful command submission as proof of recovery.

After the remediation action, Lambda uses SSM again to run:

```bash
systemctl is-active httpd
```

Expected successful output:

```text
active
```

Verification answers:

> **Did HTTPD recover immediately after the restart?**

Conceptually:

```text
Restart HTTPD
     │
     ▼
SSM Verification Command
     │
     ▼
systemctl is-active httpd
     │
     ▼
active / inactive / failed
```

---

## 10. P1 Stability Verification

Immediate recovery can be temporary.

The current Lambda workflow waits approximately **15 seconds** and performs another service-status check.

```text
Immediate Verification
       │
       ▼
     active
       │
       ▼
 Wait 15 Seconds
       │
       ▼
SSM Stability Check
       │
       ▼
Still active?
```

This confirms **sustained recovery** rather than only immediate recovery.

---

## 11. Bounded Retry

The P1 workflow uses a bounded retry policy.

If the initial recovery attempt is unsuccessful:

```text
Initial Attempt
      │
      ▼
Failed
      │
      ▼
Configured Retry
      │
      ▼
Verify Again
```

If HTTPD still cannot be confirmed healthy, Lambda escalates the incident through SNS.

SSM itself does not decide whether to retry.

> **Lambda controls the retry policy; SSM executes each requested command.**

---

## 12. P2 — CPU Diagnostics

P2 uses:

```text
Alarm  : cpu alert
Metric : CPUUtilization
Rule   : > 50%
```

P2 is **diagnostic-only**.

Lambda requests SSM to collect evidence using commands such as:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

Conceptually:

```text
P2 Alarm
   │
   ▼
Lambda
   │
   ▼
SSM Run Command
   │
   ▼
SSM Agent
   │
   ▼
Linux Diagnostics
   │
   ├── uptime / load
   ├── top CPU consumers
   └── memory information
```

The results are returned to Lambda and later included in the SNS diagnostic notification.

---

## 13. Why P2 Does Not Restart the Server

High CPU is a symptom with multiple possible root causes.

Examples include:

- Legitimate user traffic.
- Application workload.
- Background processing.
- A misbehaving process.
- Resource pressure.

Therefore:

> **Detection does not automatically mean remediation.**

SSM collects evidence for P2, but no automatic HTTPD or EC2 restart is performed.

---

## 14. P1 vs P2 SSM Usage

| Characteristic | P1 — HTTPD | P2 — CPU |
|---|---|---|
| SSM purpose | Remediation + verification | Diagnosis |
| Recovery command | `systemctl restart httpd` | None |
| Verification | `systemctl is-active httpd` | Not a recovery verification |
| Diagnostics | Limited to recovery status | CPU/load/process/memory evidence |
| Automatic corrective action | Yes | No |
| Human involvement | On escalation | Required for final decision |

---

## 15. Systems Manager Parameter Store

The current Lambda code also uses Systems Manager Parameter Store to maintain an incident counter.

The parameter path follows the pattern:

```text
/cloudops/incident-counter/YYYYMMDD
```

Lambda reads the current value with:

```text
ssm:GetParameter
```

and updates it with:

```text
ssm:PutParameter
```

The value is used to generate incident IDs such as:

```text
INC-YYYYMMDD-0001
```

Conceptually:

```text
Lambda
   │
   ▼
Parameter Store
   │
   ▼
Read Counter
   │
   ▼
Increment
   │
   ▼
Write Counter
   │
   ▼
Generate Incident ID
```

This is a secondary SSM capability used by the project in addition to Run Command.

---

## 16. IAM Requirements

There are two major IAM sides to SSM.

### EC2 Instance Role

The EC2 instance requires permissions that allow the SSM Agent to operate as a managed node.

A common AWS-managed policy for this purpose is:

```text
AmazonSSMManagedInstanceCore
```

The instance uses temporary AWS credentials from its IAM role rather than hardcoded access keys.

### Lambda Execution Role

Lambda requires only the SSM actions needed by the workflow.

Relevant operations include:

```text
ssm:SendCommand
ssm:GetCommandInvocation
ssm:GetParameter
ssm:PutParameter
```

Permissions should follow the **Principle of Least Privilege**.

---

## 17. Why SSM Instead of SSH?

The current automation does not require Lambda to directly establish an SSH session with EC2.

### SSH-style design

```text
Lambda
  │
  ▼
SSH
  │
  ▼
Port 22
  │
  ▼
EC2
```

This introduces:

- SSH key management.
- SSH credential handling.
- Direct network connectivity requirements.
- Additional operational configuration.

### SSM design

```text
Lambda
  │
  ▼
AWS API
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

Benefits include:

- IAM-based authorization.
- No Lambda-managed SSH key.
- No direct Lambda-to-EC2 SSH session.
- Central command status and output.
- Cleaner AWS-native integration.

---

## 18. Network Requirements

The SSM Agent must be able to communicate with the required Systems Manager service endpoints.

In the current project, the EC2 instance uses network connectivity that allows the agent to reach AWS services.

Conceptually:

```text
SSM Agent
    │
    ▼
Outbound AWS Connectivity
    │
    ▼
Systems Manager Endpoints
```

A future private-subnet design could use appropriate VPC endpoints where required.

That is a future architecture option, not a required part of the current V2.0 implementation.

---

## 19. SSM Is Not Part of User Web Traffic

The user request path and the SSM management path are different.

### User Traffic

```text
Browser
  │
  ▼
VPC
  │
  ▼
EC2
  │
  ▼
HTTPD
```

### SSM Management

```text
Lambda
  │
  ▼
Systems Manager
  │
  ▼
SSM Agent
  │
  ▼
Linux
```

SSM is used for **operations and management**, not for serving HTTP requests.

---

## 20. SSM vs Lambda Responsibility

### Lambda

```text
Receive
Parse
Validate
Classify
Decide
Coordinate
```

### SSM

```text
Receive approved command request
Execute command
Return status/output
```

Therefore:

> **Lambda decides what should happen. SSM executes what Lambda has approved and requested.**

---

## 21. SSM vs systemd

These also have different responsibilities.

### Systems Manager

Provides remote command execution.

### systemd

Is the Linux service manager that controls `httpd.service`.

For P1:

```text
SSM
  │
  ▼
systemctl restart httpd
  │
  ▼
systemd
  │
  ▼
HTTPD
```

So the most technically accurate answer to:

> **Which service restarts HTTPD?**

is:

> **Systems Manager provides the controlled remote execution path, while Linux systemd performs the actual HTTPD service restart.**

---

## 22. Manual Run Command Test

The SSM execution layer can be tested independently before troubleshooting Lambda.

From the Systems Manager console:

```text
Systems Manager
      │
      ▼
Run Command
      │
      ▼
AWS-RunShellScript
      │
      ▼
Select Managed Node
      │
      ▼
systemctl restart httpd
```

Then verify:

```bash
systemctl is-active httpd
```

Expected output:

```text
active
```

This separates:

```text
SSM execution issue
```

from:

```text
Lambda orchestration issue
```

---

## 23. Verification Commands

### SSM Agent

```bash
sudo systemctl status amazon-ssm-agent --no-pager
```

### SSM Agent version

```bash
amazon-ssm-agent -version
```

### Apache status

```bash
sudo systemctl status httpd --no-pager
```

### Apache active state

```bash
systemctl is-active httpd
```

### SSM Agent logs

```bash
sudo tail -n 50 /var/log/amazon/ssm/amazon-ssm-agent.log
```

---

## 24. Troubleshooting

### EC2 Not Appearing as a Managed Node

Check:

1. EC2 instance is running.
2. SSM Agent is installed and running.
3. EC2 IAM role is attached.
4. Required SSM permissions are available.
5. Outbound connectivity to Systems Manager endpoints exists.
6. Region configuration is correct.

### SSM Command Fails

Check:

1. Managed-node status.
2. Lambda SSM permissions.
3. Command syntax.
4. SSM Agent status.
5. SSM Agent logs.
6. Target instance ID.
7. Linux command permissions.

### HTTPD Does Not Recover

Check:

```bash
sudo systemctl status httpd --no-pager
sudo apachectl configtest
sudo journalctl -u httpd --no-pager -n 50
```

Then test manually if required:

```bash
sudo systemctl restart httpd
```

If manual restart fails too, the issue is likely inside the HTTPD/Linux configuration rather than the SSM transport itself.

---

## 25. Failure Handling

The Lambda helper waits for SSM command execution results.

It checks command states such as:

```text
Success
Failed
TimedOut
Cancelled
```

If SSM does not return a terminal result within the configured waiting loop, the Lambda workflow treats the command as not successfully confirmed.

This distinction is important:

> **Command request accepted does not automatically mean command execution succeeded.**

---

## 26. Security Practices

The SSM implementation follows these principles:

- Use IAM roles rather than static AWS credentials.
- Use least-privilege Lambda permissions.
- Keep SSM Agent operational and updated.
- Restrict Run Command access.
- Avoid direct SSH dependencies for automation.
- Do not hardcode AWS access keys in scripts.
- Validate commands before placing them in an automated workflow.
- Keep remediation commands predefined rather than constructing arbitrary shell commands from alarm text.

This supports **controlled remediation**.

---

## 27. Integration with the Seven AWS Services

| Service | Relationship with SSM |
|---|---|
| VPC | Provides the EC2 network environment |
| EC2 | Hosts Linux, HTTPD, and the SSM Agent |
| IAM | Authorizes SSM interactions |
| CloudWatch | Detects P1/P2 conditions |
| Lambda | Decides and requests SSM operations |
| Systems Manager | Executes recovery/diagnostic commands |
| SNS | Delivers incident results after processing |

Correct end-to-end P1 flow:

```text
HTTPD
  │
  ▼
CloudWatch
  │
  ▼
Lambda
  │
  ▼
SSM
  │
  ▼
SSM Agent
  │
  ▼
systemd / HTTPD
  │
  ▼
Verification
  │
  ▼
SNS
```

---

## 28. Three-Level Interview Answer

### Level 1

> **SSM is the controlled execution layer of my project.**

### Level 2

> **Lambda uses Systems Manager to execute approved commands on the EC2 instance without directly connecting through SSH. For P1, SSM performs HTTPD recovery and verification; for P2, it collects CPU diagnostic evidence.**

### Level 3

> **The Lambda Python code uses Boto3 `ssm.send_command()` with the AWS-managed `AWS-RunShellScript` document and the target EC2 instance ID. The SSM Agent on EC2 receives the Run Command instruction and executes the Linux command. Lambda then uses `ssm.get_command_invocation()` to retrieve the execution status and output. The current code also uses SSM Parameter Store to maintain the daily incident counter.**

---

## 29. Operational Summary

Systems Manager can be remembered as:

```text
RECEIVE REQUEST
      │
      ▼
DELIVER COMMAND
      │
      ▼
EXECUTE ON EC2
      │
      ▼
RETURN STATUS / OUTPUT
```

SSM does not:

- Monitor HTTPD.
- Evaluate CloudWatch alarms.
- Parse alarm events.
- Decide P1 vs P2.
- Determine the retry policy.
- Deliver the final SNS notification.

Those responsibilities belong to CloudWatch, Lambda, and SNS.

---

## 30. Final Summary

AWS Systems Manager is the **controlled remote execution and diagnostic service** in CloudOps NOC Automation V2.0.

P1:

```text
Lambda
  │
  ▼
SSM SendCommand
  │
  ▼
SSM Agent
  │
  ▼
systemctl restart httpd
  │
  ▼
systemd
  │
  ▼
HTTPD
  │
  ▼
Verification + Stability Check
```

P2:

```text
Lambda
  │
  ▼
SSM SendCommand
  │
  ▼
SSM Agent
  │
  ▼
CPU / Load / Process / Memory Diagnostics
  │
  ▼
Lambda
  │
  ▼
SNS
```

---

## Key Design Statement

> **Lambda makes the operational decision; Systems Manager provides the controlled execution path; the SSM Agent executes the requested command on EC2; and Linux systemd performs the actual HTTPD service management.**
