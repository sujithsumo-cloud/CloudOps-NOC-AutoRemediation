# Amazon EC2 — Workload Hosting, Linux Runtime, and Managed Operations

## Overview

Amazon EC2 is the **compute and workload-hosting layer** of the CloudOps NOC Automation V2.0 project.

The EC2 instance hosts the Apache HTTPD web server and runs the supporting agents required for monitoring and controlled operations:

```text
Amazon EC2
   │
   ├── Amazon Linux
   ├── Apache HTTPD
   ├── CloudWatch Agent
   └── SSM Agent
```

The EC2 instance is the workload being monitored and the target on which approved recovery or diagnostic commands are executed.

In simple terms:

> **EC2 hosts the workload. CloudWatch observes it. Lambda decides. SSM manages it.**

---

## 1. Role in the Project

EC2 is responsible for:

- Hosting the Linux operating system.
- Running Apache HTTPD.
- Serving web requests.
- Running the CloudWatch Agent.
- Running the SSM Agent.
- Exposing process and operating-system state for monitoring.
- Receiving approved Systems Manager commands.
- Providing application and operating-system logs.
- Acting as the P1 remediation target.
- Acting as the P2 diagnostic target.

EC2 itself does **not** decide when remediation should happen.

---

## 2. Current EC2 Project Configuration

| Property | Project Configuration |
|---|---|
| Instance Name | `cloudops-server` |
| Operating System | Amazon Linux 2023 |
| Instance Type | `t3.micro` |
| Architecture | x86_64 |
| Region | `ap-south-1` |
| Availability Zone | `ap-south-1a` |
| IAM Role | `cloudops-EC2-inline-role` |
| Security Group | `cloudops-sg` |
| VPC | `cloudops-vpc` |
| Subnet | `cloudops-subnet` |
| Web Server | Apache HTTP Server (`httpd`) |

---

## 3. Correct V2.0 Architecture

The current project architecture is:

```text
                         IAM
                          │
                          ▼
                         EC2
                          │
                   Apache HTTPD
                          │
                  CloudWatch Agent
                          │
                          ▼
                     CloudWatch
                          │
                     Alarm Event
                          │
                          ▼
                       Lambda
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
               SSM                 SNS
                │                   │
                ▼                   ▼
               EC2               Engineer
```

Important:

> **SNS is not between CloudWatch and Lambda in the current V2.0 architecture.**

Correct:

```text
CloudWatch → Lambda → SSM → EC2
                    └────→ SNS
```

Not:

```text
CloudWatch → SNS → Lambda
```

---

## 4. EC2 as the Workload Host

The EC2 instance provides the runtime environment for:

```text
Amazon Linux
    │
    ▼
Apache HTTPD
    │
    ▼
Web Workload
```

HTTPD is the primary P1 workload monitored by the project.

The Linux operating system provides:

- Process management.
- CPU scheduling.
- Memory management.
- File systems.
- Networking.
- Service management through `systemd`.

---

## 5. Apache HTTPD

Apache HTTPD is the web server used in the project.

### Service name

```text
httpd
```

### Common commands

Check status:

```bash
systemctl status httpd
```

Start:

```bash
systemctl start httpd
```

Stop:

```bash
systemctl stop httpd
```

Restart:

```bash
systemctl restart httpd
```

Enable at boot:

```bash
systemctl enable httpd
```

Check processes:

```bash
pgrep -a httpd
```

Check HTTP port:

```bash
ss -lntp | grep :80
```

---

## 6. Linux `systemd` and HTTPD

Linux uses `systemd` as the service manager.

Conceptually:

```text
systemctl restart httpd
        │
        ▼
      systemd
        │
        ▼
   httpd.service
        │
        ▼
 Apache HTTPD Processes
```

Important responsibility distinction:

```text
SSM
= provides remote command execution

systemctl
= sends the local service-management request

systemd
= performs the actual service management
```

Therefore, the most accurate explanation is:

> **Systems Manager provides the controlled execution path, while Linux systemd performs the actual HTTPD restart.**

---

## 7. HTTPD Processes and PIDs

When Apache runs, Linux can maintain:

```text
HTTPD Parent Process
      │
      ├── Worker Process
      ├── Worker Process
      └── Worker Process
```

Each process has a PID.

Multiple HTTPD PIDs can exist even when there are no active users because Apache can keep worker processes ready for future requests.

Therefore:

> **PID count is not user count.**

and:

> **PID count is not request count.**

The project uses process count as a process-presence signal for P1.

---

## 8. CloudWatch Agent

The CloudWatch Agent runs on EC2 and collects configured operating-system, process, network, and log data.

Conceptually:

```text
EC2 Linux
    │
    ▼
CloudWatch Agent
    │
    ▼
Amazon CloudWatch
```

