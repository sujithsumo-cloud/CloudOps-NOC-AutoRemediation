# AWS Identity and Access Management (IAM) — Authorization and Least Privilege

## Overview

AWS Identity and Access Management (IAM) is the **authorization and access-control layer** of the CloudOps NOC Automation V2.0 project.

IAM controls which AWS identities and services are allowed to perform specific AWS API operations on project resources.

The project uses IAM roles and policies so that EC2 and Lambda can interact with AWS services without storing permanent AWS access keys in application code.

In simple terms:

> **IAM answers: Who or which service is allowed to do what on which AWS resource?**

---

## 1. Role in the Project

IAM is used to:

- Provide AWS permissions to the EC2 instance.
- Provide AWS permissions to the Lambda function.
- Allow the CloudWatch Agent to publish monitoring data.
- Allow the SSM Agent to operate as a managed-node agent.
- Allow Lambda to call Systems Manager.
- Allow Lambda to read SSM command results.
- Allow Lambda to publish operational notifications to SNS.
- Allow Lambda to read required EC2 instance details.
- Allow Lambda to write execution logs.
- Allow Lambda to use the SSM Parameter Store incident counter.
- Avoid hardcoded permanent AWS credentials.
- Apply the **Principle of Least Privilege**.

IAM does not monitor the server, restart HTTPD, or send notifications itself.

---

## 2. IAM Architecture

The project uses separate IAM permission paths for EC2 and Lambda.

```text
                         AWS IAM
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
        EC2 Instance Role          Lambda Execution Role
              │                           │
       ┌──────┴──────┐             ┌──────┼───────────┐
       ▼             ▼             ▼      ▼           ▼
CloudWatch Agent   SSM Agent      SSM     SNS         EC2
       │             │             │      │           │
       ▼             ▼             ▼      ▼           ▼
   Metrics/Logs   Managed Node   Commands Notify   Read Details
```

The two roles have different responsibilities.

---

## 3. IAM Components Used

| IAM Concept | Project Purpose |
|---|---|
| IAM Role | Provides temporary AWS credentials to a service/workload |
| Trust Policy | Defines which service/principal may assume a role |
| Permission Policy | Defines what actions the assumed role may perform |
| Inline Policy | Policy embedded directly in a role or identity |
| Managed Policy | Reusable policy managed by AWS or the customer |
| Instance Profile | Makes an IAM role available to EC2 |
| Resource-Based Policy | Policy attached directly to supported AWS resources |
| Least Privilege | Grants only the permissions required for a responsibility |

---

## 4. EC2 IAM Role

### Current Project Role

```text
cloudops-EC2-inline-role
```

The EC2 role provides temporary AWS credentials to software running on the instance.

Important consumers include:

```text
CloudWatch Agent
SSM Agent
```

Conceptually:

```text
EC2
 │
 ▼
Instance Profile
 │
 ▼
EC2 IAM Role
 │
 ├── CloudWatch permissions
 └── Systems Manager permissions
```

---

## 5. EC2 Role — CloudWatch Permissions

The repository policy `cloudops-EC2-inline-role.json` allows the EC2-side monitoring components to publish CloudWatch Agent metrics.

The policy includes:

```text
cloudwatch:PutMetricData
```

and restricts the metric-publishing statement to the:

```text
CWAgent
```

namespace.

The policy also contains CloudWatch read permissions such as:

```text
cloudwatch:GetMetricData
cloudwatch:GetMetricStatistics
cloudwatch:ListMetrics
cloudwatch:DescribeAlarms
```

This supports monitoring and project verification.

---

## 6. EC2 Role — CloudWatch Logs Permissions

The current EC2 policy contains log permissions including:

```text
logs:CreateLogGroup
logs:CreateLogStream
logs:DescribeLogGroups
logs:DescribeLogStreams
logs:PutLogEvents
```

It also contains read operations used for troubleshooting.

These permissions support configured CloudWatch Agent log collection.

---

## 7. EC2 Role — Systems Manager Permissions

The EC2 role contains the permissions required by the SSM Agent to operate as a Systems Manager managed node.

The current repository policy includes SSM-related operations and the communication channels required by the agent.

Conceptually:

```text
EC2
 │
 ▼
SSM Agent
 │
 ▼
EC2 IAM Role
 │
 ▼
Authorized SSM Communication
 │
 ▼
AWS Systems Manager
```

