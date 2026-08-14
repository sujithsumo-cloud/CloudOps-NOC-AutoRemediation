# AWS Systems Manager (SSM)

## Overview

AWS Systems Manager (SSM) is the secure server-management service used in the CloudOps NOC Automation project.

SSM provides the mechanism through which AWS Lambda remotely executes Linux commands on the Amazon EC2 instance without requiring direct SSH access.

In this project, SSM is primarily responsible for **automated Apache HTTP Server (httpd) recovery**.

When the existing CloudWatch alarm `NOC-cloudops-automate` detects that the Apache process is unavailable, the event reaches SNS and invokes the Lambda automation. Lambda then uses **Systems Manager Run Command** to execute the recovery command on the EC2 instance.

---

# 1. Purpose

AWS Systems Manager is used to:

- Manage the EC2 instance securely.
- Execute Linux commands remotely.
- Restart the Apache HTTP Server automatically.
- Eliminate SSH dependency for automation.
- Support event-driven remediation.
- Return command execution results to Lambda.
- Reduce manual NOC intervention.
- Provide an auditable command-execution workflow.

---

# 2. Role in the Project

SSM is the **execution layer** of the auto-remediation architecture.

The overall P1 HTTPD workflow is:

```text
Apache httpd
     │
     │ Process becomes unavailable
     ▼
CloudWatch Agent
     │
     ▼
Amazon CloudWatch
     │
     ▼
NOC-cloudops-automate
     │
     ▼
Amazon SNS
     │
     ▼
AWS Lambda
     │
     ▼
SSM Run Command
     │
     ▼
SSM Agent
     │
     ▼
EC2 Instance
     │
     ▼
systemctl restart httpd
     │
     ▼
Apache Recovered
```

---

# 3. SSM Components Used

| Component | Purpose |
|---|---|
| Systems Manager | Central management service |
| Managed Node | EC2 instance registered with SSM |
| Run Command | Executes Linux commands |
| SSM Agent | Receives and executes commands on EC2 |
| IAM Role | Authorizes EC2-to-SSM communication |
| Lambda | Requests Run Command execution |

---

# 4. Managed Node

The EC2 instance is registered with Systems Manager as a managed node.

| Property | Value |
|---|---|
| Instance Name | `cloudops-server` |
| Platform | Amazon Linux 2023 |
| Architecture | x86_64 |
| SSM Status | Online |
| SSM Agent | Installed and running |

The managed node must remain online and communicate successfully with Systems Manager.

---

# 5. SSM Agent

The SSM Agent runs on the EC2 instance as a system service.

Its responsibilities are:

- Communicate with Systems Manager.
- Receive Run Command instructions.
- Execute commands locally.
- Return command output.
- Report command execution status.
- Maintain secure communication with AWS.

### Verify SSM Agent

```bash
sudo systemctl status amazon-ssm-agent
```

### Start SSM Agent

```bash
sudo systemctl start amazon-ssm-agent
```

### Enable SSM Agent at Boot

```bash
sudo systemctl enable amazon-ssm-agent
```

### Restart SSM Agent

```bash
sudo systemctl restart amazon-ssm-agent
```

---

# 6. IAM Requirement

The EC2 instance requires an IAM role that allows Systems Manager to manage the instance.

The standard AWS managed policy used for the EC2 SSM role is:

```text
AmazonSSMManagedInstanceCore
```

This allows the SSM Agent to communicate with Systems Manager using temporary credentials provided through the EC2 instance role.

No AWS access key or secret access key is stored on the EC2 instance.

---

# 7. Lambda Permission

The Lambda execution role requires permission to send commands to the target EC2 instance through Systems Manager.

The project should use a restricted policy rather than unnecessarily granting full Systems Manager access.

