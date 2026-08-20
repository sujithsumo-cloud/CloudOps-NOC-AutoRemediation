# CloudOps NOC Automation — AWS Cloud Operations Center

> **Version 2.0** | Automated Monitoring, Detection, Remediation & Notification

## 📌 Project Overview

**CloudOps NOC Automation** is an AWS-based Cloud Operations Center project designed to monitor EC2 workloads, detect operational issues, automatically remediate critical failures, and notify the operations team.

The project implements a simplified **Cloud Operations Center (COC/NOC)** workflow using AWS-native services.

The system focuses on two operational scenarios:

* **P1 — HTTPD Service Failure:** Automatically detects when the HTTPD process is unavailable and attempts automated recovery.
* **P2 — High CPU Utilization:** Detects high CPU utilization and provides diagnostic information without performing automatic remediation.

The architecture follows an event-driven model:

```text
EC2
 │
 ├── CloudWatch Agent
 │      └── procstat_lookup_pid_count
 │
 └── CPUUtilization
        │
        ▼
   Amazon CloudWatch
        │
        ├── NOC-cloudops-automate (P1)
        │
        └── cpu alert (P2)
                 │
                 ▼
          CloudWatch Alarm Event
                 │
                 ▼
              Lambda
                 │
        ┌────────┴────────┐
        ▼                 ▼
       P1                P2
   HTTPD Recovery     CPU Diagnosis
        │
        ▼
       SSM
        │
        ▼
       EC2
        │
        ▼
      HTTPD
        │
        ▼
       SNS
        │
        ▼
   Notification
```

---

# 🎯 Project Objectives

The main objectives of the project are:

1. Monitor EC2 infrastructure continuously.
2. Detect HTTPD service/process failure automatically.
3. Detect abnormal CPU utilization.
4. Trigger Lambda from CloudWatch Alarm events.
5. Automatically recover the HTTPD service for P1 incidents.
6. Verify whether remediation was successful.
7. Retry the remediation once if required.
8. Perform stability verification after recovery.
9. Escalate when automatic recovery is unsuccessful.
10. Send operational notifications through SNS.
11. Maintain a simple, secure and event-driven AWS architecture.

---

# 🏗️ AWS Architecture

## High-Level Architecture

```text
                         AWS CLOUD
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                         VPC                                  │
│                                                              │
│   ┌──────────────────┐                                       │
│   │       EC2        │                                       │
│   │                  │                                       │
│   │  HTTPD           │                                       │
│   │  CloudWatch      │                                       │
│   │  Agent           │                                       │
│   │                  │                                       │
│   └────────┬─────────┘                                       │
│            │                                                  │
│            │ Metrics                                          │
│            ▼                                                  │
│   ┌──────────────────┐                                       │
│   │   CloudWatch     │                                       │
│   │                  │                                       │
│   │ P1: procstat     │                                       │
│   │ P2: CPUUtil      │                                       │
│   └────────┬─────────┘                                       │
│            │                                                  │
│            │ Alarm Event                                      │
│            ▼                                                  │
│   ┌──────────────────┐                                       │
│   │     Lambda       │                                       │
│   │                  │                                       │
│   │ Alarm Parser     │                                       │
│   │ Actionable Gate  │                                       │
│   │ P1 Remediation   │                                       │
│   │ P2 Diagnosis     │                                       │
│   └──────┬─────┬─────┘                                       │
│          │     │                                             │
│          │     └──────────────┐                              │
│          ▼                    ▼                              │
│       SSM                     SNS                             │
│          │                    │                              │
│          ▼                    ▼                              │
│         EC2              Notifications                       │
│                                                              │
│                         IAM                                   │
│                  Access Control                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

# 🔄 End-to-End Project Flow

## P1 — HTTPD Failure Automation

The P1 workflow is the primary automated remediation path.

```text
HTTPD running
      │
      ▼
CloudWatch Agent
      │
      ▼
