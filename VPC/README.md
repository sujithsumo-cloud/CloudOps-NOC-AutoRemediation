# Amazon VPC — Network Foundation and Connectivity

## Overview

Amazon Virtual Private Cloud (Amazon VPC) provides the **network foundation** for the CloudOps NOC Automation V2.0 project.

The VPC provides the logically isolated AWS network in which the EC2-based Apache HTTPD server runs. It defines the IP address space, subnet, routing, internet connectivity, and network-level access controls required by the workload.

The project uses a simple single-VPC design:

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
cloudops-vpc
10.0.0.0/16
   │
   ▼
Public Subnet
10.0.0.0/28
   │
   ▼
Security Group
   │
   ▼
EC2
cloudops-server
   │
   ▼
Apache HTTPD
```

In simple terms:

> **VPC provides the network environment. EC2 runs the workload. CloudWatch monitors it. Lambda decides. SSM executes. SNS notifies. IAM authorizes.**

---

## 1. Role in the Project

The VPC is responsible for:

- Providing a logically isolated AWS network.
- Defining the private IPv4 address range.
- Hosting the EC2 subnet.
- Providing routing between the subnet and the internet.
- Supporting public HTTP access to the Apache server.
- Applying Security Group rules to the EC2 network interface.
- Providing the network environment required by the CloudWatch Agent and SSM Agent.
- Supporting communication between the EC2 instance and required AWS service endpoints.

The VPC does **not** perform monitoring, incident classification, remediation, or notification.

---

## 2. Current VPC Configuration

| Property | Current Project Value |
|---|---|
| VPC Name | `cloudops-vpc` |
| CIDR Block | `10.0.0.0/16` |
| IPv4 | Enabled |
| Region | `ap-south-1` |
| Purpose | CloudOps NOC network foundation |

The `10.0.0.0/16` CIDR provides the private address space for the VPC and leaves room for future subnet expansion.

---

## 3. Current Network Architecture

```text
                         Internet
                            │
                            ▼
                     cloudops-igw
                    Internet Gateway
                            │
                            ▼
                      cloudops-rt
                       Route Table
                            │
                            ▼
              ┌───────────────────────────┐
              │       cloudops-vpc        │
              │        10.0.0.0/16        │
              │                           │
              │   cloudops-subnet         │
              │      10.0.0.0/28          │
              │       Public              │
              │          │                │
              │          ▼                │
              │     cloudops-server       │
              │        EC2                │
              │          │                │
              │     cloudops-sg           │
              └───────────────────────────┘
```

The current design intentionally uses:

```text
1 VPC
1 Public Subnet
1 EC2 Instance
```

This keeps the implementation simple and aligned with the project scope.

---

## 4. Subnet Configuration

The EC2 instance is deployed in:

```text
cloudops-subnet
```

| Property | Current Project Value |
|---|---|
| Subnet Name | `cloudops-subnet` |
| CIDR | `10.0.0.0/28` |
| Type | Public |
| Availability Zone | `ap-south-1a` |
| Purpose | Hosts the EC2 workload |

The subnet is considered public because its associated route table has a default route to an Internet Gateway.

Important:

> A subnet is not public only because it has a public IP range. It is public because its routing allows internet-bound traffic through an Internet Gateway.

---

## 5. Internet Gateway

The project uses:

```text
cloudops-igw
```

The Internet Gateway enables internet connectivity between the VPC and the public internet when the required routing and resource configuration are present.

Conceptually:

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

The Internet Gateway alone does not make a resource reachable.

The EC2 instance also requires:

- An appropriate public IPv4 configuration for direct internet communication.
- A route to the Internet Gateway.
- Security Group rules that allow the intended traffic.

---

## 6. Route Table

The project route table is:

```text
cloudops-rt
```

Current important routes:

| Destination | Target |
|---|---|
| `10.0.0.0/16` | Local |
| `0.0.0.0/0` | `cloudops-igw` |

The local route provides internal VPC routing.

The default route:

```text
0.0.0.0/0
```

sends internet-bound IPv4 traffic toward the Internet Gateway.

---

## 7. Route Table Association

`cloudops-rt` is associated with:

```text
cloudops-subnet
```

Conceptually:

```text
cloudops-vpc
     │
     ▼
