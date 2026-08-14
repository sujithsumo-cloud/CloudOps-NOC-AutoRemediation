# AWS Identity and Access Management (IAM)

## CloudOps NOC Automation Project

---

# 1. Overview

AWS Identity and Access Management (IAM) is the authorization and authentication control layer of the CloudOps NOC Automation project.

IAM controls which AWS identities and services can access project resources and which API operations they are allowed to perform.

The project uses IAM Roles instead of storing permanent AWS access keys on the EC2 instance or inside the Lambda function.

IAM is one of the seven AWS services implemented in this project:

1. IAM
2. Amazon EC2
3. Amazon VPC
4. Amazon CloudWatch
5. Amazon SNS
6. AWS Systems Manager (SSM)
7. AWS Lambda

---

# 2. Purpose

IAM is used to:

- Authenticate AWS services.
- Authorize AWS API operations.
- Allow EC2 to communicate with Systems Manager.
- Allow EC2 to publish monitoring data to CloudWatch.
- Allow Lambda to execute SSM Run Commands.
- Allow Lambda to write execution logs to CloudWatch Logs.
- Allow Lambda to publish notifications to SNS.
- Control access using least-privilege permissions.
- Eliminate hardcoded AWS credentials.

---

# 3. IAM Architecture

The project uses different IAM roles for different workloads.

```text
                    AWS IAM
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
   EC2 Instance Role          Lambda Execution Role
          │                         │
          │                         ├── CloudWatch Logs
          │                         ├── SSM Run Command
          │                         └── SNS Publish
          │
          ├── Systems Manager
          ├── CloudWatch
          └── CloudWatch Logs
```

The IAM role attached to EC2 and the IAM execution role used by Lambda have different responsibilities.

---

# 4. IAM Components

The IAM implementation consists of:

- IAM Roles
- Trust Policies
- Permission Policies
- Inline Policies
- Managed Policies
- IAM Role Attachments
- Least-Privilege Permissions

---

# 5. EC2 IAM Role

## Role Name

```text
cloudops-EC2-inline-role
```

## Purpose

The EC2 role provides the EC2 instance with temporary AWS credentials that allow the installed CloudWatch Agent and SSM Agent to communicate with AWS services.

The role is attached to the EC2 instance through an Instance Profile.

---

# 6. EC2 Role Responsibilities

The EC2 role is used for:

### Systems Manager

Allows the SSM Agent to register the instance as a managed node and communicate with Systems Manager.

### CloudWatch

Allows the CloudWatch Agent to publish system metrics.

### CloudWatch Logs

Allows supported agent functionality to send logs to CloudWatch Logs.

### EC2

Required EC2 API permissions may be provided where the project configuration requires instance information.

---

# 7. EC2 Role Policy

For Systems Manager, the standard AWS managed policy is:

```text
AmazonSSMManagedInstanceCore
```

This policy provides the core permissions required by the SSM Agent.

For CloudWatch Agent functionality, permissions should be limited to the actions required by the configured metrics and log collection.

Example permissions include:

```text
cloudwatch:PutMetricData
logs:CreateLogGroup
logs:CreateLogStream
logs:DescribeLogStreams
logs:PutLogEvents
```

The exact policy should match the CloudWatch Agent configuration deployed on the instance.

---

# 8. EC2 Trust Policy

The EC2 IAM role must trust the EC2 service.

Example trust relationship:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This allows Amazon EC2 to assume the role and provide temporary credentials to applications running on the instance.

---

# 9. Lambda Execution Role

Lambda uses a separate IAM execution role.

Example role name:

```text
Cloudops-NOC-Lambda-Execution-Role
```

The role allows the Lambda function to perform only the AWS API operations required by the automation workflow.

---

# 10. Lambda Role Responsibilities

The Lambda execution role provides permissions for:

### CloudWatch Logs

Lambda requires permissions to create and write its execution logs.

Typical actions:

```text
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

### Systems Manager

Lambda requires permission to execute the remediation command.

Primary API operation:

```text
ssm:SendCommand
```

### EC2

If the Lambda implementation performs EC2 API lookups, the role may require read-only permissions such as:

```text
ec2:DescribeInstances
```

### SNS

If Lambda publishes the remediation result to the SNS topic:

```text
sns:Publish
```

---

# 11. Lambda Least-Privilege Policy

A project-specific Lambda policy can be structured like this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SSMRunCommand",
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PublishNotification",
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:ap-south-1:ACCOUNT_ID:cloudops-sns"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

`ACCOUNT_ID` should be replaced with the AWS account ID during actual deployment.

Where supported by the specific API and resource model, permissions should be narrowed further to specific resources instead of using `"Resource": "*"`.

---

# 12. Lambda Trust Policy

The Lambda execution role must trust the Lambda service.

Example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

This allows AWS Lambda to assume the execution role when the function runs.

---

# 13. IAM and CloudWatch

CloudWatch interacts with the project through multiple permission paths.

```text
EC2
 │
 │ IAM Role
 ▼
