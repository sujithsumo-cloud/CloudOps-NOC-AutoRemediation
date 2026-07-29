import boto3
import time
import os

ssm = boto3.client("ssm")
sns = boto3.client("sns")

INSTANCE_ID = os.environ["INSTANCE_ID"]
TOPIC_ARN   = os.environ["TOPIC_ARN"]


def run_command(commands):
    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": commands}
    )

    command_id = response["Command"]["CommandId"]
    print(f"SSM Command ID: {command_id}")

    for attempt in range(20):
        time.sleep(3)

        try:
            result = ssm.get_command_invocation(
                CommandId=command_id,
                InstanceId=INSTANCE_ID
            )

            status = result["Status"]
            print(f"Attempt {attempt+1}: Status = {status}")

            if status in ["Success", "Failed", "TimedOut", "Cancelled"]:
                return result

        except ssm.exceptions.InvocationDoesNotExist:
            # SSM not registered yet — keep waiting
            print(f"Attempt {attempt+1}: Waiting for SSM to register...")
            continue

    return None


def lambda_handler(event, context):
    print("NOC Auto Remediation started.")
    print(f"Instance: {INSTANCE_ID}")

    # ── Restart httpd ─────────────────────────────────────────
    restart = run_command([
        "systemctl restart httpd",
        "sleep 5",
        "systemctl is-active httpd"
    ])

    # ── SSM Timed out ─────────────────────────────────────────
    if restart is None:
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="🚨 CloudOps Auto Remediation Failed",
            Message=f"""
NOC AUTO REMEDIATION - TIMEOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Instance : {INSTANCE_ID}
Service  : httpd (Apache)
Problem  : SSM command timed out
Action   : Manual investigation required!
            """
        )
        return {"statusCode": 500, "message": "SSM timed out"}

    # ── Check final status ────────────────────────────────────
    output_lines = restart["StandardOutputContent"].strip().split("\n")
    status = output_lines[-1].strip()
    print(f"Final httpd status: {status}")

    # ── httpd restarted successfully ──────────────────────────
    if status == "active":
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="✅ CloudOps Incident Resolved",
            Message=f"""
NOC AUTO REMEDIATION - SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Instance : {INSTANCE_ID}
Service  : httpd (Apache)
Action   : systemctl restart httpd
Result   : ✅ Apache is now ACTIVE

Incident resolved automatically.
No manual action needed.
            """
        )

    # ── httpd still failed after restart ─────────────────────
    else:
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="🚨 CloudOps Incident Escalation",
            Message=f"""
NOC AUTO REMEDIATION - FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Instance : {INSTANCE_ID}
Service  : httpd (Apache)
Action   : systemctl restart httpd
Result   : ❌ Apache still {status}

MANUAL INVESTIGATION REQUIRED!
Steps:
1. Connect via SSM Session Manager
2. Run: systemctl status httpd
3. Run: journalctl -u httpd -n 50
4. Run: apachectl configtest
            """
        )

    return {
        "statusCode": 200,
        "instance": INSTANCE_ID,
        "final_status": status
    }