cloudops-subnet
     │
     ▼
cloudops-rt
     │
     ▼
0.0.0.0/0
     │
     ▼
cloudops-igw
```

The route table determines **where traffic should go**.

It does not determine whether the traffic is authorized.

---

## 8. Security Group

The EC2 instance uses:

```text
cloudops-sg
```

A Security Group is a **stateful virtual firewall** associated with the EC2 network interface.

### Current Inbound Intent

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 22 | Administrator / trusted IP | Administrative access |
| TCP | 80 | `0.0.0.0/0` | Apache HTTP access |

Port `22` should be restricted to a trusted administrator source.

Port `80` is exposed because the current project uses HTTP for the Apache web server.

### Outbound

The current project allows outbound traffic required for:

- AWS service communication.
- CloudWatch Agent publishing.
- SSM Agent communication.
- Package or external connectivity where required.

---

## 9. Route Table vs Security Group

These controls have different jobs.

```text
Route Table
= Where should traffic go?

Security Group
= Is this traffic allowed?
```

Example:

```text
Destination route exists
        │
        ▼
Security Group still evaluates access
```

Having a route does not automatically grant network access.

---

## 10. EC2 Network Interface

The EC2 instance communicates with the VPC through an Elastic Network Interface (ENI).

Conceptually:

```text
AWS VPC View
     │
     ▼
EC2 ENI
     │
     ↕
Linux View
     │
     ▼
ens5
```

The ENI is the AWS-side virtual network interface.

`ens5` is the Linux-side interface name commonly presented to the guest operating system.

They should not be treated as two independent routing devices.

---

## 11. User Request Flow

A simplified HTTP request path is:

```text
Browser
   │
   ▼
User Network
   │
   ▼
Internet
   │
   ▼
AWS Internet Gateway
   │
   ▼
VPC Routing
   │
   ▼
Security Group Evaluation
   │
   ▼
EC2 ENI
   │
   ▼
ens5
   │
   ▼
Linux Kernel
   │
   ▼
IP
   │
   ▼
TCP :80
   │
   ▼
Socket
   │
   ▼
Apache HTTPD
```

This is a **conceptual network flow**.

VPC, route tables, and Security Groups are AWS logical networking controls, not physical boxes that a packet literally moves through one by one.

---

## 12. Response Flow

The response travels back through the networking stack:

```text
HTTPD
   │
   ▼
HTTP Response
   │
   ▼
Socket
   │
   ▼
TCP
   │
   ▼
IP
   │
   ▼
Linux Kernel
   │
   ▼
ens5
   │
   ▼
EC2 ENI
   │
   ▼
VPC Networking
   │
   ▼
Internet Gateway
   │
   ▼
Internet
   │
   ▼
Browser
```

---

## 13. Correct AWS Service Communication

The current V2.0 incident architecture is:

```text
EC2 / HTTPD
     │
     ▼
CloudWatch
     │
     ▼
Lambda
     │
  ┌──┴───────────┐
  ▼              ▼
 SSM            SNS
  │              │
  ▼              ▼
 EC2          Engineer
```

This replaces the old documentation pattern:

```text
CloudWatch
   │
   ▼
SNS
   │
   ▼
Lambda
```

That old flow is not the current V2.0 architecture.

The current event path is:

```text
CloudWatch Alarm
      │
      ▼
Lambda
```

SNS is used after Lambda processing for notification.

---

## 14. VPC and CloudWatch

The VPC provides the network environment for the EC2 instance that runs the CloudWatch Agent.

P1 monitoring:

```text
EC2
 │
 ▼
HTTPD
 │
 ▼
CloudWatch Agent
 │
 ▼
procstat
 │
 ▼
procstat_lookup_pid_count
 │
 ▼
CloudWatch
```

P2 monitoring:

```text
EC2
 │
 ▼
CPUUtilization
 │
 ▼
CloudWatch
```

The CloudWatch Agent requires connectivity to the appropriate CloudWatch service endpoints.

The VPC provides the network environment, while IAM separately determines whether AWS API operations are authorized.

---

## 15. VPC and Systems Manager

The P1/P2 management path is:

```text
Lambda
   │
   ▼
