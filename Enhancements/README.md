SSM OpsCenter Incident Management Enhancement

Overview

This enhancement extends the existing CloudOps NOC V2.0 project by adding formal incident recording, tracking, and closure using AWS Systems Manager OpsCenter.

The original V2.0 automation already provides:

P1 HTTPD monitoring using CloudWatch Agent

CloudWatch alarm-based incident detection

Direct CloudWatch Alarm → Lambda invocation

Actionable Alarm Gate in Lambda

Automated remediation through AWS Systems Manager Run Command

HTTPD recovery verification and stability verification

SNS notification and escalation

P2 CPU monitoring as diagnostic-only

This enhancement adds a new incident-management path:

CloudWatch Alarm
      |
      +----> Lambda -> SSM Run Command -> EC2 -> Verification -> SNS
      |
      +----> SSM OpsCenter -> OpsItem

The existing remediation workflow remains unchanged.

Base Project

Project: CloudOps NOC Automation

Base Version: V2.0

Enhancement: SSM OpsCenter Incident Management

Primary P1 Alarm: NOC-cloudops-automate

Scope of this enhancement: P1 HTTPD incident management

The project continues to use the same seven AWS services:

IAM

EC2

VPC

CloudWatch

SNS

Systems Manager

Lambda

OpsCenter is a capability inside AWS Systems Manager. It does not add an eighth AWS service to the project.

Why This Enhancement Was Added

The existing V2.0 project already handled the technical incident-response workflow:

Detect -> Decide -> Remediate -> Verify -> Notify / Escalate

However, it did not maintain a centralized incident record showing:

that an incident occurred,

when it occurred,

which CloudWatch alarm created it,

its severity,

its current incident status,

and whether the incident was resolved.

Systems Manager OpsCenter was added to provide this missing incident-management lifecycle.

The enhanced operational lifecycle becomes:

Detect -> Record -> Remediate -> Verify -> Notify / Escalate -> Track -> Resolve

Architecture

Existing V2.0 P1 Remediation Path

EC2 HTTPD
    |
    v
CloudWatch Agent
    |
    v
procstat_lookup_pid_count
    |
    v
CloudWatch Alarm
NOC-cloudops-automate
    |
    v
Lambda
    |
    v
Actionable Alarm Gate
    |
    v
SSM Run Command
    |
    v
EC2
    |
    v
Restart HTTPD
    |
    v
Verification + Stability Check
    |
    v
SNS Notification / Escalation

New OpsCenter Incident-Management Path

                     CloudWatch Alarm
                  NOC-cloudops-automate
                           |
              +------------+------------+
              |                         |
              v                         v
           Lambda                  SSM OpsCenter
              |                         |
              v                         v
      Existing Remediation            OpsItem
              |                         |
              v                         v
       SSM Run Command                Open
              |                         |
              v                         |
             EC2                        |
              |                         |
              v                         |
       HTTPD Remediation                |
              |                         |
              v                         |
         Verification                   |
              |                         |
        +-----+-----+                   |
        |           |                   |
     Success      Failure               |
        |           |                   |
        v           v                   v
       SNS      SNS Escalation     In Progress
                    |                   |
                    v                   |
            Engineer Investigation     |
                    |                   |
                    +---------+---------+
                              |
                              v
                           Resolved

Systems Manager Responsibilities

AWS Systems Manager now has two separate responsibilities in the project.

1. Systems Manager Run Command

Used for technical remediation.

Lambda
   |
   v
SSM Run Command
   |
   v
EC2
   |
   v
systemctl restart httpd

Responsibility: Execute controlled remediation commands on the EC2 instance.

2. Systems Manager OpsCenter

Used for incident management.

CloudWatch Alarm
      |
      v
SSM OpsCenter
      |
      v
OpsItem

Responsibility: Record and track the lifecycle of an operational incident.

Systems Manager Capability

Responsibility

Run Command

EC2 remediation

OpsCenter

Incident recording, tracking, and closure

OpsItem

An OpsItem is the operational incident record created in Systems Manager OpsCenter.

For the P1 HTTPD test, the OpsItem was automatically created when NOC-cloudops-automate entered the ALARM state.

The test OpsItem recorded information such as:

Source: CloudWatch Alarm

Severity: 1

Initial Status: Open

Alarm: NOC-cloudops-automate

The OpsItem remains as an operational record even after HTTPD has already been recovered.

Incident Status Lifecycle

In the current implementation, OpsItem creation is automatic, while status updates are performed manually by the NOC engineer.

Status Meanings

Status

Meaning

Open

Incident has been created and requires review

In Progress

An engineer is actively investigating or working on the incident

Resolved

The incident has been fixed and closed

Scenario 1 — Automated Recovery Succeeds

HTTPD Failure
    |
    v
CloudWatch Alarm
    |
    v
OpsItem Created
    |
    v
Open
    |
    v
Lambda + SSM Remediation
    |
    v
