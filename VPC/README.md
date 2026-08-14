# Amazon VPC Configuration

## Overview

Amazon Virtual Private Cloud (VPC) provides the network foundation for the CloudOps NOC Automation project.

The VPC isolates the EC2-based Apache web server within a dedicated AWS network and provides controlled connectivity between the server, the internet, and AWS managed services used by the automation workflow.

The VPC is part of the project's seven-service AWS architecture:

- IAM
- EC2
- VPC
- CloudWatch
- SNS
- Systems Manager (SSM)
- Lambda

---

# 1. Purpose

The VPC is responsible for providing:

- Network isolation for the EC2 instance
- IP addressing through a private CIDR range
- Public connectivity for the Apache server
- Routing between the subnet and the internet
- Network-level access control through Security Groups
- Connectivity required by CloudWatch Agent and SSM Agent

---

# 2. VPC Architecture

The project uses a simple single-VPC architecture.

```text
                         Internet
                            │
                            ▼
                  Internet Gateway
                     cloudops-igw
                            │
                            ▼
                     Route Table
                      cloudops-rt
                            │
                            ▼
              ┌─────────────────────────┐
              │      cloudops-vpc       │
              │       10.0.0.0/16       │
              │                         │
              │   Public Subnet         │
              │   10.0.1.0/24           │
              │        │                │
              │        ▼                │
              │   EC2 Instance          │
              │   cloudops-server       │
              │        │                │
              │   cloudops-sg            │
              └─────────────────────────┘
```

---

# 3. VPC Configuration

| Property | Value |
|---|---|
| VPC Name | cloudops-vpc |
| CIDR Block | 10.0.0.0/16 |
| IPv4 | Enabled |
| Region | ap-south-1 |
| Purpose | CloudOps NOC infrastructure |

The `10.0.0.0/16` CIDR provides a large private IP address range for the project and allows future expansion.

---

# 4. Subnet Configuration

The EC2 instance is deployed inside a public subnet.

| Property | Value |
|---|---|
| Subnet Name | cloudops-subnet |
| CIDR | 10.0.1.0/24 |
| Type | Public |
| Availability Zone | ap-south-1a |
| Purpose | Hosts EC2 instance |

The subnet is considered public because its associated route table contains a default route to the Internet Gateway.

---

# 5. Internet Gateway

## Resource

```text
cloudops-igw
```

The Internet Gateway provides internet connectivity for resources in the public subnet.

Traffic flow:

```text
EC2
 │
 ▼
Public Subnet
 │
 ▼
Route Table
 │
 ▼
Internet Gateway
 │
 ▼
Internet
```

The Internet Gateway does not provide access by itself. The subnet must also have an appropriate route through its route table, and the EC2 instance must have a public IPv4 address when direct internet communication is required.

---

# 6. Route Table

## Route Table

```text
cloudops-rt
```

The route table contains the default internet route.

| Destination | Target |
|---|---|
| 10.0.0.0/16 | Local |
| 0.0.0.0/0 | cloudops-igw |

The local route allows communication within the VPC.

The `0.0.0.0/0` route sends internet-bound traffic through the Internet Gateway.

---

# 7. Route Table Association

The route table is associated with:

```text
cloudops-subnet
```

This association makes the subnet use the configured routes.

```text
cloudops-vpc
      │
      └── cloudops-subnet
                │
                └── cloudops-rt
                         │
                         └── 0.0.0.0/0
                                  │
                                  ▼
                           cloudops-igw
```

---

# 8. Security Group

The EC2 instance uses:

```text
cloudops-sg
```

The Security Group provides stateful network-level access control.

## Inbound Rules

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 22 | Administrator/My IP | Administrative access |
| TCP | 80 | 0.0.0.0/0 | Apache HTTP access |

Port `22` should be restricted to the administrator's trusted IP address rather than being exposed to the entire internet.

Port `80` is open to the internet because the Apache web server is intended to receive HTTP requests.

