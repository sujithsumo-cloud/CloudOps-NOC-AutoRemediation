# CloudOps NOC V2.0 — Scripts

This directory contains the Linux shell scripts used to install, configure,
operate, verify, and diagnose the EC2 environment used by the CloudOps NOC
Automation project.

The scripts support the implemented NOC scope:

- P1 — Apache HTTPD service availability
- P2 — CPU utilization monitoring and diagnosis

The scripts are primarily intended for EC2 setup, operational testing,
verification, and incident diagnosis.

---

## Directory Structure

```text
scripts/
│
├── README.md
│
├── installation/
│   ├── 01-install-apache.sh
│   ├── 02-install-cloudwatch-agent.sh
│   └── 03-install-ssm-agent.sh
│
├── configuration/
│   ├── 04-configure-cloudwatch-agent.sh
│   └── 05-enable-services.sh
│
├── operations/
│   ├── restart-httpd.sh
│   ├── start-httpd.sh
│   └── stop-httpd.sh
│
├── verification/
│   ├── verify-services.sh
│   ├── health-check.sh
│   └── verify-aws-agents.sh
│
└── diagnostics/
    ├── system-information.sh
    ├── collect-logs.sh
    └── troubleshoot.sh
