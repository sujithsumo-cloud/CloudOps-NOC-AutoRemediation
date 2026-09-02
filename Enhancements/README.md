SSM OpsCenter Operational Incident Tracking Enhancement

Post-Review Enhancement

This folder documents an enhancement implemented after the CloudOps NOC Automation V2.0 baseline was reviewed.

The reviewed V2.0 remediation architecture remains the baseline:

CloudWatch Alarm
      ↓
Lambda
      ↓
SSM Run Command
      ↓
EC2
      ↓
HTTPD Remediation
      ↓
Verification / Stability Check
      ↓
SNS Notification or Escalation

This enhancement does not replace or redesign that flow. It adds AWS Systems Manager OpsCenter as a parallel alarm action so P1 incidents can also be recorded and tracked as OpsItems.

1. Enhancement Summary

The original CloudOps NOC Automation V2.0 project already handled the technical incident-response workflow for the supported incidents:

Detect
  ↓
Decide
  ↓
Remediate or Diagnose
  ↓
Verify
  ↓
Notify / Escalate

For P1 HTTPD, CloudWatch detects the HTTPD process failure and invokes Lambda directly. Lambda applies the Actionable Alarm Gate and uses Systems Manager Run Command to perform controlled remediation on EC2.

For P2 CPU, the workflow remains diagnostic-only. No automatic CPU remediation is introduced by this enhancement.

The new enhancement adds a second responsibility:

Record and track the P1 operational incident in Systems Manager OpsCenter.

When the existing P1 CloudWatch alarm enters the ALARM state, it now has two independent actions:

                     NOC-cloudops-automate
                              │
                 ┌────────────┴────────────┐
                 │                         │
                 ▼                         ▼
              Lambda                 SSM OpsCenter
                 │                         │
                 ▼                         ▼
          Existing P1 Flow              OpsItem

The Lambda remediation action remains unchanged.

2. Base Project

Item

Current Design

Project

CloudOps NOC Automation

Reviewed baseline

V2.0

Enhancement

Systems Manager OpsCenter operational incident tracking

Enhancement timing

Post-review

Scope

P1 HTTPD incident tracking

Primary P1 alarm

NOC-cloudops-automate

P2

CPU diagnostic-only; unchanged

Primary AWS services

IAM, EC2, VPC, CloudWatch, SNS, Systems Manager, Lambda

Service-count clarification

OpsCenter is a capability of AWS Systems Manager.

Therefore, the project still uses the same seven primary AWS services:

IAM
EC2
VPC
CloudWatch
SNS
Systems Manager
Lambda

OpsCenter is not counted as an eighth AWS service.

3. Why This Enhancement Was Added

The reviewed V2.0 implementation already automated technical response, but it did not maintain a formal OpsCenter record for each supported P1 alarm.

The enhancement adds an operational record containing information such as:

the event/alarm source,

the OpsItem creation time,

severity,

current status,

related alarm information,

and the final resolution state.

This improves the operational lifecycle from only responding to a problem to also recording and tracking it.

A simplified view is:

                     Detection
                        │
             ┌──────────┴──────────┐
             │                     │
             ▼                     ▼
        Technical Response      Incident Record
             │                     │
             ▼                     ▼
      Remediate / Verify          Track
             │                     │
             └──────────┬──────────┘
                        ▼
                 Notify / Resolve

4. Architecture

4.1 Reviewed V2.0 P1 Remediation Path

EC2 HTTPD
   ↓
CloudWatch Agent
   ↓
procstat_lookup_pid_count
   ↓
CloudWatch Alarm
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
SSM Agent on EC2
   ↓
systemctl restart httpd
   ↓
Verification
   ↓
One Retry if Required
   ↓
15-Second Stability Recheck
   ↓
SNS Recovery Notification
or
SNS Escalation

This remains the project's original P1 remediation path.

4.2 New OpsCenter Path

CloudWatch Alarm
NOC-cloudops-automate
        ↓
Systems Manager OpsCenter
        ↓
OpsItem
        ↓
Open
        ↓
Manual Status Management
        ↓
In Progress / Resolved

4.3 Combined Architecture

                         HTTPD Failure
                              │
                              ▼
                       CloudWatch Agent
                              │
                              ▼
                 procstat_lookup_pid_count
                              │
                              ▼
                    NOC-cloudops-automate
                              │
              ┌───────────────┴────────────────┐
              │                                │
              ▼                                ▼
           Lambda                        SSM OpsCenter
              │                                │
              ▼                                ▼
     Actionable Alarm Gate                   OpsItem
              │                                │
              ▼                                ▼
       SSM Run Command                       Open
              │                                │
              ▼                                │
             EC2                               │
              │                                │
              ▼                                │
     systemctl restart httpd                   │
              │                                │
              ▼                                │
        Verification                           │
              │                                │
        ┌─────┴─────┐                          │
        │           │                          │
        ▼           ▼                          │
     Success      Failure                      │
        │           │                          │
        ▼           ▼                          │
 SNS Recovery   SNS Escalation                 │
 Notification       │                          │
        │           ▼                          │
        │     Engineer Investigation           │
        │           │                          │
        │           └──────────────┐           │
        │                          │           │
        └──────────────────────────┼───────────┘
                                   ▼
                         Manual OpsItem Update
                                   │
                        ┌──────────┴───────────┐
                        ▼                      ▼
                   In Progress             Resolved

