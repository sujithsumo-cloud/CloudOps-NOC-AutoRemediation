# Amazon EC2 – Configuration & Operations

## Project

**CloudOps NOC Automation**

## Service

**Amazon Elastic Compute Cloud (EC2)**

---

# 1. Overview

Amazon EC2 provides the compute environment for the CloudOps NOC Automation project.

The EC2 instance hosts the Apache HTTP Server and provides the target environment for monitoring and automated remediation. The instance is integrated with Amazon CloudWatch, AWS Systems Manager (SSM), IAM, SNS, and Lambda to implement the NOC incident-response workflow.

The EC2 instance is therefore the primary workload resource monitored and managed by the automation system.

---

# 2. Purpose

The EC2 instance is responsible for:

- Hosting the Apache HTTP Server.
- Serving HTTP requests.
- Running the CloudWatch Agent.
- Running the SSM Agent.
- Publishing monitoring metrics through the CloudWatch Agent.
- Receiving automated remediation commands through Systems Manager.
- Providing the target environment for Lambda-driven recovery.
- Generating operating-system and application logs for troubleshooting.

---

# 3. EC2 Configuration

| Property | Project Configuration |
| --- | --- |
| Instance Name | `cloudops-server` |
| Instance ID | `i-0b7d483631875bb1c` |
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

# 4. EC2 Role in the NOC Architecture

EC2 is the monitored workload in the project.

The relationship between the services is:

```text
                 IAM
                  |
                  | Permissions
                  v
VPC ---------> EC2 Server
                  |
             Apache httpd
                  |
          CloudWatch Agent
                  |
                  v
             CloudWatch
                  |
              Alarm
                  |
                  v
                 SNS
                  |
                  v
               Lambda
                  |
                  v
                 SSM
                  |
                  v
             EC2 / httpd
```

The EC2 instance is therefore both:

- The **application hosting environment**
- The **target of automated remediation**

---

# 5. Operating System

The server runs:

```text
Amazon Linux 2023
```

The operating system provides the environment required for:

- Apache
- CloudWatch Agent
- SSM Agent
- Python-based operational tooling
- Shell scripts
- Linux system administration

---

# 6. Apache HTTP Server

Apache is the primary application monitored by the project.

### Service Name

```text
httpd
```

### Common Commands

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

Check the running process:

```bash
ps -ef | grep httpd
```

Check HTTP port:

```bash
ss -lntp | grep :80
```

---

# 7. CloudWatch Agent

The CloudWatch Agent runs directly on the EC2 instance.

Its purpose is to collect operating-system and application-related metrics and publish them to Amazon CloudWatch.

### Metrics Used

The project monitors areas including:

- CPU utilization
- Memory utilization
- Disk utilization
- Disk I/O
- Network traffic
- Apache process count

### Agent Service

```bash
systemctl status amazon-cloudwatch-agent
```

Start:

```bash
systemctl start amazon-cloudwatch-agent
```

Restart:

```bash
systemctl restart amazon-cloudwatch-agent
```

Enable:

```bash
systemctl enable amazon-cloudwatch-agent
```

---

# 8. CloudWatch Agent Configuration

The CloudWatch Agent configuration is maintained on the EC2 instance.

Typical configuration location:

```text
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/
```

The configuration defines:

- Metric collection
- Collection interval
- CPU monitoring
- Memory monitoring
- Disk monitoring
- Network monitoring
- Apache process monitoring

The project uses a **60-second monitoring interval** for the configured metrics.

---

# 9. Apache Process Monitoring

Apache availability is monitored through the process state.

The monitored process is:

```text
httpd
```

The monitoring logic checks whether the Apache process is available.

Conceptually:

```text
httpd process available
        |
        v
Normal monitoring state

httpd process unavailable
        |
        v
CloudWatch Alarm
        |
        v
NOC Automation
```

The P1 workflow uses the existing project alarm:

```text
NOC-cloudops-automate
```

---

# 10. SSM Agent

The SSM Agent runs on the EC2 instance and allows AWS Systems Manager to manage the server without requiring the automation workflow to establish an SSH connection.

### Check SSM Agent

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

Enable:

```bash
systemctl enable amazon-ssm-agent
```

The EC2 instance must remain registered as a Systems Manager managed node for automated remediation to work.

---

# 11. Automated Remediation

When the monitored Apache service fails, the EC2 instance becomes the target of the automated recovery workflow.

The remediation sequence is:

```text
Apache Failure
      |
      v
CloudWatch Detection
      |
      v
NOC-cloudops-automate
      |
      v
SNS
      |
      v
Lambda
      |
      v
SSM Run Command
      |
      v
EC2
      |
      v
systemctl restart httpd
      |
      v
Apache Recovery
```

The EC2 instance does not directly decide to restart itself.

Instead, the recovery action is orchestrated through:

**CloudWatch → SNS → Lambda → SSM → EC2**

---

# 12. IAM Integration

The EC2 instance uses the IAM role:

```text
cloudops-EC2-inline-role
```

The role provides the permissions required for the EC2-based monitoring and management components to communicate with AWS services.

The project follows the principle of:

```text
EC2
 |
 v
IAM Role
 |
 v
AWS Service Permissions
```

No permanent AWS access keys are required to be stored on the EC2 instance.

---

# 13. Network Integration

The EC2 instance is deployed inside the project's VPC.

```text
cloudops-vpc
       |
       v
cloudops-subnet
       |
       v
cloudops-server
```

The instance is associated with the project Security Group:

```text
cloudops-sg
```

The Security Group controls the network traffic permitted to and from the EC2 instance.

---

# 14. Security Configuration

The EC2 implementation follows these security practices:

- IAM Role-based AWS authentication.
- No hardcoded AWS access keys.
- Security Group-based network filtering.
- SSM-based remote management.
- Limited administrative access.
- CloudWatch-based monitoring.
- Operational logs for troubleshooting.

