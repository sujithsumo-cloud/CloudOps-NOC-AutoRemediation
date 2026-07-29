# Utility Scripts

## Overview

This directory contains all shell scripts used to deploy, configure, verify, and troubleshoot the CloudOps NOC Auto-Remediation project.

These scripts automate repetitive administrative tasks, simplify deployment, and provide operational support for maintaining the EC2 instance and its associated services.

The scripts are organized according to the project lifecycle, from initial deployment to production troubleshooting.

---

# Purpose

The scripts in this folder are used to:

- Install required software packages
- Configure monitoring components
- Enable system services
- Verify application health
- Restart services
- Collect diagnostic information
- Assist with production troubleshooting

---

# Script Categories

## Deployment

Scripts used during the initial setup of the EC2 instance.

- Install Apache Web Server
- Install CloudWatch Agent
- Verify and configure SSM Agent
- Configure CloudWatch Agent
- Enable required services at boot

---

## Operations

Scripts used for daily administration.

- Restart Apache
- Verify running services
- Perform health checks

---

## Troubleshooting

Scripts used during incident investigation.

- Collect system information
- Retrieve service logs
- Verify infrastructure health

---

# Script Details

| Script | Description |
|---------|-------------|
| 01-install-apache.sh | Installs and starts the Apache Web Server |
| 02-install-cloudwatch-agent.sh | Installs the Amazon CloudWatch Agent |
| 03-install-ssm-agent.sh | Verifies and starts the Amazon SSM Agent |
| 04-configure-cloudwatch-agent.sh | Applies the CloudWatch Agent configuration |
| 05-enable-services.sh | Enables required services to start automatically during system boot |
| restart-httpd.sh | Restarts the Apache service |
| verify-services.sh | Verifies Apache, CloudWatch Agent, and SSM Agent status |
| health-check.sh | Validates HTTP and HTTPS connectivity |
| system-information.sh | Displays operating system and hardware information |
| collect-logs.sh | Retrieves Apache, SSM Agent, and CloudWatch Agent logs |
| troubleshoot.sh | Performs a complete operational health check |

---

# Services Covered

These scripts interact with the following services:

- Amazon EC2
- Apache HTTP Server
- Amazon CloudWatch Agent
- AWS Systems Manager Agent
- Linux Systemd Services

---

# Typical Workflow

1. Launch EC2 instance.
2. Install Apache.
3. Install CloudWatch Agent.
4. Verify SSM Agent.
5. Configure CloudWatch Agent.
6. Enable required services.
7. Verify service status.
8. Perform health checks.
9. Monitor the application.
10. Troubleshoot issues if necessary.

---

# Best Practices

- Execute scripts with appropriate permissions.
- Review script output after execution.
- Test scripts in a non-production environment before production use.
- Keep scripts under version control.
- Document any modifications.

---

# Repository Structure

```text
scripts/
│
├── README.md
├── 01-install-apache.sh
├── 02-install-cloudwatch-agent.sh
├── 03-install-ssm-agent.sh
├── 04-configure-cloudwatch-agent.sh
├── 05-enable-services.sh
├── restart-httpd.sh
├── verify-services.sh
├── health-check.sh
├── system-information.sh
├── collect-logs.sh
└── troubleshoot.sh
```

---

# Learning Outcome

Through these scripts, this project demonstrates:

- Linux administration
- Service management using systemctl
- EC2 server configuration
- CloudWatch Agent deployment
- AWS Systems Manager integration
- Infrastructure validation
- Production troubleshooting
- Operational automation