The two CloudWatch actions are parallel. OpsCenter does not sit between CloudWatch and Lambda.

5. Systems Manager Responsibilities

AWS Systems Manager now has two clearly separated responsibilities in this project.

Systems Manager capability

Responsibility

Run Command

Controlled command execution on EC2

OpsCenter

Operational issue recording and tracking

SSM Agent

Receives Systems Manager commands on the EC2 instance

Run Command — Technical Remediation

Lambda
   ↓
Boto3
   ↓
SSM SendCommand API
   ↓
AWS-RunShellScript
   ↓
SSM Agent
   ↓
EC2
   ↓
systemctl restart httpd

Purpose:

Fix the supported technical problem.

OpsCenter — Operational Tracking

CloudWatch Alarm
      ↓
OpsCenter Action
      ↓
OpsItem
      ↓
Status Tracking

Purpose:

Record what happened and track the operational issue to closure.

6. What Is an OpsItem?

An OpsItem is an operational work item stored in Systems Manager OpsCenter.

For this enhancement, the existing P1 alarm automatically creates an OpsItem when the alarm enters the ALARM state.

During testing, the OpsItem recorded information including:

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

Severity 1 was selected for the P1 test. In OpsCenter, severity values range from 1 to 4, with 1 representing the highest severity.

The OpsItem continues to provide an operational record even after HTTPD has recovered and can later be marked Resolved.

7. OpsItem Status Lifecycle

In the current implementation:

OpsItem creation is automatic.

Remediation remains automatic for the supported P1 failure.

OpsItem status changes are manual.

The relevant statuses used in this project are:

Status

Project Meaning

Open

OpsItem was created and requires review

In Progress

An engineer is actively investigating or working on the incident

Resolved

The operational issue has been closed

Scenario A — P1 Automated Recovery Succeeds

HTTPD Failure
      ↓
CloudWatch ALARM
      ↓
OpsItem Created: Open
      │
      └───────────────┐
                      │
Lambda + SSM Recovery │
      ↓               │
HTTPD Active          │
      ↓               │
Verification Passes   │
      ↓               │
SNS Recovery          │
Notification          │
      ↓               │
Engineer Reviews ─────┘
      ↓
Resolved

Typical status lifecycle:

Open → Resolved

In Progress is not required when automatic remediation succeeds and no additional investigation is needed.

Scenario B — P1 Automated Recovery Fails

HTTPD Failure
      ↓
CloudWatch ALARM
      ↓
OpsItem Created: Open
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

Typical status lifecycle:

Open → In Progress → Resolved

8. Implementation Change

Only one architectural capability was added to the existing P1 alarm.

Before the enhancement

NOC-cloudops-automate
        ↓
      Lambda
        ↓
Existing Automated Remediation

After the enhancement

                       NOC-cloudops-automate
                                │
                   ┌────────────┴────────────┐
                   │                         │
                   ▼                         ▼
                Lambda                 SSM OpsCenter
                   │                         │
                   ▼                         ▼
       Existing Automated Flow            OpsItem

The existing Lambda alarm action was not removed or replaced.

The CloudWatch alarm now performs an additional Systems Manager OpsCenter action when it enters the ALARM state.

9. IAM Behavior for the OpsCenter Alarm Action

The OpsCenter alarm action is authorized through the AWS-managed CloudWatch service-linked role used for Systems Manager alarm actions.

Conceptually:

CloudWatch Alarm
      ↓
AWS Service-Linked Role
      ↓
ssm:CreateOpsItem
      ↓
Systems Manager OpsCenter

This is separate from:

the Lambda execution role,

the EC2 instance role,

and the permissions Lambda uses to call Systems Manager Run Command.

This separation keeps the existing remediation authorization model unchanged.

10. Testing Performed

The enhancement was tested using the existing P1 HTTPD failure workflow.

Test Flow

HTTPD intentionally stopped
        ↓
CloudWatch Agent publishes procstat data
        ↓
procstat_lookup_pid_count indicates HTTPD is down
        ↓
NOC-cloudops-automate enters ALARM
        │
        ├──────────────→ Lambda remediation continues
        │
        └──────────────→ OpsCenter creates OpsItem
                              ↓
                             Open
        ↓