procstat_lookup_pid_count
      │
      ▼
CloudWatch Metric
      │
      ▼
NOC-cloudops-automate
      │
      │ Alarm condition
      ▼
CloudWatch Alarm
      │
      ▼
Lambda
      │
      ▼
Alarm Parsing
      │
      ▼
Actionable Alarm Gate
      │
      ▼
P1 Detection
      │
      ▼
SSM Run Command
      │
      ▼
EC2
      │
      ▼
systemctl restart httpd
      │
      ▼
HTTPD Verification
      │
      ├── SUCCESS
      │      │
      │      ▼
      │   Stability Check
      │      │
      │      ▼
      │   SNS Notification
      │
      └── FAILURE
             │
             ▼
          One Retry
             │
             ▼
       Verification
             │
        ┌────┴────┐
        ▼         ▼
     Success    Failure
        │         │
        ▼         ▼
      SNS       Escalation
```

### P1 Detection

The EC2 instance runs the CloudWatch Agent with process monitoring.

The HTTPD process is monitored using:

```text
procstat_lookup_pid_count
```

The metric represents the number of matching HTTPD processes.

The P1 alarm currently evaluates:

```text
procstat_lookup_pid_count < 1
```

for the configured alarm evaluation period.

When the HTTPD process disappears, the metric can cause:

```text
OK → ALARM
```

The alarm used for the current P1 implementation is:

```text
NOC-cloudops-automate
```

---

# 🚨 P1 Lambda Remediation

When Lambda receives the CloudWatch Alarm event, it first parses the alarm information.

The Lambda does **not** immediately execute a remediation command.

It first performs an **actionable-alarm gate**.

```text
CloudWatch Event
       │
       ▼
Alarm Parsing
       │
       ▼
Is this an actionable alarm?
       │
   ┌───┴───┐
   │       │
  NO      YES
   │       │
   ▼       ▼
 Ignore   P1 Logic
```

This prevents Lambda from unnecessarily executing remediation for irrelevant or non-actionable events.

For P1, Lambda uses AWS Systems Manager to execute the HTTPD remediation command on the EC2 instance.

The current remediation command is:

```bash
systemctl restart httpd
```

After execution, Lambda verifies the service using:

```bash
systemctl is-active httpd
```

If required, the workflow performs **one automatic retry**.

After successful recovery, Lambda performs a stability verification before considering the remediation successful.

---

# 🖥️ P2 — CPU Monitoring

P2 is intentionally **diagnostic-only**.

The P2 workflow monitors:

```text
EC2 CPUUtilization
        │
        ▼
CloudWatch
        │
        ▼
cpu alert
        │
        ▼
Lambda
        │
        ▼
CPU Diagnostic Information
        │
        ▼
SNS Notification
```

P2 does **not** automatically restart services or modify the EC2 instance.

This separation keeps the remediation policy controlled:

| Severity | Problem              | Automation            |
| -------- | -------------------- | --------------------- |
| **P1**   | HTTPD failure        | Automatic remediation |
| **P2**   | High CPU utilization | Diagnostic only       |

---

# ☁️ AWS Services Used

The project intentionally uses **seven AWS services**.

| AWS Service                   | Responsibility                        |
| ----------------------------- | ------------------------------------- |
| **Amazon VPC**                | Network boundary and connectivity     |
| **Amazon EC2**                | Application/workload server           |
| **Amazon CloudWatch**         | Metrics, monitoring and alarms        |
| **AWS Lambda**                | Event processing and automation logic |
| **AWS Systems Manager (SSM)** | Remote command execution on EC2       |
| **Amazon SNS**                | Operational notifications             |
| **AWS IAM**                   | Permissions and access control        |

No additional AWS services are required for the implemented architecture.

---

# 🔐 IAM

IAM controls what the Lambda function and EC2 instance are allowed to do.

The architecture follows the principle of granting only the permissions required for the automation workflow.

Lambda requires permissions related to:

```text
CloudWatch Alarm Event Processing
        │
        ▼
