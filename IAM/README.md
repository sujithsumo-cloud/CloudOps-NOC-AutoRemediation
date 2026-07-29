# AWS Identity and Access Management (IAM)

## Overview

AWS Identity and Access Management (IAM) is the security service used to control authentication and authorization for AWS resources.

In this project, IAM Roles allow AWS services to securely communicate with each other without storing access keys.

IAM ensures that each service has only the permissions required to perform its assigned task.

---

# Purpose

IAM is used to:

- Secure AWS resources
- Grant permissions between AWS services
- Enable EC2 to communicate with Systems Manager
- Allow Lambda to invoke AWS Systems Manager
- Allow Lambda to write logs to CloudWatch
- Follow the Principle of Least Privilege

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
IAM Role
        │
        ▼
AWS Systems Manager
        │
        ▼
IAM Role
        │
        ▼
Amazon EC2

---

# IAM Roles Used

## EC2 IAM Role

Purpose:

- Register EC2 as a Managed Instance
- Communicate with AWS Systems Manager
- Receive Run Commands

Attached Policy:

AmazonSSMManagedInstanceCore

---

## Lambda Execution Role

Purpose:

- Invoke AWS Systems Manager
- Write execution logs to CloudWatch Logs

Attached Policies:

- AWSLambdaBasicExecutionRole
- Custom SSM Policy (or AmazonSSMFullAccess for learning)

---

# Why IAM Roles Instead of Access Keys?

IAM Roles provide:

- Temporary credentials
- Automatic credential rotation
- Improved security
- No hardcoded secrets

---

# Principle of Least Privilege

Each AWS service should receive only the permissions required to perform its task.

This reduces security risks and limits the impact of compromised credentials.

---

# Benefits

- Secure authentication
- Fine-grained authorization
- Temporary credentials
- Centralized permission management
- Improved compliance

---

# Repository Files

| File | Description |
|------|-------------|
| ec2-role-policy.json | EC2 IAM permissions |
| lambda-role-policy.json | Lambda IAM permissions |
| iam-roles.md | IAM role documentation |
| trust-policy.md | Trust relationship examples |
| least-privilege.md | Security best practices |
| iam-troubleshooting.md | Common IAM issues |