Example permission:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource": "*"
    }
  ]
}
```

For a production implementation, the policy should be further restricted to the specific SSM document and EC2 target where practical.

---

# 8. Run Command

The project uses Systems Manager **Run Command** to execute the Apache recovery operation.

Primary command:

```bash
systemctl restart httpd
```

The command can be executed manually from the Systems Manager console for testing or automatically through Lambda during an incident.

---

# 9. Apache Recovery Procedure

The automated remediation performs the following logical operations:

### Step 1 – Check Apache

```bash
systemctl is-active httpd
```

### Step 2 – Restart Apache

```bash
systemctl restart httpd
```

### Step 3 – Verify Apache

```bash
systemctl is-active httpd
```

Expected result:

```text
active
```

This verification allows the automation workflow to determine whether the remediation succeeded.

---

# 10. End-to-End SSM Automation

When the P1 HTTPD alarm is triggered:

```text
1. Apache becomes unavailable
        ↓
2. CloudWatch detects Process Count = 0
        ↓
3. NOC-cloudops-automate enters ALARM
        ↓
4. CloudWatch publishes to SNS
        ↓
5. SNS invokes Lambda
        ↓
6. Lambda identifies the EC2 instance
        ↓
7. Lambda calls ssm:SendCommand
        ↓
8. Systems Manager receives command
        ↓
9. SSM Agent receives command
        ↓
10. SSM Agent executes systemctl restart httpd
        ↓
11. Apache becomes active
        ↓
12. Lambda checks execution result
        ↓
13. Recovery notification is generated
```

---

# 11. Why SSM Is Used Instead of SSH

The project uses SSM for automated server management rather than making Lambda connect to the EC2 instance through SSH.

### SSH-based approach

```text
Lambda
   ↓
SSH
   ↓
Port 22
   ↓
EC2
```

This requires additional SSH configuration, key management, network access, and credential handling.

### SSM-based approach

```text
Lambda
   ↓
AWS Systems Manager
   ↓
SSM Agent
   ↓
EC2
```

Advantages include:

- No SSH key required for automation.
- No Lambda-to-EC2 SSH connection required.
- No requirement to expose port 22 for the remediation workflow.
- IAM-based authorization.
- Centralized command execution.
- Command execution status.
- Better auditing and operational control.

---

# 12. Network Requirements

SSM Agent must be able to communicate with AWS Systems Manager endpoints.

In the current project architecture, the EC2 instance is deployed in a public subnet with internet connectivity.

The instance therefore requires appropriate outbound connectivity for AWS service communication.

For a future private-subnet architecture, VPC endpoints for Systems Manager-related services can be considered.

---

# 13. SSM Verification Commands

### Check Agent Status

```bash
sudo systemctl status amazon-ssm-agent
```

### Check Agent Version

```bash
amazon-ssm-agent -version
```

### Check SSM Logs

```bash
sudo ls -lah /var/log/amazon/ssm/
```

### View Recent SSM Log Entries

```bash
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log
```

### Verify Apache

```bash
sudo systemctl status httpd
```

---

# 14. Manual Run Command Test

Before depending on Lambda automation, the SSM workflow should be tested independently.

From the AWS Systems Manager console:

```text
Systems Manager
      ↓
Run Command
      ↓
AWS-RunShellScript
      ↓
Select EC2 managed node
      ↓
Enter command
      ↓
systemctl restart httpd
      ↓