SSM Command Execution
        │
        ▼
SNS Notification
        │
        ▼
CloudWatch/Lambda Logging
```

EC2 uses an IAM role to allow required AWS integrations such as CloudWatch Agent and Systems Manager.

---

# 🌐 VPC

The EC2 instance runs inside an Amazon VPC.

The VPC provides the network boundary for the workload.

The network architecture includes:

```text
VPC
 │
 ├── Subnet
 │
 ├── Route Table
 │
 ├── Internet Connectivity
 │
 └── Security Group
        │
        ▼
       EC2
```

The VPC controls the network environment in which the monitored EC2 workload operates.

---

# 🖥️ EC2

EC2 is the workload host of the project.

The EC2 instance contains:

* HTTPD web server
* CloudWatch Agent
* Systems Manager connectivity
* Linux systemd service management

The important internal relationship is:

```text
EC2
 │
 ├── Linux Kernel
 │
 ├── systemd
 │      │
 │      └── httpd.service
 │
 ├── HTTPD
 │
 └── CloudWatch Agent
```

The HTTPD process is the P1 workload being monitored.

---

# 📊 CloudWatch

CloudWatch provides the monitoring and detection layer.

## P1 Metric

```text
CloudWatch Agent
      │
      ▼
procstat_lookup_pid_count
      │
      ▼
NOC-cloudops-automate
```

## P2 Metric

```text
EC2
 │
 ▼
CPUUtilization
 │
 ▼
cpu alert
```

CloudWatch then generates an alarm event when the configured conditions are satisfied.

---

# ⚡ Lambda

Lambda is the automation brain of the project.

Its responsibilities include:

1. Receive the CloudWatch Alarm event.
2. Parse the event.
3. Validate the alarm.
4. Apply the actionable-alarm gate.
5. Identify P1 or P2.
6. Execute P1 remediation through SSM.
7. Verify HTTPD recovery.
8. Perform one retry when required.
9. Perform stability verification.
10. Generate diagnostic information for P2.
11. Send SNS notifications.

The Lambda event path is:

```text
CloudWatch Alarm
       │
       ▼
Lambda
       │
       ▼
event["alarmData"]
       │
       ▼
Alarm Information
       │
       ▼
Actionable Gate
       │
       ├───────────────┐
       ▼               ▼
      P1              P2
       │               │
       ▼               ▼
      SSM          Diagnosis
       │               │
       └───────┬───────┘
               ▼
              SNS
```

---

# 🛠️ Systems Manager

AWS Systems Manager is used for remote command execution.

For P1 remediation:

```text
Lambda
   │
   │ SSM API request
   ▼
Systems Manager
   │
   ▼
SSM Agent on EC2
   │
   ▼
Linux command execution
   │
   ▼
systemctl restart httpd
```

The important point is that Lambda does not directly log into the EC2 server using SSH.

Instead:

```text
Lambda → SSM → SSM Agent → EC2
```

---

# 📢 SNS

Amazon SNS provides notification delivery.

The notification flow is:

```text
Lambda
   │
   ▼
SNS
   │
   ▼
Operations Notification
```

Notifications can communicate events such as:

* P1 detected
* HTTPD remediation started
* HTTPD recovery successful
* Retry performed
* Recovery failed
* Escalation required
* P2 CPU diagnostic alert

---

# 🔄 Failure Recovery Logic

The P1 automation follows a controlled recovery sequence.

```text
P1 Alarm
   │
   ▼
Validate Event
   │
   ▼
Actionable Gate
   │
   ▼
Execute Restart
   │
   ▼
Verify HTTPD
   │
   ├───────────────┐
   │               │
 SUCCESS         FAILURE
   │               │
   ▼               ▼
Stability       One Retry
Check             │
   │               ▼
   │            Verify
   │               │
   │          ┌────┴────┐
   │          │         │
   │       SUCCESS    FAILURE
   │          │         │
   ▼          ▼         ▼