## Outbound Rules

The project currently allows outbound traffic.

Outbound connectivity is required for the EC2 instance to communicate with AWS services and external resources.

---

# 9. EC2 Network Flow

The Apache server is deployed inside the VPC as follows:

```text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Route Table
   │
   ▼
Public Subnet
   │
   ▼
Security Group
   │
   ▼
EC2 Instance
   │
   ▼
Apache HTTP Server
```

---

# 10. AWS Service Communication

The VPC provides the network environment for the EC2 instance, while AWS managed services handle monitoring and automation.

```text
                    AWS Cloud
                       │
          ┌────────────┴────────────┐
          │                         │
      CloudWatch                  SNS
          │                         │
          │                         ▼
          │                       Lambda
          │                         │
          │                         ▼
          │                        SSM
          │                         │
          └──────────┬──────────────┘
                     │
                     ▼
              EC2 Instance
              cloudops-server
                     │
                     ▼
              Apache / httpd
```

The EC2 instance uses its IAM role to authenticate to AWS APIs. Network connectivity and IAM authorization are separate controls: being able to reach an AWS service does not by itself grant permission to use it.

---

# 11. VPC and Systems Manager

AWS Systems Manager is used to remotely execute commands on the EC2 instance.

The workflow is:

```text
Lambda
   │
   ▼
SSM Run Command
   │
   ▼
SSM Agent on EC2
   │
   ▼
systemctl restart httpd
```

The EC2 instance requires network connectivity to the Systems Manager service endpoints.

The SSM Agent communicates outbound to AWS services, eliminating the need for inbound SSH access for the automated remediation workflow.

---

# 12. VPC and CloudWatch

The CloudWatch Agent runs on the EC2 instance and publishes system metrics to CloudWatch.

```text
EC2
 │
 └── CloudWatch Agent
          │
          ▼
      CloudWatch
          │
          ▼
       Alarm
          │
          ▼
         SNS
```

The EC2 instance requires outbound network connectivity for the CloudWatch Agent to communicate with CloudWatch endpoints.

---

# 13. Network Security Design

The project uses multiple layers of network and identity controls.

### Layer 1 — VPC

Provides logical network isolation.

### Layer 2 — Subnet

Defines the network segment where the EC2 instance operates.

### Layer 3 — Route Table

Controls where network traffic is routed.

### Layer 4 — Internet Gateway

Provides internet connectivity for the public subnet.

### Layer 5 — Security Group

Controls inbound and outbound network traffic to the EC2 instance.

### Layer 6 — IAM

Controls whether the EC2 instance and AWS services are authorized to call AWS APIs.

---

# 14. Important Network Security Considerations

The current project uses a public subnet because the Apache server needs to be reachable through HTTP.

For a production environment, the architecture can be hardened by:

- Restricting SSH to trusted administrator IP addresses.
- Preferably using Systems Manager Session Manager instead of SSH.
- Placing application servers in private subnets.
- Using an Application Load Balancer for public traffic.
- Using HTTPS instead of plain HTTP.
- Using separate public and private subnets.
- Restricting outbound traffic where practical.

These are future enhancements and are not part of the current implemented seven-service project scope.

---

# 15. VPC Verification Commands

The following Linux commands can be used on the EC2 instance to verify network configuration.

## Display IP Addresses

```bash
ip addr
```

## Display Routing Table

```bash
ip route
```

## Check DNS Resolution

```bash
nslookup amazon.com
```

or:

```bash
getent hosts amazon.com
```

## Test Internet Connectivity

```bash
curl -I https://aws.amazon.com
```

## Check Apache

```bash
systemctl status httpd
```

## Check Listening Ports

```bash
ss -tulnp
```

---

# 16. AWS CLI Verification

If AWS CLI is used for verification, the following commands can be used.

## List VPCs

```bash
aws ec2 describe-vpcs
```

## List Subnets

```bash
aws ec2 describe-subnets
```

## List Route Tables

