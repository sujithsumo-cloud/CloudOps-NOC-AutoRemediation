# AWS Systems Manager Agent (SSM Agent)

## Overview

The AWS Systems Manager Agent (SSM Agent) is software installed on Amazon EC2 instances that enables communication between the instance and AWS Systems Manager.

In this project, the SSM Agent receives commands from Systems Manager and executes them locally on the EC2 instance.

Without the SSM Agent, AWS Systems Manager cannot manage the server.

---

# Purpose

The SSM Agent is responsible for:

- Receiving Run Command requests
- Executing commands on the EC2 instance
- Returning execution results
- Maintaining secure communication with AWS

---

# Communication Flow

AWS Systems Manager

↓

SSM Agent

↓

Linux Operating System

↓

Apache Service

---

# Verify Agent Status

```bash
sudo systemctl status amazon-ssm-agent
```

---

# Start Agent

```bash
sudo systemctl start amazon-ssm-agent
```

---

# Restart Agent

```bash
sudo systemctl restart amazon-ssm-agent
```

---

# Enable Agent at Boot

```bash
sudo systemctl enable amazon-ssm-agent
```

---

# Check if Agent is Active

```bash
sudo systemctl is-active amazon-ssm-agent
```

---

# Why It Is Important

The SSM Agent enables:

- Run Command
- Session Manager
- Patch Manager
- Automation
- Inventory
- State Manager

Without the agent, the EC2 instance cannot receive management commands from AWS Systems Manager.

---

# Common Issues

| Issue | Resolution |
|------|------------|
| Agent stopped | Start the service |
| IAM Role missing | Attach AmazonSSMManagedInstanceCore |
| Instance not managed | Verify IAM and network connectivity |
| Agent offline | Restart the agent and verify internet access |