CloudWatch Agent
 │
 ▼
CloudWatch Metrics
 │
 ▼
CloudWatch Alarm
```

The CloudWatch Agent uses the EC2 instance role to authenticate when publishing metrics.

The CloudWatch Alarm itself evaluates metrics and invokes its configured action.

---

# 14. IAM and SNS

The monitoring workflow uses SNS for notification distribution.

```text
CloudWatch Alarm
       │
       ▼
   SNS Topic
       │
       ├── Email
       │
       └── Lambda
```

SNS access is controlled through AWS IAM and, where applicable, SNS topic resource policies.

Lambda requires `sns:Publish` only if the Lambda function publishes the remediation result back to the SNS topic.

---

# 15. IAM and Systems Manager

Systems Manager uses IAM on both sides of the automation workflow.

```text
Lambda
   │
   │ Lambda IAM Role
   │
   ▼
SSM SendCommand
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   │ EC2 IAM Role
   ▼
EC2 Instance
```

The Lambda role authorizes the API call to Systems Manager.

The EC2 role allows the SSM Agent to communicate with Systems Manager.

Both roles therefore have different responsibilities.

---

# 16. IAM and Lambda Workflow

The complete authorization flow is:

```text
CloudWatch Alarm
       │
       ▼
SNS
       │
       ▼
Lambda
       │
       │ Assumes Lambda Execution Role
       ▼
AWS API
       │
       ├── Systems Manager
       │
       ├── SNS
       │
       └── CloudWatch Logs
```

Lambda does not require AWS access keys embedded in the Python code.

---

# 17. IAM and EC2 Workflow

The EC2 instance receives temporary credentials through its attached IAM Instance Profile.

```text
EC2
 │
 ▼
Instance Profile
 │
 ▼
IAM Role
 │
 ├── SSM
 ├── CloudWatch
 └── CloudWatch Logs
```

Applications such as the CloudWatch Agent and SSM Agent can use the role credentials through the AWS SDK/credential provider chain.

---

# 18. No Hardcoded Credentials

The project does not store:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

inside:

- Python scripts
- Shell scripts
- Lambda source code
- EC2 configuration files
- CloudWatch Agent configuration

Instead, AWS services obtain temporary credentials through IAM roles.

This reduces the risk of credential leakage.

---

# 19. Principle of Least Privilege

The project follows the Principle of Least Privilege.

Each workload receives only the permissions required for its function.

| Workload | Required Access |
|---|---|
| EC2 / SSM Agent | Systems Manager communication |
| EC2 / CloudWatch Agent | Publish monitoring data |
| Lambda | Execute required SSM command |
| Lambda | Write CloudWatch Logs |
| Lambda | Publish required SNS notification |
| CloudWatch Alarm | Trigger configured SNS action |

Avoid granting broad administrator permissions to EC2 or Lambda.

---

# 20. Resource-Based Policies

Some AWS services can also use resource-based policies.

For this project, the important distinction is:

### Identity-Based Policy

Attached to an IAM user, group, or role.

Examples:

```text
EC2 IAM Role
Lambda Execution Role
```

### Resource-Based Policy

Attached directly to a resource.

Examples include:

```text
SNS Topic Policy
Lambda Resource Policy
```

For example, the SNS topic can have a resource policy controlling which principals are allowed to publish to it.

---

# 21. SNS Resource Policy Concept

Example structure:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSpecificPrincipal",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:role/Cloudops-NOC-Lambda-Execution-Role"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:ap-south-1:ACCOUNT_ID:cloudops-sns"
    }
  ]
}
```

The exact resource policy should be adapted to the actual project configuration.

---

# 22. IAM Security Controls

The project implements the following IAM security controls:

- IAM Roles instead of permanent access keys.
- Separate EC2 and Lambda roles.
- Least-privilege permissions.
- Service-specific trust policies.
- No credentials embedded in application code.
- CloudWatch logging for Lambda execution.
- Controlled Systems Manager access.
- Controlled SNS publishing.

