# IAM Troubleshooting Guide

## EC2 Not Showing as Managed Instance

Possible Cause

Missing AmazonSSMManagedInstanceCore policy.

---

## Lambda Access Denied

Possible Cause

Missing ssm:SendCommand permission.

---

## CloudWatch Logs Not Generated

Possible Cause

Missing AWSLambdaBasicExecutionRole policy.

---

## Run Command Failed

Possible Cause

EC2 IAM Role missing.

---

## Verify Attached Role

AWS Console

↓

EC2

↓

Instance

↓

Security

↓

IAM Role

---

## Common Investigation

- Verify IAM Role attachment.
- Verify Trust Relationship.
- Verify Attached Policies.
- Review CloudTrail events if permission issues persist.