Systems Manager
   │
   ▼
SSM Agent
   │
   ▼
EC2 Linux
```

The SSM Agent communicates outbound with AWS Systems Manager services.

This allows the automation workflow to manage the instance without requiring a direct Lambda-to-EC2 SSH connection.

For P1:

```text
SSM
 │
 ▼
systemctl restart httpd
```

For P2:

```text
SSM
 │
 ▼
CPU / Load / Process / Memory Diagnostics
```

---

## 16. VPC and IAM

Networking and authorization are separate controls.

```text
Network Reachability
        ≠
AWS Permission
```

A system may be able to reach an AWS service endpoint but still receive:

```text
AccessDenied
```

if IAM does not authorize the API request.

Easy distinction:

```text
VPC / Networking
= Can the communication path exist?

IAM
= Is the AWS action authorized?
```

---

## 17. VPC and SNS

SNS is an AWS-managed notification service.

In the current project:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Engineer
```

The VPC hosts the EC2 workload, but SNS is not placed inside the EC2 subnet as part of the current architecture.

Do not describe SNS as the path that triggers Lambda.

---

## 18. Network Security Layers

The current project uses multiple controls.

### VPC

Provides logical network isolation.

### Subnet

Defines the IP network segment in which EC2 runs.

### Route Table

Controls traffic routing.

### Internet Gateway

Provides the VPC's internet connectivity path.

### Security Group

Controls allowed traffic to and from the EC2 network interface.

### IAM

Controls authorization for AWS API actions.

These controls work together but solve different problems.

---

## 19. Current Scope vs Production Enhancements

The current implemented design is intentionally simple.

Current:

```text
1 VPC
1 Public Subnet
1 EC2 Instance
```

The project does not currently implement:

- Multi-AZ architecture.
- NAT Gateway.
- Application Load Balancer.
- Auto Scaling Group.
- Private application subnets.
- Full multi-tier application architecture.

Possible future hardening could include:

```text
Internet
   │
   ▼
Application Load Balancer
   │
   ▼
Private Application Subnets
   │
   ▼
EC2 Instances
```

with private AWS service connectivity or appropriate outbound architecture where required.

These are future production enhancements, not part of the current seven-service implementation.

---

## 20. Why the Current Design Uses a Public Subnet

The current project is a learning and automation implementation centered on a single HTTPD workload.

A public subnet provides a simple path for:

- User HTTP access.
- EC2 outbound connectivity.
- CloudWatch Agent communication.
- SSM Agent communication.

This keeps the current architecture easy to build and troubleshoot.

It is not intended to represent the final hardened architecture for a large production application.

---

## 21. VPC Verification Commands

### Display IP addresses

```bash
ip addr
```

### Display Linux routing

```bash
ip route
```

### Check DNS resolution

```bash
getent hosts amazon.com
```

### Test HTTPS connectivity

```bash
curl -I https://aws.amazon.com
```

### Check HTTPD

```bash
systemctl status httpd
```

### Check listening ports

```bash
ss -tulnp
```

### Check interface

```bash
ip addr show ens5
```

These commands verify the guest operating-system view of networking.

---

## 22. AWS CLI Verification

AWS CLI can be used for infrastructure inspection where appropriate.

Examples:

```bash
aws ec2 describe-vpcs
```

```bash
aws ec2 describe-subnets
```

```bash
aws ec2 describe-route-tables
```

```bash
aws ec2 describe-internet-gateways
```

```bash
aws ec2 describe-security-groups
```

These commands are for inspection and verification, not for changing the project's preferred Lambda deployment method.

---

## 23. Troubleshooting — Website Not Reachable

Follow the path layer by layer:

```text
Browser
   │
   ▼
Public IP / Connectivity
   │
   ▼
Internet Gateway
   │
   ▼
Route Table
   │
   ▼
Security Group
   │
   ▼
EC2 Network
   │
   ▼
HTTPD
```

Check:

