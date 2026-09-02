SSM OpsCenter Enhancement

Post-Review Enhancement

This enhancement was implemented after the CloudOps NOC Automation V2.0 baseline was reviewed.

The original reviewed architecture remains unchanged.
Systems Manager OpsCenter was added only as a parallel incident-tracking capability for the P1 HTTPD alarm.

1. Enhancement at a Glance

Reviewed V2.0 baseline

CloudWatch Alarm
       ↓
Lambda
       ↓
SSM Run Command
       ↓
EC2
       ↓
HTTPD Recovery
       ↓
Verification
       ↓
SNS

Post-review enhancement

CloudWatch Alarm
       ↓
SSM OpsCenter
       ↓
OpsItem
       ↓
Incident Tracking

Final design

                NOC-cloudops-automate
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
           Lambda              SSM OpsCenter
              │                     │
              ▼                     ▼
     Existing P1 Recovery          OpsItem

Important: OpsCenter does not sit between CloudWatch and Lambda.
Both are independent actions from the same P1 CloudWatch alarm.

2. Project Scope

Item

Current Design

Project

CloudOps NOC Automation

Reviewed baseline

V2.0

Enhancement

Systems Manager OpsCenter

Enhancement timing

Post-review

Enhancement scope

P1 HTTPD incident tracking

P1 alarm

NOC-cloudops-automate

P2

CPU diagnostic-only; unchanged

AWS service count

7 primary AWS services

Primary AWS Services

IAM

EC2

VPC

CloudWatch

SNS

Systems Manager

Lambda

OpsCenter is a capability of AWS Systems Manager, not an eighth AWS service.

3. Why OpsCenter Was Added

The original V2.0 project already performed:

Detect
  ↓
Decide
  ↓
Remediate / Diagnose
  ↓
Verify
  ↓
Notify / Escalate

The enhancement adds:

Record
  ↓
Track
  ↓
Resolve

Business / Operations Reason

The original automation could recover a supported P1 incident, but it did not maintain a formal operational record of that incident.

OpsCenter provides an OpsItem that can be used to record and track:

alarm source,

severity,

incident status,

investigation progress,

and resolution.

4. Original P1 Remediation Flow

The original reviewed P1 path remains:

HTTPD
  ↓
CloudWatch Agent
  ↓
procstat_lookup_pid_count
  ↓
NOC-cloudops-automate
  ↓
Lambda
  ↓
Alarm Parsing
  ↓
Actionable Alarm Gate
  ↓
SSM Run Command
  ↓
SSM Agent
  ↓
systemctl restart httpd
  ↓
Verification
  ↓
Stability Check
  ↓
SNS Notification / Escalation

This path is the technical remediation workflow.

5. New OpsCenter Flow

The enhancement adds this second path:

NOC-cloudops-automate
        ↓
SSM OpsCenter
        ↓
OpsItem Created
        ↓
Open
        ↓
Incident Review
        ↓
In Progress / Resolved

This path is the operational tracking workflow.

6. Architecture Evidence

OpsCenter Architecture



CloudWatch Alarm Action



7. Systems Manager Has Two Roles

Systems Manager Capability

Responsibility

Run Command

Execute controlled commands on EC2

OpsCenter

Record and track operational incidents

SSM Agent

Receive Systems Manager commands on EC2

Run Command

Lambda
  ↓
Boto3
  ↓
SSM SendCommand
  ↓
AWS-RunShellScript
  ↓
SSM Agent
  ↓
EC2
  ↓
systemctl restart httpd

Purpose: Technical remediation.

OpsCenter

CloudWatch Alarm
       ↓
OpsCenter
       ↓
OpsItem
       ↓
Status Tracking

Purpose: Operational incident tracking.

8. What Is an OpsItem?

An OpsItem is an operational work item stored in Systems Manager OpsCenter.

For the tested P1 incident:

Field

Tested Value

Source

CloudWatch Alarm

Alarm

NOC-cloudops-automate

Severity

1

Initial status

Open

The OpsItem remains available as an operational record after the technical recovery is completed.

9. OpsItem Lifecycle

Scenario A — Automatic Recovery Succeeds

P1 Alarm
   ↓
OpsItem Created
   ↓
Open
   ↓
Lambda + SSM Recovery
   ↓
HTTPD Verified
   ↓
SNS Recovery Notification
   ↓
Engineer Review
   ↓
Resolved

Typical status:

Open → Resolved

In Progress is not required when automatic recovery succeeds and no additional investigation is needed.

Scenario B — Automatic Recovery Fails

P1 Alarm
   ↓
OpsItem Created
   ↓
Open
   ↓
Lambda + SSM Recovery Attempt
   ↓