The role also includes the message-channel permissions required for Systems Manager communication.

---

## 8. EC2 Role — Additional Read Permissions

The current EC2 role policy includes read operations such as:

```text
ec2:DescribeInstances
ec2:DescribeTags
ec2:DescribeVolumes
```

and selected Parameter Store read operations.

These are supporting permissions and should remain limited to what the deployed agents and project workflow require.

---

## 9. EC2 Trust Policy

The EC2 role must trust the EC2 service.

Conceptually:

```json
{
  "Principal": {
    "Service": "ec2.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

Meaning:

> **Amazon EC2 is allowed to assume this role.**

The trust policy answers:

> **Who may assume the role?**

The permission policy answers:

> **What may the assumed role do?**

---

## 10. Lambda Execution Role

Lambda uses a separate execution role.

The current project-specific Lambda policy is stored in:

```text
cloudops-lambda-inline-policy.json
```

The policy is designed around the operations required by the current automation workflow.

Conceptually:

```text
Lambda
   │
   ▼
Lambda Execution Role
   │
   ├── SSM
   ├── SNS
   ├── EC2 Read
   ├── Parameter Store
   └── CloudWatch Logs
```

---

## 11. Lambda Permission — Incident Counter

The current Lambda policy allows:

```text
ssm:GetParameter
ssm:PutParameter
```

for the project incident-counter parameter path.

The Lambda function uses this to generate sequential incident IDs.

Conceptually:

```text
Lambda
   │
   ▼
Parameter Store
   │
   ▼
Read Counter
   │
   ▼
Increment
   │
   ▼
Write Counter
```

This permission is separate from SSM Run Command.

---

## 12. Lambda Permission — Read EC2 Details

The current Lambda policy allows:

```text
ec2:DescribeInstances
```

Lambda uses this read-only permission to obtain required instance information for incident context and notifications.

This does **not** give Lambda permission to terminate, reboot, or modify the EC2 instance.

---

## 13. Lambda Permission — SSM SendCommand

The current Lambda policy allows:

```text
ssm:SendCommand
```

The policy scopes the SendCommand permission to:

- The project EC2 target.
- The AWS-managed `AWS-RunShellScript` SSM document.

Conceptually:

```text
Lambda
   │
   ▼
IAM Authorization
   │
   ▼
ssm:SendCommand
   │
   ▼
Systems Manager
```

This is a strong example of **least-privilege resource scoping**.

---

## 14. Lambda Permission — Read SSM Command Result

The current Lambda policy also allows:

```text
ssm:GetCommandInvocation
```

This is required because sending a command is not enough.

Lambda must retrieve the command status and output to determine whether:

```text
Success
Failed
TimedOut
Cancelled
```

occurred.

---

## 15. Lambda Permission — SNS Publish

The current Lambda policy allows:

```text
sns:Publish
```

to the project SNS topic:

```text
cloudops-sns
```

Correct flow:

```text
Lambda
   │
   ▼
IAM authorizes sns:Publish
   │
   ▼
SNS
   │
   ▼
Operations Engineer
```

Important:

> **SNS is downstream of Lambda in the current V2.0 architecture.**

It is not the service that triggers Lambda.

---

## 16. Lambda Permission — CloudWatch Logs

The Lambda policy permits the function to create and write its execution logs.

Typical operations include:

```text
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

These permissions allow Lambda execution details and errors to be written to CloudWatch Logs.

---

## 17. Lambda Trust Policy

The Lambda execution role must trust the Lambda service.

Conceptually:

```json
{
  "Principal": {
    "Service": "lambda.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

Meaning:

> **AWS Lambda is allowed to assume the execution role.**

---

## 18. Trust Policy vs Permission Policy

This distinction is important.

### Trust Policy

Answers:

> **Who can assume this role?**

Example:

```text
EC2 Role
→ trusts ec2.amazonaws.com

Lambda Role
→ trusts lambda.amazonaws.com
```

### Permission Policy

Answers:

> **What can the role do after it is assumed?**

Example:

```text
Lambda Role
→ ssm:SendCommand
→ ssm:GetCommandInvocation
→ sns:Publish
→ ec2:DescribeInstances
```

Easy memory:

```text
Trust Policy
= WHO can become the role?

