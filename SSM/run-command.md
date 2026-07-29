# AWS Systems Manager Run Command

## Overview

AWS Systems Manager Run Command is a capability of AWS Systems Manager that allows administrators and automation services to execute commands securely on managed EC2 instances without using SSH.

In this project, AWS Lambda invokes Run Command to restart the Apache web server whenever CloudWatch detects a service failure.

---

# Purpose

Run Command is used to:

- Execute remote shell commands
- Restart the Apache service
- Eliminate manual server login
- Automate incident recovery
- Record command execution history

---

# Project Workflow

CloudWatch Alarm
        │
        ▼
Amazon SNS
        │
        ▼
AWS Lambda
        │
        ▼
AWS Systems Manager Run Command
        │
        ▼
Amazon EC2
        │
        ▼
Restart Apache Service

---

# SSM Document Used

Document Name:

AWS-RunShellScript

---

# Commands Executed

```bash
sudo systemctl restart httpd
sudo systemctl status httpd
```

---

# Expected Result

- Apache service restarts successfully.
- The service status changes to **active (running)**.
- Command status is reported as **Success**.
- CloudWatch metrics return to a healthy state.

---

# Validation

Verify Apache status:

```bash
sudo systemctl status httpd
```

Verify service response:

```bash
curl http://localhost
```

---

# Benefits

- No SSH required
- Secure command execution
- Centralized management
- Command history
- Automated recovery

---

# Common Failure Reasons

- EC2 is not a managed instance.
- SSM Agent is stopped.
- IAM role is missing.
- Invalid document name.
- Incorrect Instance ID.
- Network connectivity issues.
