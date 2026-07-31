# Amazon VPC Configuration

## Overview

Amazon Virtual Private Cloud (VPC) provides the isolated networking environment for the CloudOps Auto Remediation project.

All networking resources including the subnet, route table, security group, and EC2 instance are deployed inside the VPC.

---

## Purpose

The VPC provides:

- Network isolation
- Secure communication
- Internet connectivity
- Resource segmentation
- Controlled inbound and outbound traffic

---

## Components

### VPC

| Property | Value |
|----------|-------|
| Name | cloudops-vpc |
| Region | ap-south-1 |
| CIDR Block | 10.0.0.0/16 |

---

### Public Subnet

| Property | Value |
|----------|-------|
| Name | cloudops-subnet |
| CIDR | 10.0.0.0/24 |
| Availability Zone | ap-south-1a |

---

### Route Table

| Route | Target |
|-------|--------|
| 0.0.0.0/0 | Internet Gateway |

---

### Internet Gateway

Provides Internet connectivity for resources inside the public subnet.

---

### Security Group

Inbound Rules

| Port | Protocol | Purpose |
|------|----------|----------|
| 22 | TCP | SSH (Optional) |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS (Future) |

Outbound Rules

- Allow All Traffic

---

## Architecture Flow

Internet

↓

Internet Gateway

↓

Route Table

↓

Public Subnet

↓

Security Group

↓

EC2

---

## Best Practices

- Use least privilege security group rules.
- Avoid opening unnecessary ports.
- Deploy private resources in private subnets.
- Use NAT Gateway for outbound Internet access from private subnets.
- Enable VPC Flow Logs for troubleshooting.

---

## Future Enhancements

- Multi-AZ deployment
- Private subnet architecture
- Application Load Balancer
- NAT Gateway
- VPC Endpoints