Permission Policy
= WHAT can the role do?
```

---

## 19. Identity-Based vs Resource-Based Policy

### Identity-Based Policy

Attached to:

```text
User
Group
Role
```

Examples in this project:

```text
EC2 IAM Role policy
Lambda execution-role policy
IAM group permission policy
```

### Resource-Based Policy

Attached directly to a supported AWS resource.

Examples can include:

```text
SNS Topic Policy
Lambda Resource-Based Policy
```

For the current architecture, Lambda's execution-role permissions authorize Lambda to call SSM and SNS.

A Lambda resource-based policy can separately control which AWS service is allowed to invoke the Lambda function.

---

## 20. Direct CloudWatch → Lambda Authorization

The current V2.0 event path is:

```text
CloudWatch Alarm
      │
      ▼
Lambda
```

The old documentation path:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

is not the current design.

IAM documentation must therefore not describe SNS as the Lambda trigger.

The authorization model should be understood as:

```text
CloudWatch Alarm
      │
      ▼
Lambda Invocation
      │
      ▼
Lambda Execution Role
      │
      ├── SSM API
      ├── SNS API
      ├── EC2 Read
      └── CloudWatch Logs
```

The Lambda execution role controls what Lambda can do **after Lambda starts running**.

---

## 21. IAM and P1

P1 authorization flow:

```text
CloudWatch
   │
   ▼
Lambda
   │
   ▼
Lambda Execution Role
   │
   ▼
ssm:SendCommand
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2
   │
   ▼
systemctl restart httpd
```

Lambda can request the approved command only if IAM authorizes the API call.

---

## 22. IAM and P2

P2 uses the same controlled SSM execution mechanism, but the command purpose is different.

```text
cpu alert
   │
   ▼
Lambda
   │
   ▼
IAM Authorization
   │
   ▼
SSM
   │
   ▼
Diagnostic Commands
```

P2 performs diagnosis only.

IAM does not decide P1 vs P2.

Lambda makes that decision.

---

## 23. Principle of Least Privilege

The project follows:

> **Give each identity only the permissions required for its responsibility.**

Examples:

### Lambda needs

```text
Send approved SSM commands
Read command results
Read required instance details
Read/write incident counter
Publish to project SNS topic
Write Lambda logs
```

Lambda does **not** require unrestricted EC2 administrator permissions for the current workflow.

### EC2 needs

```text
CloudWatch Agent permissions
SSM Agent permissions
Required supporting read operations
```

This limits the blast radius if a role is misused.

---

## 24. Explicit Deny

AWS permission evaluation gives an explicit `Deny` higher priority than an `Allow`.

Conceptually:

```text
Allow
+
Explicit Deny
=
Denied
```

This is useful to understand during IAM troubleshooting.

A valid `Allow` statement is not enough if another applicable policy explicitly denies the same action.

---

## 25. No Hardcoded Credentials

The project should not store permanent credentials such as:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

inside:

```text
Lambda source code
EC2 scripts
CloudWatch Agent configuration
Shell scripts
GitHub repository files
```

Instead:

```text
AWS Service
   │
   ▼
IAM Role
   │
   ▼
Temporary Credentials
```

This reduces credential exposure risk.

---

## 26. IAM Group Policy in the Repository

The IAM folder also contains:

```text
IAM Group Permision.json
```

This policy is different from the **runtime service roles**.

It represents permissions for an IAM operator/group to create, inspect, or manage project infrastructure and related resources.

Examples in the file include permissions covering:

- Project IAM roles and instance profiles.
- `iam:PassRole`.
- EC2 lifecycle operations.
- VPC networking operations.
- CloudWatch alarms and dashboards.
- CloudWatch Logs troubleshooting.
- SNS operations.

This policy should not be confused with:

```text
cloudops-EC2-inline-role.json
```

or:

```text
cloudops-lambda-inline-policy.json
```

Those are workload/runtime permission policies.

---

## 27. IAM Group Policy vs Service Role

Easy distinction:

```text
IAM Group Policy
= What the human/operator identity can manage

EC2 Role
= What software running on EC2 can access

Lambda Role
= What Lambda can call during execution
```

Keeping these separate makes the security model easier to explain.

---

## 28. `iam:PassRole`

`iam:PassRole` is important when an authorized user or service assigns an IAM role to another AWS service.

Conceptually:

```text
Operator
   │
   ▼