Success     Success   Escalation
Notification Notification Notification
```

This design prevents unlimited automated retries.

---

# 🧠 Why the Actionable Alarm Gate?

The Lambda function receives an event, but not every event should automatically trigger remediation.

Therefore:

```text
Alarm Event
     │
     ▼
Is it actionable?
     │
 ┌───┴────┐
 NO       YES
 │         │
 ▼         ▼
Ignore   Continue
```

This acts as a safety mechanism.

It reduces the possibility of Lambda executing an operational command when the event does not represent a genuine actionable condition.

---

# 🔍 Monitoring and Observability

The project provides visibility across multiple layers.

### Infrastructure

```text
EC2
```

### Process Monitoring

```text
CloudWatch Agent
        │
        ▼
procstat_lookup_pid_count
```

### Resource Monitoring

```text
CPUUtilization
```

### Detection

```text
CloudWatch Alarms
```

### Automation

```text
Lambda
```

### Remote Execution

```text
SSM
```

### Notification

```text
SNS
```

---

# 🧪 Testing Strategy

The project can be validated by testing the two implemented scenarios.

## P1 Test

A controlled HTTPD failure can be introduced.

Expected flow:

```text
HTTPD Failure
      ↓
procstat metric changes
      ↓
NOC-cloudops-automate
      ↓
ALARM
      ↓
Lambda
      ↓
SSM
      ↓
HTTPD Restart
      ↓
Verification
      ↓
SNS Notification
```

Expected result:

```text
HTTPD → Recovered
Alarm  → Returns toward OK
Lambda → Successful remediation
SNS    → Notification generated
```

## P2 Test

Generate high CPU utilization on the EC2 instance.

Expected flow:

```text
High CPU
   ↓
CPUUtilization
   ↓
cpu alert
   ↓
Lambda
   ↓
Diagnostic Processing
   ↓
SNS Notification
```

P2 should **not** automatically restart HTTPD.

---

# 🔎 Operational Verification

Important areas to verify include:

### EC2

```text
HTTPD status
CloudWatch Agent status
SSM Agent status
Network connectivity
```

### CloudWatch

```text
P1 procstat metric
P1 NOC-cloudops-automate
P2 CPUUtilization
P2 cpu alert
Alarm state changes
```

### Lambda

```text
Alarm parsing
Actionable gate
P1 execution
P1 verification
Retry behavior
Stability verification
P2 diagnostic processing
SNS publishing
```

### SSM

```text
Command execution
Command status
Target EC2 instance
Command output
```

### SNS

```text
Notification publishing
Notification delivery
```

---

# 📁 Repository Structure

```text

CloudOps-NOC-Auto-Remediation/
│
├── ec2/
├── vpc/
├── apache/
├── cloudwatch/
├── sns/
├── lambda/
├── ssm/
├── iam/
├── diagrams/
├── scripts/
├── screenshots/
├── Docs/
├── apache/
├── README.md
├── LICENSE
└── .gitignore
```

---

# 📚 Key Technical Concepts

This project provides practical exposure to:

* AWS Cloud Operations
* NOC automation
* Event-driven architecture
* EC2 administration
* Linux systemd
* HTTPD service management
* CloudWatch metrics
* CloudWatch Agent
* Procstat monitoring
* CloudWatch alarms
* Lambda automation
* Lambda event parsing
* Actionable alarm gates
* AWS Systems Manager
* SSM Run Command
* SNS notifications
* IAM permissions
* VPC networking
* Automated remediation
* Failure detection
* Recovery verification
* Retry and escalation logic
* Operational observability

---

# 🧩 Architecture Principle

The project follows a simple operational pattern:

```text
MONITOR
   ↓
DETECT
   ↓
DECIDE
   ↓
REMEDIATE
   ↓
VERIFY
   ↓
NOTIFY
```

For P1:

```text
Monitor HTTPD
     ↓
