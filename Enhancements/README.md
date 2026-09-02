SSM OpsCenter Enhancement — Operational Incident Tracking

Post-Review Enhancement

This enhancement was implemented after the original CloudOps NOC Automation V2.0 baseline was reviewed.

The original V2.0 remediation architecture remains unchanged.
This enhancement adds AWS Systems Manager OpsCenter as a parallel operational incident-tracking capability for the existing P1 HTTPD alarm.

Overview

The original CloudOps NOC V2.0 project already provides:

P1 HTTPD monitoring with CloudWatch Agent

P1 detection using procstat_lookup_pid_count

Direct CloudWatch Alarm → Lambda invocation

Alarm parsing and Actionable Alarm Gate in Lambda

Automated HTTPD remediation through SSM Run Command

Recovery verification and stability verification

SNS recovery notification and escalation

P2 CPU monitoring as diagnostic-only

The OpsCenter enhancement adds one additional capability:

CloudWatch Alarm → Systems Manager OpsCenter → OpsItem

This allows a P1 incident to be formally recorded and tracked without changing the existing remediation workflow.

Architecture

Reviewed V2.0 remediation path

CloudWatch → Lambda → SSM Run Command → EC2 → HTTPD Recovery → Verification → SNS

Added OpsCenter path

CloudWatch → Systems Manager OpsCenter → OpsItem

Combined behavior

The existing P1 CloudWatch alarm, NOC-cloudops-automate, now performs two independent actions:

Lambda action — continues the existing P1 remediation workflow.

OpsCenter action — creates an OpsItem for operational tracking.

OpsCenter is not placed between CloudWatch and Lambda.
Both actions originate from the same CloudWatch alarm.

Architecture Evidence



Why OpsCenter Was Added

The original V2.0 workflow could detect, remediate, verify, and notify, but it did not maintain a formal operational record for the incident.

OpsCenter adds the ability to:

record that the incident occurred,

identify the originating CloudWatch alarm,

assign severity,

track the current status,

support engineer investigation,

and preserve a resolution record.

This adds operational tracking to the existing technical remediation workflow.

Original lifecycle: Detect → Decide → Remediate → Verify → Notify / Escalate

Enhanced lifecycle: Detect → Record → Remediate → Verify → Notify / Escalate → Track → Resolve

Systems Manager Responsibilities

AWS Systems Manager now performs two separate responsibilities in this project.

SSM Run Command

Used for technical remediation.

Lambda → Boto3 → SSM SendCommand → SSM Agent → EC2 → systemctl restart httpd

Responsibility: execute controlled remediation commands on the EC2 instance.

SSM OpsCenter

Used for operational incident tracking.

CloudWatch Alarm → OpsCenter → OpsItem

Responsibility: create and track an operational work item associated with the P1 incident.

OpsCenter is a capability within AWS Systems Manager.
It does not add an eighth primary AWS service to the project.

OpsItem

An OpsItem is the operational work item created in Systems Manager OpsCenter.

For the tested P1 HTTPD incident, the OpsItem contained information including:

Source: CloudWatch Alarm

Alarm: NOC-cloudops-automate

Severity: 1

Initial Status: Open

The OpsItem remains available as an operational record even after HTTPD has been recovered.

Open OpsItem



OpsItem Status Lifecycle

OpsItem creation is automatic in the current enhancement.

Status management is currently performed manually by the engineer.

Open

The OpsItem has been created and requires review.

In Progress

An engineer is actively investigating or working on the incident.



Resolved

The issue has been reviewed and closed.



Successful automatic recovery

When P1 remediation succeeds and no additional investigation is required:

Open → Resolved

Failed automatic recovery

When automatic remediation fails and an engineer must investigate:

Open → In Progress → Resolved

CloudWatch Alarm Change

The original Lambda alarm action was not removed or replaced.

The enhancement adds an additional Systems Manager OpsCenter action to the same P1 alarm.

