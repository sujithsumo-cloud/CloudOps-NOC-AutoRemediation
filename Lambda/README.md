# AWS Lambda

## Overview

AWS Lambda is a serverless compute service that allows code to run without provisioning or managing servers. In this project, Lambda acts as the automation engine that receives notifications from Amazon SNS and remotely restarts the Apache web server using AWS Systems Manager (SSM).

Lambda eliminates the need for manual intervention by automatically executing the remediation workflow whenever a CloudWatch Alarm detects a service failure.

---

# Purpose

The primary objectives of using AWS Lambda are:

- Execute code without managing servers
- Receive notifications from Amazon SNS
- Invoke AWS Systems Manager Run Command
- Restart the Apache web server automatically
- Reduce Mean Time to Recovery (MTTR)
- Enable automated incident response

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
AWS Systems Manager
        │
        ▼
Amazon EC2
        │
        ▼
Restart Apache Service

---

# Trigger

The Lambda function is triggered automatically whenever Amazon SNS receives a notification from a CloudWatch Alarm.

Trigger Source:

- Amazon SNS Topic

Invocation Type:

- Event-based

---

# Runtime

Runtime: Python 3.x

The function uses the AWS SDK for Python (boto3), which is available by default in the Lambda runtime.

---

# Responsibilities

The Lambda function performs the following tasks:

- Receives the SNS notification
- Creates an SSM client using boto3
- Sends an SSM Run Command to the EC2 instance
- Executes the Apache restart command
- Logs execution details to Amazon CloudWatch Logs
- Returns the command execution status

---

# Environment Variables

The following environment variables can be used to avoid hardcoding values.

| Variable | Description |
|----------|-------------|
| INSTANCE_ID | EC2 Instance ID |
| DOCUMENT_NAME | SSM Document Name |
| AWS_REGION | AWS Region |

---

# IAM Permissions

The Lambda execution role requires permission to:

- Invoke AWS Systems Manager Run Command
- Write logs to Amazon CloudWatch Logs

Example AWS managed policies:

- AWSLambdaBasicExecutionRole
- AmazonSSMFullAccess (or a least-privilege custom policy)

---

# Logging

Execution logs are automatically stored in Amazon CloudWatch Logs.

Logs help troubleshoot:

- Failed SSM commands
- Permission issues
- Timeout errors
- Unexpected exceptions

---

# Error Handling

The Lambda function should:

- Catch exceptions
- Log meaningful error messages
- Return appropriate status codes
- Prevent unexpected function failures

---

# AWS Services Integrated

- Amazon CloudWatch
- Amazon SNS
- AWS Lambda
- AWS Systems Manager
- Amazon EC2
- AWS IAM

---

# Benefits

- Serverless execution
- Automatic scaling
- Event-driven automation
- High availability
- Reduced operational effort
- Faster incident response

---

# Best Practices

- Avoid hardcoding values.
- Use environment variables.
- Follow the principle of least privilege.
- Implement exception handling.
- Monitor CloudWatch Logs.
- Keep functions lightweight and focused.

--
