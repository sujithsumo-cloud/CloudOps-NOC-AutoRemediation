# Apache Troubleshooting Guide

## Purpose

This document describes common Apache issues encountered during deployment, testing, and production environments, along with investigation steps and resolutions.

---

# 1. Apache Service Not Running

## Symptoms

- Website not accessible
- CloudWatch Alarm triggered
- HTTP 503 or connection refused

## Investigation

```bash
sudo systemctl status httpd
```

## Resolution

```bash
sudo systemctl start httpd
```

---

# 2. Apache Not Starting After Reboot

## Investigation

```bash
sudo systemctl is-enabled httpd
```

## Resolution

```bash
sudo systemctl enable httpd
```

---

# 3. Configuration Syntax Error

## Investigation

```bash
sudo apachectl configtest
```

Expected Output

```
Syntax OK
```

---

# 4. Port Already in Use

## Investigation

```bash
sudo ss -tulpn
```

---

# 5. Website Returns 403 Forbidden

Possible Causes

- Incorrect permissions
- Incorrect Directory configuration
- SELinux restrictions

---

# 6. Website Returns 404

Possible Causes

- Missing index.html
- Incorrect DocumentRoot

---

# 7. Website Returns 500

Possible Causes

- Configuration errors
- Incorrect module configuration
- Application errors

---

# 8. HTTPS Certificate Errors

Possible Causes

- Self-signed certificate
- Incorrect certificate path
- Expired certificate
- CN mismatch

---

# 9. SSL Configuration Validation

```bash
sudo apachectl configtest
```

---

# 10. View Apache Logs

Access Log

```bash
tail -f /var/log/httpd/access_log
```

Error Log

```bash
tail -f /var/log/httpd/error_log
```

---

# Useful Commands

```bash
sudo systemctl status httpd
sudo systemctl restart httpd
sudo apachectl configtest
sudo ss -tulpn
curl http://localhost
curl -k https://localhost
```