```bash
aws ec2 describe-route-tables
```

## List Internet Gateways

```bash
aws ec2 describe-internet-gateways
```

## List Security Groups

```bash
aws ec2 describe-security-groups
```

These commands are for inspection and verification of the infrastructure.

---

# 17. VPC Troubleshooting

## Problem: EC2 Cannot Reach the Internet

Check:

```text
EC2
 ↓
Subnet
 ↓
Route Table
 ↓
Internet Gateway
```

Verify:

1. EC2 has a public IPv4 address if direct internet access is required.
2. The subnet is associated with the correct route table.
3. Route `0.0.0.0/0` points to the Internet Gateway.
4. Security Group outbound traffic permits the connection.
5. Network ACLs are not blocking traffic.
6. DNS resolution is working.

---

## Problem: Apache Cannot Be Accessed

Check:

```bash
systemctl status httpd
```

Then verify:

```bash
ss -tulnp | grep :80
```

Also verify that Security Group port `80` is allowed.

---

## Problem: SSM Managed Node Is Offline

Check:

```bash
sudo systemctl status amazon-ssm-agent
```

Then verify:

- EC2 IAM role
- Network connectivity
- SSM Agent status
- AWS Systems Manager managed-node status

---

## Problem: CloudWatch Metrics Are Missing

Check:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

Then inspect:

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

Also verify:

- IAM permissions
- Network connectivity
- Agent configuration
- CloudWatch namespace and metric configuration

---

# 18. VPC Relationship With Project Services

| Service | Relationship With VPC |
|---|---|
| IAM | Controls authorization for EC2 and AWS API access |
| EC2 | Runs inside the VPC |
| VPC | Provides network infrastructure |
| CloudWatch | Receives EC2 monitoring metrics |
| SNS | Receives alarm notifications |
| SSM | Communicates with the EC2 SSM Agent |
| Lambda | Executes the remediation workflow |

---

# 19. Current Project Scope

The implemented network architecture intentionally remains simple.

```text
1 VPC
   │
   └── 1 Public Subnet
           │
           └── 1 EC2 Instance
                   │
                   ├── Apache
                   ├── CloudWatch Agent
                   └── SSM Agent
```

The project does not currently implement:

- Multiple Availability Zones
- NAT Gateway
- Application Load Balancer
- Auto Scaling Group
- Private application subnets
- Multi-tier application architecture

These can be introduced as future enhancements without changing the core CloudOps NOC automation workflow.

---

# 20. Best Practices

- Use meaningful resource names.
- Use CIDR ranges that allow future expansion.
- Restrict administrative access.
- Avoid exposing unnecessary ports.
- Prefer Systems Manager over SSH for administration.
- Use IAM roles instead of static credentials.
- Monitor EC2 network and system health.
- Document route-table and Security Group changes.
- Review inbound and outbound rules periodically.

---

# 21. Final Architecture Summary

The VPC provides the network foundation for the CloudOps NOC Automation project.

The architecture consists of:

```text
cloudops-vpc
    │
    ├── cloudops-subnet
    │       │
    │       └── cloudops-server
    │                │
    │                ├── Apache
    │                ├── CloudWatch Agent
    │                └── SSM Agent
    │
    ├── cloudops-rt
    │
    ├── cloudops-igw
    │
    └── cloudops-sg
```

This network foundation enables the EC2 server to communicate with the AWS services required for monitoring, notification, and automated remediation.

---

# Conclusion

Amazon VPC forms the networking foundation of the CloudOps NOC Automation project. It provides logical isolation, IP addressing, routing, internet connectivity, and network-level access control for the EC2-based Apache server.

The VPC works together with IAM, EC2, CloudWatch, SNS, Lambda, and Systems Manager to support the complete monitoring and auto-remediation workflow.

The current design is intentionally simple and suitable for the project's single-EC2 NOC automation environment while leaving a clear path for future expansion into private subnets, load balancing, multiple Availability Zones, and Auto Scaling.