Run
```

Then verify:

```bash
systemctl is-active httpd
```

Expected result:

```text
active
```

This confirms that the SSM layer is working before troubleshooting Lambda.

---

# 15. Troubleshooting

## Problem: EC2 Not Showing as Managed Node

Check:

```bash
sudo systemctl status amazon-ssm-agent
```

Then verify:

- EC2 IAM role is attached.
- `AmazonSSMManagedInstanceCore` is available.
- SSM Agent is running.
- EC2 has outbound connectivity.
- Instance is running.

---

## Problem: SSM Agent Is Offline

Restart the agent:

```bash
sudo systemctl restart amazon-ssm-agent
```

Then check:

```bash
sudo systemctl status amazon-ssm-agent
```

---

## Problem: Run Command Fails

Check:

- Managed node status.
- IAM permissions.
- Command syntax.
- SSM Agent status.
- SSM Agent logs.
- EC2 connectivity.

---

## Problem: Apache Does Not Restart

Check Apache directly:

```bash
sudo systemctl status httpd
```

Check configuration:

```bash
sudo apachectl configtest
```

Try manually:

```bash
sudo systemctl restart httpd
```

Check logs:

```bash
sudo journalctl -u httpd --no-pager -n 50
```

---

# 16. Logging

SSM Agent logs are stored on the EC2 instance.

Primary directory:

```text
/var/log/amazon/ssm/
```

These logs can help identify:

- Agent startup problems.
- Connectivity problems.
- Command execution issues.
- Authentication problems.
- Agent communication failures.

Lambda execution logs are separately available through Amazon CloudWatch Logs.

---

# 17. Security Best Practices

The SSM implementation follows these practices:

- Use IAM roles instead of static credentials.
- Keep SSM Agent updated.
- Use least-privilege Lambda permissions.
- Avoid unnecessary SSH access.
- Restrict Run Command permissions.
- Monitor command execution.
- Review SSM logs during incidents.
- Test remediation commands before automation.
- Do not place AWS credentials inside shell scripts.

---

# 18. Repository Structure

Recommended SSM project files:

```text
ssm/
├── README.md
├── commands/
│   ├── restart-httpd.sh
│   ├── check-httpd.sh
│   └── verify-httpd.sh
│
├── documents/
│   └── restart-httpd-document.json
│
├── policies/
│   └── lambda-ssm-policy.json
│
├── scripts/
│   ├── install-ssm-agent.sh
│   └── verify-ssm-agent.sh
│
├── troubleshooting/
│   └── ssm-troubleshooting.md
│
└── screenshots/
    ├── managed-node.png
    ├── run-command.png
    └── command-result.png
```

---

# 19. Example Recovery Script

The basic Apache recovery script can be maintained in the repository:

```bash
#!/bin/bash

echo "Checking Apache service..."

if systemctl is-active --quiet httpd; then
    echo "Apache is already running."
    exit 0
fi

echo "Apache is not running."
echo "Attempting Apache restart..."

systemctl restart httpd

if systemctl is-active --quiet httpd; then
    echo "Apache restart successful."
    exit 0
else
    echo "Apache restart failed."
    systemctl status httpd --no-pager
    exit 1
fi
```

This script can be executed through Systems Manager Run Command.

---

# 20. Operational Role

Within the finalized CloudOps NOC architecture, SSM is responsible for the **execution of remediation**, not for detecting the incident.

| Layer | Service | Responsibility |
|---|---|---|
| Detection | CloudWatch | Detect Apache failure |
| Event Distribution | SNS | Distribute alarm event |
| Automation | Lambda | Start remediation |
| Execution | SSM | Execute Linux command |
| Target | EC2 | Run Apache |
| Recovery | httpd | Return to active state |

This separation of responsibilities makes the automation workflow easier to troubleshoot and maintain.

---

# 21. Benefits

The SSM implementation provides:

- Secure remote command execution.
- Automated Apache recovery.
- Reduced dependency on SSH.
- IAM-based authentication.
- Centralized management.
- Command execution visibility.
- Faster incident recovery.
- Reduced manual NOC effort.

---

# 22. Project Scope

For the current CloudOps NOC project, Systems Manager is used primarily for:

**P1 – HTTPD Auto-Remediation**

The remediation action is:

```text
systemctl restart httpd
```

The finalized project scope contains **P1 HTTPD automation and P2 CPU utilization automation**. SSM can support both workflows, while the actual command executed depends on the automation logic associated with each severity.

---

# 23. Summary

AWS Systems Manager provides the secure execution layer of the CloudOps NOC Auto-Remediation System.

CloudWatch detects the incident, SNS distributes the event, Lambda controls the automation workflow, and Systems Manager securely executes the required command on EC2.

For the P1 HTTPD workflow:

```text
CloudWatch
    ↓
SNS
    ↓
Lambda
    ↓
SSM Run Command
    ↓
SSM Agent
    ↓
EC2
    ↓
systemctl restart httpd
    ↓
Apache Recovered
```

This architecture provides a practical, secure, and automated approach to server remediation while reducing manual intervention and improving recovery time.
