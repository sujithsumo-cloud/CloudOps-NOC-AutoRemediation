# IAM Roles Used in the Project

## EC2 IAM Role

### Purpose

Allows the EC2 instance to communicate with AWS Systems Manager.

### Managed Policy

AmazonSSMManagedInstanceCore

### Used By

- Systems Manager
- Run Command
- Session Manager
- Inventory

---

## Lambda Execution Role

### Purpose

Allows Lambda to invoke Systems Manager and write logs.

### Managed Policies

AWSLambdaBasicExecutionRole

Custom SSM Policy

---

# Service Communication

CloudWatch

↓

SNS

↓

Lambda

↓

IAM Role

↓

Systems Manager

↓

EC2 IAM Role

↓

Apache Restart

---

# Why Roles?

Roles eliminate the need to store AWS Access Keys inside applications.

AWS automatically provides temporary credentials whenever a service assumes a role.
