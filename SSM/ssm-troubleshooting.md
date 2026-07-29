# AWS Systems Manager Troubleshooting Guide

## 1. EC2 Instance Not Showing as Managed

### Possible Causes

- SSM Agent not installed
- SSM Agent stopped
- Missing IAM Role
- No internet or VPC endpoint connectivity

### Investigation

```bash
sudo systemctl status amazon-ssm-agent
```

---

## 2. Run Command Failed

### Possible Causes

- Invalid document name
- Incorrect Instance ID
- Permission denied
- Command syntax error

### Investigation

Review the Run Command output in the AWS Systems Manager console.

---

## 3. Lambda Cannot Invoke SSM

### Possible Causes

- Missing IAM permissions
- Incorrect AWS Region
- Invalid API parameters

### Investigation

Review Lambda logs in CloudWatch Logs.

---

## 4. Command Status Stuck in Pending

### Possible Causes

- SSM Agent offline
- EC2 instance unreachable
- Network issues

### Investigation

Check:

- EC2 status
- SSM Agent
- IAM role
- Network connectivity

---

## 5. Apache Did Not Restart

### Investigation

```bash
sudo systemctl status httpd
```

Review Apache logs:

```bash
sudo journalctl -u httpd
```

---

## Useful Commands

```bash
sudo systemctl status amazon-ssm-agent
sudo systemctl restart amazon-ssm-agent
sudo systemctl status httpd
sudo systemctl restart httpd
```