The project uses a 60-second collection interval for the configured agent metrics.

The agent supports visibility into areas such as:

- Memory
- Disk
- Network
- HTTPD process count
- Selected Apache/Linux logs

---

## 9. P1 HTTPD Process Monitoring

The P1 monitoring path is:

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
CloudWatch
  │
  ▼
NOC-cloudops-automate
```

The current P1 alarm evaluates:

```text
procstat_lookup_pid_count < 1
```

When no matching HTTPD process is present, the alarm can transition to `ALARM`.

---

## 10. P1 Correct End-to-End Flow

The finalized P1 path is:

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
CloudWatch Alarm Event
     │
     ▼
Lambda
     │
     ▼
Actionable Alarm Gate
     │
     ▼
SSM Run Command
     │
     ▼
SSM Agent
     │
     ▼
EC2 Linux
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
SNS Notification / Escalation
```

SNS is used **after incident processing**, not as the Lambda trigger.

---

## 11. SSM Agent

The SSM Agent runs on the EC2 instance and enables controlled Systems Manager operations.

### Check status

```bash
systemctl status amazon-ssm-agent
```

Start:

```bash
systemctl start amazon-ssm-agent
```

Restart:

```bash
systemctl restart amazon-ssm-agent
```

Enable at boot:

```bash
systemctl enable amazon-ssm-agent
```

For automated management to work, the EC2 instance must remain available as an SSM managed node.

---

## 12. Why SSM Instead of Direct SSH

The automation does not require Lambda to establish an SSH session with EC2.

Current path:

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
EC2 Linux
```

This avoids making the incident workflow depend on:

- Lambda-managed SSH keys.
- Direct Lambda-to-EC2 SSH sessions.
- Port 22 for automated remediation.

The workflow uses IAM-controlled AWS APIs instead.

---

## 13. P1 Remediation

For P1, Lambda requests:

```bash
systemctl restart httpd
```

through Systems Manager.

The EC2 instance receives the command through the SSM Agent.

```text
Lambda
   │
   ▼
SSM
   │
   ▼
SSM Agent
   │
   ▼
EC2
   │
   ▼
systemctl restart httpd
```

EC2 is the execution target.

It does not determine whether the action is allowed.

That decision belongs to Lambda.

---

## 14. P1 Verification and Stability

After the restart, the project verifies:

```bash
systemctl is-active httpd
```

Immediate verification asks:

> **Did HTTPD recover now?**

The stability check asks:

> **Did HTTPD remain healthy after the initial recovery?**

The current workflow performs the stability recheck after approximately 15 seconds.

If required, the current P1 workflow allows one automatic retry before escalation.

---

## 15. P2 — CPU Diagnostics

The P2 alarm is:

```text
cpu alert
```

using:

```text
AWS/EC2
CPUUtilization
```

P2 is **diagnostic-only**.

The workflow is:

```text
EC2
 │
 ▼
CPUUtilization
 │
 ▼
CloudWatch
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
EC2 Diagnostics
 │
 ▼
SNS
 │
 ▼
Engineer
```

There is no automatic HTTPD restart or EC2 reboot for P2.

---

## 16. P2 Diagnostic Commands

Systems Manager collects evidence from the EC2 operating system.

Examples include:

```bash
uptime
ps aux --sort=-%cpu | head -11
free -h
```

These help identify:

- System load.
- Top CPU-consuming processes.
- Memory state.

High CPU can have multiple root causes, so human review remains part of the P2 workflow.

---

## 17. P1 vs P2 on EC2

| Characteristic | P1 — HTTPD | P2 — CPU |
|---|---|---|
| EC2 role | Recovery target | Diagnostic target |
| Detection signal | HTTPD process count | CPUUtilization |
| Automatic corrective action | Yes | No |
| SSM command type | Restart + verify | Diagnostics |
| Final decision | Automated unless escalation required | Engineer review |

Core principle:

> **Detection does not automatically mean remediation.**

---

## 18. IAM Integration

The EC2 instance uses an IAM role for the AWS permissions required by the monitoring and management components.

Conceptually:

```text
EC2
 │
 ▼
IAM Role
 │
 ▼
Temporary AWS Credentials
 │
 ▼
Authorized AWS Service Access
```

The design avoids storing permanent AWS access keys on the instance.

The project follows the **Principle of Least Privilege**.

---

## 19. VPC Integration

The EC2 instance is deployed inside:

```text
cloudops-vpc
      │
      ▼
cloudops-subnet
      │
      ▼
cloudops-server
```

The associated Security Group is:

```text
cloudops-sg
```

The VPC provides the network environment.

The Security Group controls permitted network traffic to and from the instance.

---

## 20. User Request Network Flow

A simplified user request path is:

```text
Browser
   │
   ▼