Detect Failure
     ↓
Validate Alarm
     ↓
Restart HTTPD
     ↓
Verify Recovery
     ↓
Stability Check
     ↓
Notify
```

For P2:

```text
Monitor CPU
     ↓
Detect High CPU
     ↓
Validate Alarm
     ↓
Diagnose
     ↓
Notify
```

---

# 🎓 Learning Outcomes

By implementing this project, the following real-world Cloud Operations concepts are demonstrated:

### Infrastructure

Understanding how an EC2 workload operates inside a VPC.

### Monitoring

Understanding how CloudWatch Agent collects application/process-level metrics.

### Detection

Understanding how CloudWatch converts metric conditions into alarms.

### Automation

Understanding how Lambda processes operational events.

### Remediation

Understanding how Lambda uses Systems Manager to execute commands on EC2.

### Verification

Understanding that automation should verify whether the requested recovery actually succeeded.

### Notification

Understanding how SNS communicates operational events.

### Security

Understanding how IAM controls service-to-service permissions.

---

# 💼 Interview Explanation

A concise interview explanation of the project:

> **"I built a CloudOps NOC automation solution on AWS to monitor an EC2-based HTTPD workload and CPU utilization. For P1 HTTPD failures, the CloudWatch Agent publishes the procstat process-count metric, which is evaluated by the NOC-cloudops-automate alarm. The CloudWatch alarm directly invokes Lambda. Lambda parses the alarm event, applies an actionable-alarm gate, and uses Systems Manager to restart HTTPD on the EC2 instance. It then verifies the service, performs one retry if necessary, checks stability, and sends the result through SNS. For P2 CPU alerts, the system is diagnostic-only and does not perform automatic remediation. IAM controls permissions and the EC2 workload operates inside a VPC."**

---

# 🚀 Future Improvements

The current implementation intentionally focuses on P1 and P2.

Possible future improvements could include:

* More advanced remediation policies
* Additional application health checks
* Improved incident correlation
* Centralized operational dashboards
* More detailed audit reporting
* Expanded notification workflows
* Automated infrastructure deployment
* Additional recovery strategies

These are **future possibilities** and are not part of the current V2.0 implementation.

---

# ⚠️ Current Scope

The implemented V2.0 project intentionally contains:

```text
P1 → HTTPD Automation
P2 → CPU Diagnostic
```

There is **no P3 implementation** in the current project.

The implemented AWS services are:

```text
IAM
EC2
VPC
CloudWatch
SNS
Systems Manager
Lambda
```

---

# 🏁 Conclusion

The CloudOps NOC Automation project demonstrates how AWS-native services can be combined to build an event-driven Cloud Operations workflow.

The architecture moves from:

```text
Infrastructure
      ↓
Monitoring
      ↓
Detection
      ↓
Decision
      ↓
Automation
      ↓
Verification
      ↓
Notification
```

The project demonstrates a practical approach to reducing manual operational effort while maintaining controlled and verifiable automated remediation.

---

## ⭐ Project Highlights

```text
✓ AWS Cloud Operations Architecture
✓ EC2 Infrastructure Monitoring
✓ HTTPD Process Monitoring
✓ CloudWatch Agent + Procstat
✓ CloudWatch Alarm Detection
✓ Direct Alarm → Lambda Event Flow
✓ Lambda-Based Automation
✓ SSM Remote Remediation
✓ HTTPD Verification
✓ One Automatic Retry
✓ Stability Verification
✓ CPU Diagnostic Monitoring
✓ SNS Notifications
✓ IAM-Based Access Control
✓ VPC Network Architecture
✓ Evidence-Based Testing
✓ P1/P2 Incident Model
```

---

## 📌 Version

**CloudOps NOC Automation — Version 2.0**

**Primary focus:** Automated HTTPD recovery + CPU operational diagnostics

**Architecture model:** Event-driven AWS Cloud Operations Automation