HTTPD recovery verified
        ↓
OpsItem manually updated
        ↓
Resolved

Test Results

Test Requirement

Result

P1 HTTPD failure detected

✅ Passed

Existing direct CloudWatch → Lambda action remained active

✅ Passed

OpsCenter alarm action created an OpsItem

✅ Passed

OpsItem identified the CloudWatch alarm source

✅ Passed

Severity 1 was recorded

✅ Passed

Existing SSM Run Command remediation continued to work

✅ Passed

HTTPD recovery was verified

✅ Passed

OpsItem status could be manually managed

✅ Passed

OpsItem was successfully marked Resolved

✅ Passed

11. Test Evidence

The following screenshots are included in this folder as implementation evidence.

Architecture



CloudWatch OpsCenter Alarm Action



OpsItem — Open



OpsItem — In Progress



OpsItem — Resolved



12. Remediation vs Operational Incident Tracking

These responsibilities must not be confused.

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

Purpose:

Correct the supported technical failure.

Operational Tracking

CloudWatch
   ↓
SSM OpsCenter
   ↓
OpsItem
   ↓
Open / In Progress / Resolved

Purpose:

Create and maintain an operational record of the issue.

Important: This enhancement uses Systems Manager OpsCenter. It does not implement AWS Systems Manager Incident Manager.

13. Component Responsibilities

Component

Responsibility

VPC

Network boundary and connectivity

EC2

Hosts Amazon Linux and HTTPD

CloudWatch Agent

Publishes the P1 HTTPD procstat metric

CloudWatch

Evaluates metrics and detects alarm conditions

Lambda

Parses the alarm, validates the actionable condition, and orchestrates the P1/P2 workflow

SSM Run Command

Executes controlled commands on EC2

SSM Agent

Receives and executes Systems Manager commands on EC2

SSM OpsCenter

Creates and tracks OpsItems

SNS

Recovery notification and escalation

IAM

Controls authorization between AWS components

CloudWatch Agent and SSM Agent are supporting agents, while OpsCenter and Run Command are capabilities of Systems Manager. They do not change the project's seven-primary-service count.

14. Impact on the Reviewed V2.0 Architecture

The reviewed remediation baseline remains:

CloudWatch
   ↓
Lambda
   ↓
SSM Run Command
   ↓
EC2
   ↓
Verification
   ↓
SNS

The post-review enhancement adds only this parallel path:

CloudWatch
   ↓
SSM OpsCenter
   ↓
OpsItem

Therefore:

Reviewed V2.0 baseline
        +
Post-review OpsCenter enhancement

rather than:

Original architecture replaced by OpsCenter

This distinction is intentional so the repository clearly separates the reviewed implementation from later learning and operational improvements.

15. Current Limitations

The current OpsCenter implementation intentionally keeps incident ownership and closure under human control.

Current limitations include:

OpsItem status changes are manual.

Lambda does not currently update the OpsItem status.

Lambda remediation results are not automatically linked back to a specific OpsItem.

OpsItem ownership/assignment is manual.

Incident response and resolution times are not automatically measured.

The enhancement currently covers the supported P1 HTTPD incident path only.

P2 remains diagnostic-only and is not part of this OpsCenter enhancement.

16. Future Enhancement Possibilities

Possible future improvements include:

automatically resolving the corresponding OpsItem after verified P1 recovery,

automatically changing the OpsItem to In Progress when automatic remediation fails,

correlating the Lambda incident ID with the related OpsItem,

assigning an incident owner,

measuring incident response and resolution times,

adding OpsCenter information to operational dashboards,

generating incident reports,

and extending OpsCenter tracking to additional supported incident types.

These are future possibilities, not part of the current implementation.

17. Key Learning

The enhancement demonstrates an important operational distinction:

Detection
≠
Remediation
≠
Incident Tracking

In this project:

CloudWatch
= Detect

Lambda
= Decide / Orchestrate

SSM Run Command
= Execute

systemd
= Manage HTTPD on Linux

SNS
= Notify / Escalate

SSM OpsCenter
= Record / Track

18. Conclusion

The Systems Manager OpsCenter enhancement adds formal operational issue tracking to the existing CloudOps NOC Automation V2.0 project without replacing its reviewed remediation architecture.

The reviewed baseline demonstrates:

Detect
   ↓
Decide
   ↓
Remediate / Diagnose
   ↓
Verify
   ↓
Notify / Escalate

The post-review OpsCenter enhancement adds:

Record
  ↓
Track
  ↓
Resolve

Together, the project demonstrates both:

technical incident response and operational incident tracking

while preserving the original CloudWatch → Lambda → Systems Manager Run Command architecture as the reviewed V2.0 baseline.
