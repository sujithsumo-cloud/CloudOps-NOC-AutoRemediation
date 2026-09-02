# Scripts — CloudOps NOC Automation V2.0

This folder contains Bash scripts used on the EC2 instance for **deployment, manual operations, verification, and troubleshooting**.

> These scripts support the project, but they are **not the Lambda automation itself**.

The automated P1 runtime path is:

```text
CloudWatch Alarm
      ↓
Lambda
      ↓
Boto3
      ↓
Systems Manager Run Command
      ↓
SSM Agent
      ↓
Linux systemctl / systemd
      ↓
HTTPD
```

P2 uses the same SSM execution path for **diagnostic commands only**.

---

## Folder Structure

```text
Scripts/
├── Installation/
│   ├── 01-install-apache.sh
│   ├── 02-install-cloudwatch-agent.sh
│   └── 03-install-ssm-agent.sh
│
├── Configuration/
│   ├── 01-configure-cloudwatch-agent.sh
│   └── 02-enable-services.sh
│
├── Operations/
│   ├── start-httpd.sh
│   ├── stop-httpd.sh
│   └── restart-httpd.sh
│
├── Verification/
│   ├── verify-services.sh
│   ├── verify-aws-agents.sh
│   └── health-check.sh
│
└── Diagnostics/
    ├── system-information.sh
    ├── collect-logs.sh
    └── troubleshoot.sh
```

Remember:

```text
INSTALL
   ↓
CONFIGURE
   ↓
OPERATE
   ↓
VERIFY
   ↓
DIAGNOSE
```

---

## 1. Installation

### `01-install-apache.sh`

Purpose:

```text
Install HTTPD
→ Enable at boot
→ Start now
→ Verify
```

Run:

```bash
sudo bash Scripts/Installation/01-install-apache.sh
```

### `02-install-cloudwatch-agent.sh`

Installs the Amazon CloudWatch Agent.

Run:

```bash
sudo bash Scripts/Installation/02-install-cloudwatch-agent.sh
```

This script **installs only**. Monitoring behavior is defined by the canonical JSON configuration.

### `03-install-ssm-agent.sh`

Checks whether SSM Agent already exists. If missing, it detects x86_64 or ARM64 and installs the official AWS RPM.

Run:

```bash
sudo bash Scripts/Installation/03-install-ssm-agent.sh
```

---

## 2. Configuration

### `01-configure-cloudwatch-agent.sh`

Reads the **single canonical configuration**:

```text
CloudWatch/cloudwatch-agent-config.json
```

and applies it to the CloudWatch Agent.

Run from the repository:

```bash
sudo bash Scripts/Configuration/01-configure-cloudwatch-agent.sh
```

Correct metric responsibility:

```text
P1:
CloudWatch Agent
→ procstat
→ procstat_lookup_pid_count

P2:
AWS/EC2
→ CPUUtilization
```

CloudWatch Agent CPU metrics are additional observability only.

### `02-enable-services.sh`

Enables and starts:

```text
httpd
amazon-cloudwatch-agent
amazon-ssm-agent
```

Run:

```bash
sudo bash Scripts/Configuration/02-enable-services.sh
```

---

## 3. Operations

These are **manual helper scripts**.

### Start HTTPD

```bash
sudo bash Scripts/Operations/start-httpd.sh
```

### Stop HTTPD

```bash
sudo bash Scripts/Operations/stop-httpd.sh
```

`stop-httpd.sh` is useful for the controlled P1 failure test.

### Restart HTTPD

```bash
sudo bash Scripts/Operations/restart-httpd.sh
```

Important:

```text
restart-httpd.sh
≠
automated Lambda remediation
```

Lambda does not call this GitHub script directly. The real P1 workflow sends the equivalent `systemctl restart httpd` command through SSM Run Command.

---

## 4. Verification

### Required Services

```bash
bash Scripts/Verification/verify-services.sh
```

Checks active/enabled state.

### AWS Agents

```bash
bash Scripts/Verification/verify-aws-agents.sh
```

Checks CloudWatch Agent and SSM Agent.

### EC2 Health

```bash
bash Scripts/Verification/health-check.sh
```

Checks:

```text
Hostname
Kernel
Uptime
Load average
CPU count
Memory
Disk
HTTPD
Port 80
Local HTTP
AWS agent services
```

---

## 5. Diagnostics

### System Snapshot

```bash
bash Scripts/Diagnostics/system-information.sh
```

Read-only system information.

### Collect Logs

```bash
sudo bash Scripts/Diagnostics/collect-logs.sh
```

Creates a local troubleshooting archive under `/tmp`.

It does **not** upload the archive anywhere.

### Troubleshoot

```bash
bash Scripts/Diagnostics/troubleshoot.sh
```

Runs first-level local checks without changing the system.

---

## Recommended Initial Deployment Order

```bash
sudo bash Scripts/Installation/01-install-apache.sh

sudo bash Scripts/Installation/02-install-cloudwatch-agent.sh

sudo bash Scripts/Installation/03-install-ssm-agent.sh

sudo bash Scripts/Configuration/01-configure-cloudwatch-agent.sh

sudo bash Scripts/Configuration/02-enable-services.sh

bash Scripts/Verification/verify-services.sh

bash Scripts/Verification/verify-aws-agents.sh

bash Scripts/Verification/health-check.sh
```

---

## Controlled P1 Test

Pre-check:

```bash
systemctl is-active httpd
```

Inject failure:

```bash
sudo bash Scripts/Operations/stop-httpd.sh
```

Expected runtime automation:

```text
HTTPD Down
   ↓
CloudWatch Agent
   ↓
procstat_lookup_pid_count
   ↓
NOC-cloudops-automate
   ↓
Lambda
   ↓
SSM
   ↓
systemctl restart httpd
   ↓
Verification
   ↓
Stability Check
   ↓
SNS
```

---

## P2 Reminder

P2 is not an automatic remediation workflow.

```text
CPUUtilization
   ↓
cpu alert
   ↓
Lambda
   ↓
SSM diagnostics
   ↓
SNS report
   ↓
Engineer review
```

---

## Bash Concepts Used

```text
#!/bin/bash
= execute with Bash

set -Eeuo pipefail
= stricter error handling

if / then / else
= decision

for
= repeat an operation

systemctl
= request Linux service operations

systemd
= service manager that actually manages services

dnf
= Linux package manager

rpm -q
= check whether an RPM package is installed

exit 0
= success

exit 1
= failure
```

---

## Key Design Statement

> **The repository Bash scripts install, configure, operate, verify, and diagnose the EC2 environment. The actual event-driven P1/P2 incident workflow is handled by CloudWatch, Lambda, Systems Manager, and SNS.**
