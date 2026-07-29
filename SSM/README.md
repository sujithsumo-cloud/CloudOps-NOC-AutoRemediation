# AWS Systems Manager (SSM)

## Overview

AWS Systems Manager (SSM) is a management service that enables administrators to securely manage Amazon EC2 instances without requiring SSH access.

In this project, Systems Manager is responsible for executing the remote command that restarts the Apache web server after AWS Lambda detects a service failure.

Instead of connecting manually to the EC2 instance, AWS Lambda invokes Systems Manager Run Command, which securely communicates with the SSM Agent installed on the EC2 instance.

---

# Purpose

AWS Systems Manager is used to:

- Execute commands remotely
- Restart Apache automatically
- Eliminate the need for SSH access
- Improve operational security
- Enable automated remediation
- Reduce manual intervention

---

# Project Architecture

CloudWatch Alarm
        │
        ▼
   Amazon SNS
        │
        ▼
   AWS Lambda
        │
        ▼
 AWS Systems Manager
        │
        ▼
    SSM Agent
        │
        ▼
 Amazon EC2 Instance
        │
        ▼
Restart Apache Service

---

# Components Used

| Component | Purpose |
|-----------|---------|
| Systems Manager | Remote server management |
| Run Command | Execute Linux commands remotely |
| SSM Agent | Receives commands on EC2 |
| IAM Role | Authorizes EC2 communication |

---

# How It Works

1. CloudWatch Alarm detects a failure.
2. SNS sends a notification.
3. Lambda is invoked.
4. Lambda calls Systems Manager Run Command.
5. Systems Manager sends the command to the SSM Agent.
6. SSM Agent executes the command on the EC2 instance.
7. Apache service restarts.
8. Command status is returned to Systems Manager.

---

# Why SSM Instead of SSH?

Using Systems Manager provides several advantages:

- No SSH port (22) required
- No key pair management
- Secure communication through AWS APIs
- Centralized command execution
- Full execution history
- Better security posture

---

# IAM Requirements

The EC2 instance must have an IAM Role with Systems Manager permissions.

Example managed policy:

- AmazonSSMManagedInstanceCore

The Lambda execution role must have permission to invoke Systems Manager Run Command.

---

# SSM Agent

The SSM Agent is installed on the EC2 instance and performs the following tasks:

- Receives commands from Systems Manager
- Executes commands locally
- Returns execution results
- Maintains secure communication with AWS

Without the SSM Agent, Systems Manager cannot manage the EC2 instance.

---

# Benefits

- Secure remote management
- Automated remediation
- No SSH dependency
- Centralized administration
- Command history and auditing
- Reduced operational overhead

---

# Best Practices

- Keep the SSM Agent updated.
- Use IAM Roles instead of access keys.
- Follow the principle of least privilege.
- Monitor command execution history.
- Test automation regularly.

---

# Repository Files

| File | Description |
|------|-------------|
| restart-httpd-document.json | Run Command document |
| run-command.md | Command execution details |
| ssm-agent.md | SSM Agent documentation |
| ssm-troubleshooting.md | Common issues and resolutions |
| screenshots/ | Systems Manager console screenshots |