1. EC2 is running.
2. EC2 has the expected public connectivity.
3. `0.0.0.0/0` points to the Internet Gateway.
4. The subnet uses the expected route table.
5. Security Group allows TCP port 80.
6. HTTPD is active.
7. HTTPD is listening on port 80.

Useful commands:

```bash
systemctl status httpd
```

```bash
ss -lntp | grep :80
```

```bash
curl http://localhost
```

---

## 24. Troubleshooting — SSM Managed Node Offline

Check:

```bash
sudo systemctl status amazon-ssm-agent
```

Then verify:

- EC2 IAM role.
- Required network connectivity.
- SSM Agent status.
- Correct AWS Region.
- Systems Manager managed-node status.

Remember:

> SSM automation does not require inbound SSH connectivity.

---

## 25. Troubleshooting — CloudWatch Metrics Missing

Check:

```bash
sudo systemctl status amazon-cloudwatch-agent
```

Inspect:

```text
/opt/aws/amazon-cloudwatch-agent/logs/
```

Then verify:

- CloudWatch Agent configuration.
- IAM permissions.
- Network connectivity.
- Correct Region.
- Expected CloudWatch namespace and metric.

For P1, also verify:

```text
procstat lookup = httpd
```

---

## 26. Relationship with the Seven AWS Services

| Service | Relationship with VPC |
|---|---|
| IAM | Authorizes AWS API operations |
| EC2 | Runs inside the VPC |
| VPC | Provides the network foundation |
| CloudWatch | Monitors the EC2 workload and receives metrics/logs |
| Lambda | Receives direct alarm events and orchestrates incident workflows |
| Systems Manager | Communicates with the EC2 managed node |
| SNS | Delivers notifications published by Lambda |

Important correction:

> **SNS receives operational notifications from Lambda; it is not the alarm-event bridge between CloudWatch and Lambda.**

---

## 27. Three-Level Interview Answer

### Level 1

> **VPC provides the network foundation and logical network boundary for my project.**

### Level 2

> **The EC2 workload runs inside `cloudops-vpc` in a public subnet. The VPC provides the IP address space, route table, Internet Gateway connectivity, and Security Group controls required for user access and AWS service communication.**

### Level 3

> **The VPC uses CIDR `10.0.0.0/16`, with `cloudops-subnet` using `10.0.0.0/28` in `ap-south-1a`. `cloudops-rt` provides the local VPC route and a `0.0.0.0/0` route to `cloudops-igw`. The EC2 instance communicates through its ENI, represented inside Linux by `ens5`, while `cloudops-sg` controls permitted traffic. The VPC provides network reachability, while IAM separately controls whether AWS API actions are authorized.**

---

## 28. Operational Summary

VPC can be remembered as:

```text
ADDRESS
   │
   ▼
SEGMENT
   │
   ▼
ROUTE
   │
   ▼
ALLOW
   │
   ▼
CONNECT
```

Meaning:

```text
CIDR
Subnet
Route Table
Security Group
Internet / AWS Connectivity
```

VPC does not:

- Detect HTTPD failure.
- Evaluate CloudWatch alarms.
- Restart HTTPD.
- Decide P1 or P2.
- Publish SNS incident messages.

---

## 29. Final Architecture Summary

```text
cloudops-vpc
10.0.0.0/16
    │
    ├── cloudops-subnet
    │      10.0.0.0/28
    │          │
    │          ▼
    │    cloudops-server
    │          │
    │    ┌─────┴─────┐
    │    ▼           ▼
    │  CW Agent    SSM Agent
    │
    ├── cloudops-rt
    │          │
    │          ▼
    │    cloudops-igw
    │
    └── cloudops-sg
```

Operationally:

```text
EC2 / HTTPD
     │
     ▼
CloudWatch
     │
     ▼
Lambda
  ┌──┴──────────┐
  ▼             ▼
 SSM           SNS
  │             │
  ▼             ▼
 EC2         Engineer
```

---

## Key Design Statement

> **Amazon VPC provides the network environment for the EC2 workload. It controls addressing, subnet placement, routing, internet connectivity, and network access, while CloudWatch, Lambda, SSM, SNS, and IAM handle monitoring, decision-making, execution, notification, and authorization respectively.**