The automation workflow uses Systems Manager rather than requiring Lambda to connect directly to the server through SSH.

---

# 15. Logging and Troubleshooting

The EC2 instance provides several useful sources for troubleshooting.

### Operating System Logs

```text
/var/log/messages
```

View recent messages:

```bash
tail -n 100 /var/log/messages
```

Follow logs:

```bash
tail -f /var/log/messages
```

### SSM Agent Logs

```text
/var/log/amazon/ssm/
```

### CloudWatch Agent Logs

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

### Apache Logs

Common Apache log locations:

```text
/var/log/httpd/
```

Check Apache logs:

```bash
ls -lah /var/log/httpd/
```

---

# 16. Basic EC2 Health Checks

The following commands can be used during NOC troubleshooting.

### Check System Uptime

```bash
uptime
```

### Check CPU and Processes

```bash
top
```

### Check Memory

```bash
free -h
```

### Check Disk

```bash
df -h
```

### Check Network Ports

```bash
ss -lntp
```

### Check Apache

```bash
systemctl status httpd
```

### Check CloudWatch Agent

```bash
systemctl status amazon-cloudwatch-agent
```

### Check SSM Agent

```bash
systemctl status amazon-ssm-agent
```

---

# 17. Installation Components

The EC2 environment contains the components required for the project implementation.

| Component | Purpose |
| --- | --- |
| Amazon Linux 2023 | Operating system |
| Apache HTTP Server | Application workload |
| CloudWatch Agent | Metric collection |
| SSM Agent | AWS Systems Manager management |
| Python | Automation/support tooling |
| Shell utilities | Server administration |
| Git | Project/source-code management |

The exact installation and configuration scripts are maintained separately in the project repository.

---

# 18. Operational Dependency

The EC2 automation workflow depends on the correct operation of several project components.

| Dependency | Required For |
| --- | --- |
| VPC | Network connectivity |
| IAM Role | AWS permissions |
| Security Group | Network access |
| CloudWatch Agent | Metric collection |
| CloudWatch | Monitoring and alarms |
| SNS | Event distribution |
| Lambda | Automation logic |
| SSM Agent | Remote command execution |

If one of these dependencies fails, the automated remediation workflow may not complete successfully.

---

# 19. P1 and P2 Project Scope

The finalized project contains two operational severity levels.

### P1 – HTTPD Automation

The P1 workflow focuses on Apache (`httpd`) service availability.

```text
HTTPD Failure
     |
     v
CloudWatch
     |
     v
SNS
     |
     v
Lambda
     |
     v
SSM
     |
     v
Restart HTTPD
```

### P2 – CPU Utilization Automation

The P2 workflow focuses on CPU utilization monitoring and automation.

```text
EC2 CPU
   |
   v
CloudWatch
   |
   v
P2 Alarm / Automation
```

P3 / Unknown Service behavior is **not part of the finalized project scope**.

---

# 20. EC2 Operational Checklist

Before considering the EC2 server healthy, verify:

- [ ] EC2 instance is running.
- [ ] Apache service is active.
- [ ] HTTP port is listening.
- [ ] CloudWatch Agent is running.
- [ ] SSM Agent is running.
- [ ] EC2 has the correct IAM role.
- [ ] EC2 is visible as an SSM managed node.
- [ ] CloudWatch metrics are updating.
- [ ] Apache process monitoring is working.
- [ ] Required logs are available.

---

# 21. Common Failure Scenarios

## Apache Failure

```text
Apache stopped
     |
     v
CloudWatch alarm
     |
     v
Lambda
     |
     v
SSM
     |
     v
Apache restart
```

Verify:

```bash
systemctl status httpd
```

---

## CloudWatch Agent Failure

Symptoms:

- Metrics stop updating.
- Dashboard data becomes stale.
- Apache monitoring may stop working.

Verify:

```bash
systemctl status amazon-cloudwatch-agent
```

Restart if required:

```bash
systemctl restart amazon-cloudwatch-agent
```

---

## SSM Agent Failure

Symptoms:

- EC2 may no longer appear online in Systems Manager.
- Lambda cannot successfully execute the remediation command.

Verify:

```bash
systemctl status amazon-ssm-agent
```

---

# 22. EC2 Service Responsibility

The EC2 component has four primary responsibilities in this project:

```text
                EC2
                 |
     +-----------+-----------+
     |           |           |
     v           v           v
  Apache     Monitoring    Management
  Server     Agent/Logs      SSM Agent
```

It provides the actual workload, exposes the service health that CloudWatch monitors, and receives automated recovery commands through Systems Manager.

---

# 23. Related AWS Services

The EC2 configuration integrates only with the seven AWS services defined for this project:

| AWS Service | EC2 Relationship |
| --- | --- |
| IAM | Provides instance permissions |
| VPC | Provides network environment |
| CloudWatch | Receives monitoring metrics |
| SNS | Receives/distributes incident events |
| Lambda | Orchestrates remediation |
| SSM | Executes commands on EC2 |
| EC2 | Hosts the workload |

---

# 24. Summary

Amazon EC2 is the central workload component of the CloudOps NOC Automation project.

It hosts the Apache HTTP Server and runs the CloudWatch Agent and SSM Agent required for monitoring and automated recovery.

The complete P1 incident workflow is:

```text
EC2 / Apache
     |
     v
CloudWatch
     |
     v
SNS
     |
     v
Lambda
     |
     v
SSM
     |
     v
EC2 / Apache Restart
```

IAM provides the required permissions, while VPC provides the network environment.

This configuration enables the project to demonstrate a practical AWS NOC workflow in which an application failure can be detected, automatically remediated, and reported with minimal manual intervention.