Create / Configure EC2 or Lambda
   │
   ▼
Pass Approved Role
   │
   ▼
AWS Service Uses Role
```

`iam:PassRole` does not mean the operator assumes that role.

It means the operator is authorized to pass the role to the supported AWS service.

---

## 29. IAM Troubleshooting

### Lambda gets `AccessDenied` for SSM

Check:

```text
Lambda Execution Role
       │
       ▼
ssm:SendCommand
       │
       ▼
Target Instance + SSM Document
```

Verify that the target resource matches the policy scope.

### Lambda can send command but cannot read result

Check:

```text
ssm:GetCommandInvocation
```

### SNS notification fails

Check:

```text
sns:Publish
```

and verify the topic ARN matches the policy.

### Incident counter fails

Check:

```text
ssm:GetParameter
ssm:PutParameter
```

and verify the Parameter Store path matches the policy.

### EC2 is not an SSM managed node

Check:

- EC2 role attachment.
- SSM Agent status.
- Required SSM Agent permissions.
- Network connectivity.

### CloudWatch Agent cannot publish metrics

Check:

```text
cloudwatch:PutMetricData
```

and the `CWAgent` namespace condition.

---

## 30. IAM Verification

Useful AWS CLI inspection commands include:

```bash
aws iam list-roles
```

```bash
aws iam get-role --role-name <ROLE_NAME>
```

```bash
aws iam list-role-policies --role-name <ROLE_NAME>
```

```bash
aws iam get-role-policy \
  --role-name <ROLE_NAME> \
  --policy-name <POLICY_NAME>
```

These commands are useful for inspection and troubleshooting.

---

## 31. Integration with the Seven AWS Services

| Service | IAM Relationship |
|---|---|
| VPC | Operator permissions may control VPC resource management |
| EC2 | Uses an instance role for CloudWatch/SSM access |
| CloudWatch | Receives metrics/logs through authorized agents |
| Lambda | Uses an execution role for runtime AWS API calls |
| SSM | Requires permissions on both Lambda and EC2 sides |
| SNS | Lambda requires permission to publish notifications |
| IAM | Provides the authorization model across the workflow |

---

## 32. Three-Level Interview Answer

### Level 1

> **IAM is the authorization and least-privilege access-control layer of my project.**

### Level 2

> **The project uses separate IAM roles for EC2 and Lambda. The EC2 role allows the CloudWatch Agent and SSM Agent to communicate with AWS services, while the Lambda role allows only the required operations such as SSM command execution, command-result retrieval, SNS publishing, EC2 read access, Parameter Store access, and logging.**

### Level 3

> **The Lambda inline policy scopes `ssm:SendCommand` to the approved EC2 target and `AWS-RunShellScript`, allows `ssm:GetCommandInvocation`, permits `sns:Publish` only to the project SNS topic, provides `ec2:DescribeInstances`, and grants read/write access to the project incident-counter parameter path. The EC2 policy allows CloudWatch Agent metrics in the `CWAgent` namespace, log publishing, supporting EC2 reads, and the SSM Agent communication actions required for managed-node operation. Trust policies separately define which AWS service may assume each role.**

---

## 33. Operational Summary

IAM can be remembered as:

```text
IDENTITY
   │
   ▼
ASSUME ROLE
   │
   ▼
TEMPORARY CREDENTIALS
   │
   ▼
POLICY EVALUATION
   │
   ▼
ALLOW / DENY
```

Easy interview memory:

```text
Trust Policy
= Who can assume?

Permission Policy
= What can they do?

Least Privilege
= Only what is required.
```

---

## 34. Final Architecture Summary

```text
CloudWatch Alarm
      │
      ▼
Lambda
      │
      ▼
Lambda Execution Role
      │
      ├── SSM SendCommand
      ├── SSM GetCommandInvocation
      ├── Parameter Store
      ├── EC2 Describe
      ├── SNS Publish
      └── CloudWatch Logs

EC2
 │
 ▼
EC2 Instance Role
 │
 ├── CloudWatch Agent
 └── SSM Agent
```

IAM surrounds the operational workflow by controlling every AWS API action.

---

## Key Design Statement

> **IAM does not perform monitoring or remediation. It authorizes the services that do. The project separates EC2 and Lambda permissions, uses role-based temporary credentials, and applies least privilege so each component can perform only the AWS actions required by its responsibility.**