Internet
   │
   ▼
Internet Gateway
   │
   ▼
VPC Routing
   │
   ▼
Security Group
   │
   ▼
EC2 ENI
   │
   ▼
ens5
   │
   ▼
Linux Kernel
   │
   ▼
TCP :80
   │
   ▼
Socket
   │
   ▼
HTTPD
```

This is the user/data path.

It is different from the monitoring and management path.

---

## 21. Monitoring Flow vs Management Flow

### Monitoring

```text
HTTPD / Linux
      │
      ▼
CloudWatch Agent
      │
      ▼
CloudWatch
```

### Management

```text
Lambda
  │
  ▼
SSM
  │
  ▼
SSM Agent
  │
  ▼
Linux
```

### User Traffic

```text
Browser
  │
  ▼
Network
  │
  ▼
HTTPD
```

These flows should not be mixed together.

---

## 22. Logs and Troubleshooting

### Apache logs

Common path:

```text
/var/log/httpd/
```

Useful files include:

```text
access_log
error_log
```

### SSM Agent logs

```text
/var/log/amazon/ssm/
```

### CloudWatch Agent logs

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

### Linux messages

```text
/var/log/messages
```

These logs help separate:

- Application problems.
- Agent problems.
- Linux problems.
- Automation transport problems.

---

## 23. Basic EC2 Health Checks

Check uptime:

```bash
uptime
```

Check CPU/processes:

```bash
top
```

Check memory:

```bash
free -h
```

Check disk:

```bash
df -h
```

Check network listeners:

```bash
ss -lntp
```

Check HTTPD:

```bash
systemctl status httpd
```

Check CloudWatch Agent:

```bash
systemctl status amazon-cloudwatch-agent
```

Check SSM Agent:

```bash
systemctl status amazon-ssm-agent
```

Test HTTP locally:

```bash
curl http://localhost
```

---

## 24. Operational Dependencies

| Dependency | Required For |
|---|---|
| VPC | EC2 network environment |
| Security Group | Network traffic control |
| IAM Role | AWS authorization |
| CloudWatch Agent | P1 process-level monitoring |
| CloudWatch | Alarm detection |
| Lambda | Incident decision and orchestration |
| SSM Agent | Managed command execution |
| SNS | Operational notification |

Important:

> **SNS is a notification dependency, not an alarm-event distribution layer to Lambda in the current V2.0 architecture.**

---

## 25. Security Practices

The EC2 implementation follows these practices:

- IAM role-based AWS access.
- No hardcoded permanent AWS credentials.
- Security Group network filtering.
- Systems Manager-based managed operations.
- Limited administrative access.
- CloudWatch monitoring and logging.
- Separation of decision logic from command execution.

---

## 26. Three-Level Interview Answer

### Level 1

> **EC2 is the compute layer that hosts my Linux and Apache HTTPD workload.**

### Level 2

> **The EC2 instance runs Amazon Linux, Apache HTTPD, the CloudWatch Agent, and the SSM Agent. It is both the workload monitored by CloudWatch and the managed target on which Systems Manager executes P1 recovery or P2 diagnostic commands.**

### Level 3

> **Inside EC2, Linux systemd manages `httpd.service`, while the kernel manages the HTTPD processes, PIDs, memory, CPU, and networking. The CloudWatch Agent publishes the configured HTTPD process metric used by the P1 alarm, while the SSM Agent receives Systems Manager Run Command instructions. Lambda does not directly log in to EC2; it requests approved operations through SSM.**

---

## 27. EC2 Responsibility Summary

```text
                    EC2
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
     Workload     Monitoring   Management
     HTTPD        CW Agent     SSM Agent
```

EC2 provides the actual runtime environment.

It does not:

- Evaluate alarms.
- Decide P1 or P2.
- Apply the Actionable Alarm Gate.
- Determine escalation.
- Deliver SNS notifications.

---

## 28. Final Summary

Amazon EC2 is the **central workload host and managed execution target** of CloudOps NOC Automation V2.0.

The finalized P1 path is:

```text
EC2 / HTTPD
     │
     ▼
CloudWatch Agent
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
EC2 / HTTPD
     │
     ▼
Verification
     │
     ▼
SNS
```

The finalized P2 path is:

```text
EC2 CPUUtilization
        │
        ▼
CloudWatch
        │
        ▼
Lambda
        │
        ▼
SSM Diagnostics
        │
        ▼
SNS
        │
        ▼
Engineer
```

---

## Key Design Statement

> **EC2 hosts the workload and runs the monitoring and management agents. CloudWatch detects operational conditions, Lambda decides what action is allowed, Systems Manager executes approved commands on EC2, and SNS communicates the result.**