---

# 23. IAM Verification

The following AWS CLI commands can be used for inspection and verification.

## List IAM Roles

```bash
aws iam list-roles
```

## Get EC2 Role

```bash
aws iam get-role \
  --role-name cloudops-EC2-inline-role
```

## List Role Policies

```bash
aws iam list-role-policies \
  --role-name cloudops-EC2-inline-role
```

## Get Inline Policy

```bash
aws iam get-role-policy \
  --role-name cloudops-EC2-inline-role \
  --policy-name POLICY_NAME
```

## List Attached Policies

```bash
aws iam list-attached-role-policies \
  --role-name cloudops-EC2-inline-role
```

These commands are intended for inspection and verification.

---

# 24. IAM Troubleshooting

## Problem: SSM Agent Cannot Register

Check:

```text
EC2 IAM Role
        │
        ▼
AmazonSSMManagedInstanceCore
```

Verify:

- IAM role is attached to EC2.
- Instance Profile is associated correctly.
- SSM Agent is running.
- EC2 has required network connectivity.

---

## Problem: CloudWatch Metrics Are Missing

Check:

```text
CloudWatch Agent
       │
       ▼
EC2 IAM Role
       │
       ▼
cloudwatch:PutMetricData
```

Verify:

- CloudWatch Agent is running.
- IAM role is attached.
- Required CloudWatch permissions exist.
- Agent configuration is correct.

---

## Problem: Lambda Cannot Execute SSM Command

Check:

```text
Lambda
  │
  ▼
Lambda Execution Role
  │
  ▼
ssm:SendCommand
```

Verify:

- Correct execution role is attached.
- `ssm:SendCommand` permission exists.
- Target EC2 instance is a managed node.
- SSM Agent is online.

---

## Problem: Lambda Cannot Publish SNS Notification

Verify:

```text
sns:Publish
```

and confirm the policy resource points to the correct SNS topic ARN.

---

## Problem: Lambda Logs Are Missing

Verify that the Lambda execution role has:

```text
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

Then check the Lambda log group in CloudWatch Logs.

---

# 25. IAM Relationship With the Seven Project Services

| Service | IAM Relationship |
|---|---|
| IAM | Provides identity and authorization |
| EC2 | Uses an IAM Instance Profile |
| VPC | Provides network isolation; IAM controls AWS API access separately |
| CloudWatch | Receives metrics and stores logs through authorized roles |
| SNS | Distributes notifications and can use resource policies |
| Systems Manager | Uses EC2 role for SSM Agent communication |
| Lambda | Uses an execution role for AWS API operations |

---

# 26. Security Best Practices

The following practices should be maintained throughout the project:

- Never hardcode AWS access keys.
- Never commit credentials to GitHub.
- Use IAM Roles for EC2 and Lambda.
- Use separate roles for separate workloads.
- Keep permissions as narrow as practical.
- Review IAM policies regularly.
- Remove unused permissions.
- Restrict resource ARNs where supported.
- Monitor failed AWS API calls.
- Use CloudTrail in production environments when centralized API auditing is required.

---

# 27. Current Project Scope

The IAM implementation supports the project's current automation scope:

```text
P1 — Apache HTTPD Auto-Remediation
P2 — CPU Utilization Monitoring
```

IAM permissions should support these implemented workflows without introducing unnecessary permissions for unrelated automation.

The project does not require additional IAM roles for unused services or future technologies until those technologies are actually implemented.

---

# 28. Final IAM Architecture

```text
                         IAM
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
      EC2 IAM Role             Lambda Execution Role
             │                         │
             ├── SSM                  ├── SSM
             │                        ├── SNS
             ├── CloudWatch           └── CloudWatch Logs
             │
             └── CloudWatch Logs
                          │
                          ▼
                    AWS Services
```

IAM acts as the authorization layer that connects the project's compute, monitoring, notification, and automation components securely.

---

# Conclusion

AWS IAM is a critical security component of the CloudOps NOC Automation project.

The EC2 instance uses an IAM Instance Profile to obtain temporary credentials for Systems Manager and CloudWatch operations. Lambda uses a separate execution role to execute SSM commands, write execution logs, and publish remediation notifications.

By separating roles, using service-specific trust policies, avoiding hardcoded credentials, and applying least-privilege permissions, the project establishes a secure authorization model for its seven-service AWS architecture.

The IAM configuration should always be maintained together with its JSON policies, trust relationships, and verification procedures so that the complete environment can be reproduced and securely maintained.