Recovery Failure
   ↓
SNS Escalation
   ↓
Engineer Investigation
   ↓
In Progress
   ↓
Manual / Additional Action
   ↓
Resolved

Typical status:

Open → In Progress → Resolved

10. OpsItem Evidence

Open



In Progress



Resolved



11. Before vs After

Before

NOC-cloudops-automate
        ↓
Lambda
        ↓
SSM Run Command
        ↓
EC2

After

                NOC-cloudops-automate
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
           Lambda              SSM OpsCenter
              │                     │
              ▼                     ▼
     SSM Run Command              OpsItem
              │
              ▼
             EC2

The original Lambda remediation action was not removed.

12. IAM Behavior

The OpsCenter alarm action uses a CloudWatch service-linked authorization path for Systems Manager alarm actions.

Conceptually:

CloudWatch Alarm
       ↓
Service-Linked Role
       ↓
ssm:CreateOpsItem
       ↓
SSM OpsCenter

This is separate from:

Lambda execution role permissions,

EC2 instance role permissions,

Lambda → SSM Run Command permissions.

13. Testing Performed

The enhancement was tested using the existing P1 HTTPD failure scenario.

Test flow

HTTPD intentionally stopped
        ↓
CloudWatch Agent
        ↓
procstat_lookup_pid_count
        ↓
NOC-cloudops-automate = ALARM
        │
        ├──→ Lambda P1 recovery
        │
        └──→ OpsCenter OpsItem creation
                    ↓
                   Open
        ↓
HTTPD recovery verified
        ↓
OpsItem reviewed
        ↓
Resolved

Test Results

Test

Result

P1 HTTPD failure detected

✅ Passed

Direct CloudWatch → Lambda action remained active

✅ Passed

OpsCenter created an OpsItem

✅ Passed

OpsItem captured the alarm source

✅ Passed

Severity 1 recorded

✅ Passed

SSM remediation continued

✅ Passed

HTTPD recovery verified

✅ Passed

OpsItem status manually updated

✅ Passed

OpsItem marked Resolved

✅ Passed

14. Component Responsibilities

Component

Responsibility

VPC

Network boundary and connectivity

EC2

Hosts Linux and HTTPD

CloudWatch Agent

Publishes P1 procstat metric

CloudWatch

Detects alarm conditions

Lambda

Decision and orchestration

SSM Run Command

Controlled command execution

SSM Agent

Executes SSM commands on EC2

SSM OpsCenter

Records and tracks OpsItems

SNS

Recovery notification and escalation

IAM

Authorization

15. Remediation vs Incident Tracking

Remediation

CloudWatch
   ↓
Lambda
   ↓
SSM Run Command
   ↓
EC2
   ↓
Recover HTTPD

Goal: Fix the supported technical problem.

Incident Tracking

CloudWatch
   ↓
SSM OpsCenter
   ↓
OpsItem
   ↓
Open / In Progress / Resolved

Goal: Maintain an operational record of the incident.

This enhancement uses AWS Systems Manager OpsCenter.
It does not implement Systems Manager Incident Manager.

16. Current Limitations

Current implementation:

OpsItem creation is automatic.

P1 remediation remains automatic.

OpsItem status changes are manual.

Lambda does not automatically resolve the OpsItem.

Lambda remediation results are not automatically correlated to a specific OpsItem.

OpsItem assignment is manual.

Incident response/resolution metrics are not automatically calculated.

Enhancement currently applies to P1 HTTPD only.

P2 remains diagnostic-only.

17. Future Improvements

Possible future improvements:

automatically resolve an OpsItem after verified recovery,

automatically set In Progress when recovery fails,

correlate Lambda incident IDs with OpsItems,

assign OpsItem ownership,

measure response and resolution time,

integrate OpsCenter data with operational dashboards,

generate incident reports.

These are future possibilities and are not part of the current implementation.

18. Key Learning

The enhancement demonstrates that these are different responsibilities:

Detection
    ≠
Remediation
    ≠
Incident Tracking

In this project:

Function

Component

Detect

CloudWatch

Decide / Orchestrate

Lambda

Execute

SSM Run Command

Manage HTTPD

systemd

Notify / Escalate

SNS

Record / Track

SSM OpsCenter

19. Conclusion

The original reviewed CloudOps NOC Automation V2.0 architecture remains the project baseline.

The enhancement adds a separate operational incident-tracking capability:

Reviewed V2.0
CloudWatch → Lambda → SSM → EC2 → Verification → SNS

                 +

Post-Review Enhancement
CloudWatch → SSM OpsCenter → OpsItem

The project now demonstrates both:

Technical incident response + Operational incident tracking