Before

NOC-cloudops-automate → Lambda → Existing P1 Remediation

After

NOC-cloudops-automate → Lambda → Existing P1 Remediation

and, in parallel:

NOC-cloudops-automate → Systems Manager OpsCenter → OpsItem

CloudWatch Action Evidence



IAM and Authorization

The OpsCenter alarm action uses the AWS authorization path required for CloudWatch to create an OpsItem in Systems Manager.

Conceptually:

CloudWatch Alarm → Service-Linked Role → ssm:CreateOpsItem → OpsCenter

This is separate from:

the Lambda execution role,

the EC2 instance role,

and Lambda permissions used for SSM Run Command.

The existing remediation authorization model therefore remains unchanged.

Testing

The enhancement was tested using the existing P1 HTTPD failure scenario.

Test procedure

HTTPD was intentionally stopped.

CloudWatch Agent reported the HTTPD procstat metric.

procstat_lookup_pid_count indicated that the HTTPD process was unavailable.

NOC-cloudops-automate entered the ALARM state.

The existing direct CloudWatch → Lambda remediation path executed.

The new CloudWatch → OpsCenter action created an OpsItem.

HTTPD recovery was verified.

The OpsItem lifecycle was reviewed and manually updated.

The OpsItem was marked Resolved.

Verified results

✅ P1 HTTPD failure was detected.

✅ Direct CloudWatch → Lambda invocation remained active.

✅ Existing SSM remediation continued to work.

✅ HTTPD recovery was verified.

✅ OpsCenter created an OpsItem.

✅ The OpsItem identified the CloudWatch alarm source.

✅ Severity 1 was recorded.

✅ OpsItem status could be managed.

✅ The OpsItem was successfully marked Resolved.

Remediation vs Operational Tracking

Technical remediation

CloudWatch → Lambda → SSM Run Command → EC2

Purpose: recover the supported technical failure.

Operational tracking

CloudWatch → SSM OpsCenter → OpsItem

Purpose: record and track the operational issue.

These are separate responsibilities.

This enhancement uses AWS Systems Manager OpsCenter.
It does not implement AWS Systems Manager Incident Manager.

Project Scope After the Enhancement

The project still uses the same seven primary AWS services:

IAM

EC2

VPC

CloudWatch

SNS

Systems Manager

Lambda

Supporting capabilities include:

CloudWatch Agent

SSM Agent

Systems Manager Run Command

Systems Manager OpsCenter

Linux systemd

Boto3

The P1/P2 scope also remains unchanged:

P1 HTTPD: automated remediation

P2 CPU: diagnostic-only

Current Limitations

The current enhancement intentionally keeps incident ownership and closure under human control.

Current limitations:

OpsItem status changes are manual.

Lambda does not automatically resolve the OpsItem.

Lambda remediation results are not automatically correlated with the OpsItem.

OpsItem assignment is manual.

Incident response and resolution times are not automatically calculated.

OpsCenter tracking currently applies only to the supported P1 HTTPD scenario.

P2 remains diagnostic-only.

Future Improvements

Possible future improvements include:

automatically resolve the OpsItem after verified P1 recovery,

automatically move the OpsItem to In Progress when automated recovery fails,

correlate Lambda incident identifiers with OpsItems,

assign an incident owner,

calculate response and resolution times,

expose OpsCenter information through operational dashboards,

and generate incident reports.

These are future possibilities and are not part of the current implementation.

Conclusion

The OpsCenter enhancement adds operational incident recording and tracking to the existing CloudOps NOC Automation V2.0 project without replacing the reviewed remediation architecture.

Reviewed V2.0:
CloudWatch → Lambda → SSM Run Command → EC2 → Verification → SNS

Post-review enhancement:
CloudWatch → Systems Manager OpsCenter → OpsItem

The project now demonstrates two complementary operational capabilities:

Technical incident response + Operational incident tracking