HTTPD Active
    |
    v
Verification Successful
    |
    v
Resolved

Recommended lifecycle:

Open -> Resolved

In Progress is not required when automated remediation succeeds and no engineer needs to investigate further.

Scenario 2 — Automated Recovery Fails

HTTPD Failure
    |
    v
CloudWatch Alarm
    |
    v
OpsItem Created
    |
    v
Open
    |
    v
Lambda + SSM Remediation
    |
    v
Recovery Failed
    |
    v
SNS Escalation
    |
    v
Engineer Starts Investigation
    |
    v
In Progress
    |
    v
Manual / Additional Remediation
    |
    v
Resolved

Recommended lifecycle:

Open -> In Progress -> Resolved

Implementation Change

The existing CloudWatch P1 alarm was updated with an additional Systems Manager OpsCenter action.

Existing Action

NOC-cloudops-automate
      |
      v
Lambda

New Additional Action

NOC-cloudops-automate
      |
      v
Systems Manager OpsCenter
      |
      v
Create OpsItem

Final Alarm Behavior

CloudWatch Alarm
      |
      +----> Lambda -> Existing Automated Remediation
      |
      +----> SSM OpsCenter -> Incident Record

The existing Lambda action was not removed or replaced.

Testing Performed

The enhancement was tested using the existing P1 HTTPD workflow.

Test Flow

HTTPD failure introduced
        |
        v
CloudWatch Agent publishes process metric
        |
        v
procstat_lookup_pid_count indicates HTTPD is down
        |
        v
NOC-cloudops-automate enters ALARM
        |
        +----> Existing Lambda automation executes
        |
        +----> OpsCenter automatically creates OpsItem
                         |
                         v
                        Open
                         |
                         v
                 HTTPD recovery verified
                         |
                         v
                      Resolved

Test Result

Requirement

Result

P1 HTTPD incident detected by CloudWatch

✅ Passed

Existing CloudWatch → Lambda action remained active

✅ Passed

OpsCenter action created an OpsItem

✅ Passed

OpsItem source identified CloudWatch Alarm

✅ Passed

Severity 1 was recorded

✅ Passed

Existing SSM remediation continued to work

✅ Passed

HTTPD recovery was verified

✅ Passed

OpsItem status could be managed

✅ Passed

OpsItem was successfully marked Resolved

✅ Passed

Incident Remediation vs Incident Management

These are two different responsibilities.

Incident Remediation

Lambda
   |
   v
SSM Run Command
   |
   v
EC2
   |
   v
Recover HTTPD

Purpose: Fix the technical problem.

Incident Management

CloudWatch Alarm
      |
      v
SSM OpsCenter
      |
      v
OpsItem
      |
      v
Open / In Progress / Resolved

Purpose: Record and track what happened and how the incident was closed.

Service Responsibilities

AWS Component

Responsibility

VPC

Network boundary and connectivity

EC2

Hosts the HTTPD workload

IAM

Controls permissions between AWS services

CloudWatch Agent

Publishes HTTPD process metric

CloudWatch

Metrics, alarm evaluation, and incident detection

Lambda

Alarm parsing, actionable gate, and remediation logic

SSM Run Command

Executes remediation commands on EC2

SSM OpsCenter

Records and tracks incident lifecycle

SNS

Recovery notification and escalation

Impact on Existing V2.0 Architecture

This enhancement does not redesign the original CloudOps NOC V2.0 solution.

The existing remediation path remains:

CloudWatch -> Lambda -> SSM Run Command -> EC2 -> Verification -> SNS

The only new path is:

CloudWatch -> SSM OpsCenter -> OpsItem

Therefore, the reviewed V2.0 baseline remains preserved while this folder documents the post-submission incident-management enhancement separately.

Current Limitation

OpsItem status changes are currently manual.

Successful Automated Recovery

Open -> Resolved

Escalated Incident Requiring Engineer Investigation

Open -> In Progress -> Resolved

The current implementation intentionally keeps incident ownership and closure under human control.

Future Enhancement Possibilities

Possible future improvements include:

Automatically resolve an OpsItem after verified remediation success

Automatically move an OpsItem to In Progress when automated remediation fails

Correlate Lambda remediation results with the corresponding OpsItem

Assign incident owners

Track incident response and resolution times

Add OpsCenter incident information to operational dashboards

Generate incident reports

Extend incident management to additional supported incident types

Conclusion

The SSM OpsCenter enhancement adds a formal incident-management capability to the existing CloudOps NOC V2.0 project without changing the original remediation architecture.

The original project already demonstrated:

Detect -> Remediate -> Verify -> Notify

The enhancement adds:

Record -> Track -> Resolve

Together, the project now demonstrates a more complete NOC incident lifecycle:

Detect
   |
   v
Record
   |
   v
Remediate
   |
   v
Verify
   |
   v
Notify / Escalate
   |
   v
Track
   |
   v
Resolve
