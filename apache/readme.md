# Apache Web Server

## Overview

Apache HTTP Server is the web server used in this project to host the **Cloud Operations Center (NOC)** web application. It serves the web page to users over HTTP and HTTPS and acts as the primary application running on the Amazon EC2 instance.

In this project, Apache is continuously monitored using Amazon CloudWatch. If the Apache service stops unexpectedly, an automated remediation workflow restarts the service using AWS Systems Manager (SSM).

---

# Purpose

- Host the Cloud Operations Center (NOC) web application
- Serve web content over HTTP (Port 80)
- Serve secure web content over HTTPS (Port 443)
- Act as the application monitored by CloudWatch
- Demonstrate automated service recovery using AWS

---

# Apache in Project Architecture

User Browser
        │
        ▼
Apache Web Server (EC2)
        │
        ▼
CloudWatch Monitoring
        │
        ▼
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
Restart Apache Service

---

# Components

| File | Purpose |
|------|---------|
| index.html | Website content |
| httpd.conf | Main Apache configuration |
| ssl.conf | HTTPS/SSL configuration |
| apache-troubleshooting.md | Troubleshooting guide |

---

# Ports Used

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | HTTP | Web traffic |
| 443 | HTTPS | Secure web traffic |

---

# AWS Services Integrated

- Amazon EC2
- Amazon CloudWatch
- Amazon SNS
- AWS Lambda
- AWS Systems Manager (SSM)
- AWS IAM

---

# Service Management

Start Apache

```bash
sudo systemctl start httpd
```

Stop Apache

```bash
sudo systemctl stop httpd
```

Restart Apache

```bash
sudo systemctl restart httpd
```

Enable Apache at Boot

```bash
sudo systemctl enable httpd
```

Check Status

```bash
sudo systemctl status httpd
```

---

# Project Workflow

1. User accesses the web application.
2. Apache processes incoming HTTP/HTTPS requests.
3. CloudWatch continuously monitors the EC2 instance.
4. If Apache stops responding, CloudWatch Alarm enters the ALARM state.
5. Amazon SNS publishes the notification.
6. AWS Lambda invokes AWS Systems Manager.
7. Systems Manager restarts the Apache service automatically.
8. The website becomes available again.

---

# Best Practices

- Enable Apache during system boot.
- Validate configuration before restarting.
- Enable HTTPS whenever possible.
- Monitor Apache health continuously.
- Review Apache logs regularly.
- Follow the principle of least privilege for IAM permissions.
