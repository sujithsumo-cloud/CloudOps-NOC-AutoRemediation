import json
import os
import time
from datetime import datetime, timezone

import boto3


# ============================================================
# AWS CLIENTS
# ============================================================

ssm = boto3.client("ssm")
sns = boto3.client("sns")
ec2 = boto3.client("ec2")


# ============================================================
# ENVIRONMENT
# ============================================================

INSTANCE_ID = os.environ["INSTANCE_ID"]
TOPIC_ARN = os.environ["TOPIC_ARN"]
ENVIRONMENT = os.environ.get("ENVIRONMENT", "Production")
REGION = os.environ.get("AWS_REGION", "ap-south-1")


# ============================================================
# ICONS
# ============================================================

ICON = {
    "detect": "🔍",
    "p1": "🛠️",
    "p2": "📊",
    "resolved": "✅",
    "failed": "❌",
    "escalated": "🚨",
    "mail": "📧",
}


# ============================================================
# ALARM CONFIGURATION
#
# ONLY THESE TWO ALARM NAMES ARE ACTIONABLE.
#
# NOC-cloudops-automate -> P1 -> HTTPD recovery
# cpu alert             -> P2 -> CPU diagnosis
#
# Unknown alarms are ignored.
# ============================================================

ALARM_CONFIG = {
    "NOC-cloudops-automate": {
        "priority": "P1",
        "severity": "P1 - Critical",
        "service": "Apache HTTP Server (httpd)",
        "icon": ICON["p1"],
        "action_type": "recovery",
        "metric_label": "procstat_lookup_pid_count",
        "threshold_label": "< 1",
        "remediation": [
            "systemctl restart httpd"
        ],
        "verify_command": "systemctl is-active httpd",
    },

    "cpu alert": {
        "priority": "P2",
        "severity": "P2 - High",
        "service": "EC2 CPU Utilization",
        "icon": ICON["p2"],
        "action_type": "diagnosis",
        "metric_label": "CPUUtilization",
        "threshold_label": "> 50%",
        "diagnostic_commands": [
            'echo "--- uptime / load ---"',
            "uptime",
            'echo "--- top 10 CPU consumers ---"',
            "ps aux --sort=-%cpu | head -11",
            'echo "--- memory ---"',
            "free -h",
        ],
    },
}


# ============================================================
# SNS TOPIC NAME
# ============================================================

def get_sns_topic_name():
    """
    Extract SNS topic name from the configured Topic ARN.

    Example:
        arn:aws:sns:ap-south-1:123456789012:CloudOps-NOC
        ->
        CloudOps-NOC
    """

    try:
        return TOPIC_ARN.split(":")[-1]
    except Exception:
        return "Unknown"


# ============================================================
# EC2 INSTANCE DETAILS
# ============================================================

def get_instance_details():
    """
    Fetch useful EC2 metadata for the incident email.
    """

    details = {
        "instance_name": INSTANCE_ID,
        "private_ip": "N/A",
        "availability_zone": "N/A",
    }

    try:
        response = ec2.describe_instances(
            InstanceIds=[INSTANCE_ID]
        )

        reservations = response.get("Reservations", [])

        if not reservations:
            return details

        instances = reservations[0].get("Instances", [])

        if not instances:
            return details

        instance = instances[0]

        details["private_ip"] = instance.get(
            "PrivateIpAddress",
            "N/A"
        )

        details["availability_zone"] = (
            instance.get("Placement", {})
            .get("AvailabilityZone", "N/A")
        )

        details["instance_name"] = next(
            (
                tag["Value"]
                for tag in instance.get("Tags", [])
                if tag["Key"] == "Name"
            ),
            INSTANCE_ID,
        )

    except Exception as e:

        print(
            f"Could not fetch EC2 instance details: {e}"
        )

    return details


# ============================================================
# BACKWARD-COMPATIBLE INSTANCE NAME
# ============================================================

def get_instance_name():

    return get_instance_details()["instance_name"]


# ============================================================
# STAGE 1
# PARSE DIRECT CLOUDWATCH ALARM -> LAMBDA EVENT
# ============================================================

def parse_alarm_context(event):
    """
    Parse a direct CloudWatch Alarm -> Lambda event.

    Architecture:

        CloudWatch Alarm
              ↓
           Lambda

    This is NOT an SNS event.

    Alarm information is contained inside:

        event["alarmData"]
    """

    try:

        alarm_data = event["alarmData"]

        alarm_name = alarm_data.get("alarmName")

        state_data = alarm_data.get("state", {})

        state = state_data.get("value")

        reason = state_data.get(
            "reason",
            ""
        )

        timestamp = state_data.get(
            "timestamp",
            datetime.now(timezone.utc).isoformat()
        )

        alarm_arn = event.get(
            "alarmArn",
            "N/A"
        )

        account_id = event.get(
            "accountId",
            "N/A"
        )

        event_region = event.get(
            "region",
            REGION
        )

        if not alarm_name:

            print(
                "No alarmName found. Ignoring event."
            )

            return None

        print(
            f"CloudWatch event parsed successfully | "
            f"Alarm={alarm_name} | "
            f"State={state}"
        )

        return {
            "alarm_name": alarm_name,
            "state": state,
            "reason": reason,
            "timestamp": timestamp,
            "alarm_arn": alarm_arn,
            "account_id": account_id,
            "event_region": event_region,
        }

    except (KeyError, TypeError) as e:

        print(
            f"Event is not a valid direct "
            f"CloudWatch alarm event: {e}"
        )

        return None


# ============================================================
# INCIDENT DETECTION
# ============================================================

def detect_incident(event):
    """
    Single classification gate.

    Priority is determined ONLY by exact CloudWatch
    alarm name.

    Unknown alarm names:
        ignored
        no SSM
        no SNS
        no email
    """

    context = parse_alarm_context(event)

    if context is None:

        print(
            "No actionable CloudWatch alarm event."
        )

        return None

    alarm_name = context["alarm_name"]
    state = context["state"]

    if state != "ALARM":

        print(
            f"Alarm '{alarm_name}' state is '{state}'. "
            "Only ALARM state is actionable."
        )

        return None

    config = ALARM_CONFIG.get(alarm_name)

    if config is None:

        print(
            f"Unrecognized alarm '{alarm_name}'. "
            "Ignoring it. No notification will be sent."
        )

        return None

    print(
        f"{ICON['detect']} DETECTED | "
        f"{config['priority']} | "
        f"{alarm_name}"
    )

    return {
        **context,
        **config,
    }


# ============================================================
# INCIDENT ID
# ============================================================

def get_incident_id():
    """
    Generate daily sequential incident IDs.

    Example:
        INC-20260811-0001
    """

    today = datetime.now(timezone.utc).strftime(
        "%Y%m%d"
    )

    parameter_name = (
        f"/cloudops/incident-counter/{today}"
    )

    try:

        current = int(
            ssm.get_parameter(
                Name=parameter_name
            )["Parameter"]["Value"]
        )

    except ssm.exceptions.ParameterNotFound:

        current = 0

    next_count = current + 1

    ssm.put_parameter(
        Name=parameter_name,
        Value=str(next_count),
        Type="String",
        Overwrite=True,
    )

    return f"INC-{today}-{next_count:04d}"


# ============================================================
# SSM COMMAND EXECUTION
# ============================================================

def run_ssm(commands, comment):
    """
    Execute an SSM command and monitor it.

    Returns:

        {
            "command_id": "...",
            "result": {...}
        }
    """

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": commands
        },
        Comment=comment,
    )

    command_id = response["Command"]["CommandId"]

    print(
        f"SSM Command ID: {command_id}"
    )

    for attempt in range(20):

        time.sleep(3)

        try:

            result = ssm.get_command_invocation(
                CommandId=command_id,
                InstanceId=INSTANCE_ID,
            )

            status = result["Status"]

            print(
                f"Attempt {attempt + 1}: "
                f"Status = {status}"
            )

            if status in (
                "Success",
                "Failed",
                "TimedOut",
                "Cancelled",
            ):

                return {
                    "command_id": command_id,
                    "result": result,
                }

        except ssm.exceptions.InvocationDoesNotExist:

            continue

    print(
        f"SSM command timed out while waiting: "
        f"{command_id}"
    )

    return {
        "command_id": command_id,
        "result": None,
    }


# ============================================================
# EMAIL PIPELINE
# ============================================================

def pipeline_strip(*stages):

    return "   →   ".join(stages)


# ============================================================
# EMAIL BUILDER
# ============================================================

def build_email(
    incident_id,
    incident,
    instance_details,
    pipeline,
    status,
    resolution_time,
    manual_action,
    extra="",
    ssm_command_id="N/A",
    stability_command_id="N/A",
    initial_check="N/A",
    stability_check="N/A",
    final_service_status="N/A",
    recovery_status="N/A",
):
    """
    Build the detailed CloudOps NOC email.
    """

    instance_name = instance_details["instance_name"]
    private_ip = instance_details["private_ip"]
    availability_zone = instance_details[
        "availability_zone"
    ]

    sns_topic_name = get_sns_topic_name()

    return f"""
============================================================
CLOUDOPS NOC AUTOMATION
============================================================

INCIDENT DETAILS
------------------------------------------------------------

Incident ID        : {incident_id}
Priority           : {incident["priority"]}
Severity           : {incident["severity"]}
Environment        : {ENVIRONMENT}
Service            : {incident["service"]}

Detection Time     : {incident["timestamp"]}
Alarm State        : {incident["state"]}
Alarm Reason       : {incident["reason"]}

AWS Account ID     : {incident["account_id"]}
AWS Region         : {incident["event_region"]}

============================================================
AFFECTED EC2 RESOURCE
============================================================

Instance Name      : {instance_name}
Instance ID        : {INSTANCE_ID}
Private IP         : {private_ip}
Availability Zone  : {availability_zone}

============================================================
CLOUDWATCH ALARM
============================================================

Alarm Name         : {incident["alarm_name"]}
Alarm ARN          : {incident["alarm_arn"]}
Detection Source   : CloudWatch Alarm
Detection Metric   : {incident.get("metric_label", "N/A")}
Threshold          : {incident.get("threshold_label", "N/A")}

============================================================
SNS NOTIFICATION
============================================================

SNS Topic Name     : {sns_topic_name}
SNS Topic ARN      : {TOPIC_ARN}

============================================================
AUTOMATION PIPELINE
============================================================

{pipeline}

============================================================
REMEDIATION DETAILS
============================================================

SSM Command ID     : {ssm_command_id}
Initial Check      : {initial_check}
Stability Check    : {stability_check}
Final Service      : {final_service_status}

Recovery Status    : {recovery_status}

============================================================
INCIDENT STATUS
============================================================

Status             : {status}
Resolution Time    : {resolution_time}
Manual Action      : {manual_action}

{extra}

============================================================
CLOUDOPS NOC AUTOMATION
============================================================

Automated Incident Detection & Remediation
AWS Region: {incident["event_region"]}

"""


# ============================================================
# SNS EMAIL
# ============================================================

def send_mail(subject, body):

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject=subject[:100],
        Message=body,
    )

    print(
        f"{ICON['mail']} Notification sent: {subject}"
    )


# ============================================================
# P1
# HTTPD RECOVERY
# ============================================================

def handle_p1(
    incident_id,
    incident,
    instance_details,
    start_time,
):

    instance_name = instance_details["instance_name"]

    # --------------------------------------------------------
    # INITIAL INCIDENT EMAIL
    # --------------------------------------------------------

    pipeline = pipeline_strip(
        "🔍 DETECTED",
        "🛠️ RECOVERING",
    )

    send_mail(
        subject=(
            f"🛠️ [{incident['severity']}] "
            f"{incident['service']} Down | "
            f"{instance_name} | "
            f"{REGION}"
        ),
        body=build_email(
            incident_id,
            incident,
            instance_details,
            pipeline,
            status=(
                "Detected -- httpd recovery initiated"
            ),
            resolution_time="In progress",
            manual_action="Pending",
            initial_check="Pending",
            stability_check="Pending",
            final_service_status="Unknown",
            recovery_status="In progress",
        ),
    )

    # --------------------------------------------------------
    # INITIAL HTTPD RECOVERY
    # --------------------------------------------------------

    commands = incident["remediation"] + [
        "sleep 5",
        incident["verify_command"],
    ]

    initial_execution = run_ssm(
        commands,
        comment=(
            f"NOC {incident_id} "
            "P1 httpd recovery"
        ),
    )

    initial_command_id = (
        initial_execution["command_id"]
        if initial_execution
        else "N/A"
    )

    initial_result = (
        initial_execution["result"]
        if initial_execution
        else None
    )

    # --------------------------------------------------------
    # VERIFY INITIAL HTTPD STATUS
    # --------------------------------------------------------

    def is_active(result_data):

        if not result_data:
            return False

        if result_data["Status"] != "Success":
            return False

        output = (
            result_data
            .get("StandardOutputContent", "")
            .strip()
        )

        lines = output.splitlines()

        if not lines:
            return False

        return lines[-1].strip() == "active"

    status_ok = is_active(initial_result)

    initial_check_status = (
        "PASSED"
        if status_ok
        else "FAILED"
    )

    # --------------------------------------------------------
    # STABILITY VERIFICATION
    # --------------------------------------------------------

    stability_command_id = "N/A"
    stability_check_status = "NOT PERFORMED"

    if status_ok:

        print(
            "Initial httpd check passed. "
            "Performing stability recheck in 15 seconds."
        )

        recheck = run_ssm(
            [
                "sleep 15",
                incident["verify_command"],
            ],
            comment=(
                f"NOC {incident_id} "
                "P1 httpd stability verification"
            ),
        )

        stability_command_id = (
            recheck["command_id"]
            if recheck
            else "N/A"
        )

        recheck_result = (
            recheck["result"]
            if recheck
            else None
        )

        status_ok = is_active(
            recheck_result
        )

        stability_check_status = (
            "PASSED"
            if status_ok
            else "FAILED"
        )

    # --------------------------------------------------------
    # FINAL SERVICE STATUS
    # --------------------------------------------------------

    final_service_status = (
        "ACTIVE / RUNNING"
        if status_ok
        else "NOT CONFIRMED ACTIVE"
    )

    resolution_time = (
        f"{int(time.time() - start_time)} seconds"
    )

    # --------------------------------------------------------
    # RESOLVED
    # --------------------------------------------------------

    if status_ok:

        pipeline = pipeline_strip(
            "🔍 DETECTED",
            "🛠️ RECOVERED",
            "✅ RESOLVED",
        )

        subject = (
            f"✅ [{incident['severity']}] "
            f"{incident['service']} Resolved | "
            f"{instance_name} | "
            f"{REGION} | "
            f"{resolution_time}"
        )

        status = (
            "Resolved -- httpd active and stable"
        )

        manual_action = "Not required"

        recovery_status = (
            "SUCCESS -- HTTPD recovered and "
            "passed stability verification"
        )

    # --------------------------------------------------------
    # FAILED / ESCALATED
    # --------------------------------------------------------

    else:

        pipeline = pipeline_strip(
            "🔍 DETECTED",
            "❌ RECOVERY FAILED",
            "🚨 ESCALATED",
        )

        subject = (
            f"🚨 [{incident['severity']}] "
            f"{incident['service']} Escalation | "
            f"{instance_name} | "
            f"{REGION} | "
            "Manual Action Required"
        )

        status = (
            "Auto-remediation failed -- "
            "httpd was not confirmed active"
        )

        manual_action = (
            "Required -- investigate the EC2 instance"
        )

        recovery_status = (
            "FAILED -- manual investigation required"
        )

    # --------------------------------------------------------
    # FINAL EMAIL
    # --------------------------------------------------------

    extra = f"""
============================================================
RECOVERY VERIFICATION
============================================================

Initial SSM Command : {initial_command_id}
Initial HTTPD Check : {initial_check_status}

Stability SSM Cmd   : {stability_command_id}
Stability Check     : {stability_check_status}

Final HTTPD Status  : {final_service_status}

The Apache HTTP Server was automatically remediated
and independently verified through the NOC stability
verification workflow.
"""

    send_mail(
        subject,
        build_email(
            incident_id,
            incident,
            instance_details,
            pipeline,
            status,
            resolution_time,
            manual_action,
            extra=extra,
            ssm_command_id=initial_command_id,
            stability_command_id=stability_command_id,
            initial_check=initial_check_status,
            stability_check=stability_check_status,
            final_service_status=final_service_status,
            recovery_status=recovery_status,
        ),
    )

    return {
        "incidentId": incident_id,
        "priority": "P1",
        "resolved": status_ok,
        "resolutionTime": resolution_time,
        "initialSsmCommandId": initial_command_id,
        "stabilitySsmCommandId": stability_command_id,
        "initialCheck": initial_check_status,
        "stabilityCheck": stability_check_status,
    }


# ============================================================
# P2
# CPU DIAGNOSIS ONLY
#
# IMPORTANT:
# There is NO restart command here.
# ============================================================

def handle_p2(
    incident_id,
    incident,
    instance_details,
    start_time,
):

    instance_name = instance_details["instance_name"]

    # --------------------------------------------------------
    # INITIAL P2 EMAIL
    # --------------------------------------------------------

    pipeline = pipeline_strip(
        "🔍 DETECTED",
        "📊 DIAGNOSING",
    )

    send_mail(
        subject=(
            f"📊 [{incident['severity']}] "
            f"High CPU Detected | "
            f"{instance_name} | "
            f"{REGION}"
        ),
        body=build_email(
            incident_id,
            incident,
            instance_details,
            pipeline,
            status=(
                "Detected -- collecting CPU diagnostics"
            ),
            resolution_time="In progress",
            manual_action="Pending",
            recovery_status="Diagnosis in progress",
        ),
    )

    # --------------------------------------------------------
    # CPU DIAGNOSTICS
    # --------------------------------------------------------

    execution = run_ssm(
        incident["diagnostic_commands"],
        comment=(
            f"NOC {incident_id} "
            "P2 CPU diagnosis"
        ),
    )

    command_id = (
        execution["command_id"]
        if execution
        else "N/A"
    )

    result = (
        execution["result"]
        if execution
        else None
    )

    if result:

        output = (
            result
            .get("StandardOutputContent", "")
            .strip()
        )

        diagnostic_status = result.get(
            "Status",
            "Unknown"
        )

    else:

        output = ""

        diagnostic_status = "No result"

    if not output:

        output = (
            "(No diagnostic output captured. "
            "Check SSM Run Command history.)"
        )

    resolution_time = (
        f"{int(time.time() - start_time)} seconds"
    )

    # --------------------------------------------------------
    # P2 DIAGNOSIS COMPLETE / ESCALATED
    # --------------------------------------------------------

    pipeline = pipeline_strip(
        "🔍 DETECTED",
        "📊 DIAGNOSED",
        "🚨 ESCALATED",
    )

    send_mail(
        subject=(
            f"🚨 [{incident['severity']}] "
            f"CPU Diagnostic Report | "
            f"{instance_name} | "
            f"{REGION} | "
            "Review Required"
        ),
        body=build_email(
            incident_id,
            incident,
            instance_details,
            pipeline,
            status=(
                "Diagnosed -- no auto-fix applied "
                "for CPU; handed to on-call"
            ),
            resolution_time=resolution_time,
            manual_action=(
                "Required -- review diagnostic output"
            ),
            extra=f"""
============================================================
CPU DIAGNOSTIC EXECUTION
============================================================

SSM Command ID     : {command_id}
SSM Result         : {diagnostic_status}

============================================================
DIAGNOSTIC OUTPUT
============================================================

{output}

============================================================
P2 AUTOMATION POLICY
============================================================

CPU automation is diagnostic-only.

No automatic restart or destructive remediation
was performed.
""",
            ssm_command_id=command_id,
            initial_check=diagnostic_status,
            final_service_status="N/A",
            recovery_status=(
                "DIAGNOSIS COMPLETE -- "
                "manual review required"
            ),
        ),
    )

    return {
        "incidentId": incident_id,
        "priority": "P2",
        "resolved": False,
        "resolutionTime": resolution_time,
        "ssmCommandId": command_id,
        "diagnosticStatus": diagnostic_status,
    }


# ============================================================
# LAMBDA ENTRY POINT
# ============================================================

def lambda_handler(event, context):

    start_time = time.time()

    print(
        "=================================================="
    )

    print(
        "CloudOps NOC Lambda invoked"
    )

    print(
        "=================================================="
    )

    # --------------------------------------------------------
    # STEP 1
    # DETECT AND CLASSIFY REAL CLOUDWATCH ALARM
    # --------------------------------------------------------

    incident = detect_incident(event)

    # --------------------------------------------------------
    # IMPORTANT:
    #
    # Unknown/manual/test events STOP HERE.
    #
    # NO incident ID
    # NO SSM command
    # NO SNS email
    # --------------------------------------------------------

    if incident is None:

        return {
            "statusCode": 200,
            "body": (
                "No actionable "
                "CloudWatch alarm event"
            ),
        }

    # --------------------------------------------------------
    # STEP 2
    # CREATE INCIDENT
    # --------------------------------------------------------

    incident_id = get_incident_id()

    instance_details = (
        get_instance_details()
    )

    instance_name = (
        instance_details["instance_name"]
    )

    print(
        f"{incident['icon']} "
        f"{incident_id} | "
        f"{incident['priority']} | "
        f"{incident['alarm_name']} | "
        f"{instance_name}"
    )

    # --------------------------------------------------------
    # STEP 3
    # SEPARATE P1 AND P2 PATHS
    # --------------------------------------------------------

    if incident["priority"] == "P1":

        result = handle_p1(
            incident_id,
            incident,
            instance_details,
            start_time,
        )

    elif incident["priority"] == "P2":

        result = handle_p2(
            incident_id,
            incident,
            instance_details,
            start_time,
        )

    else:

        print(
            f"Unknown priority "
            f"{incident['priority']}. "
            "Ignoring event."
        )

        return {
            "statusCode": 200,
            "body": "Unknown priority ignored",
        }

    return {
        "statusCode": 200,
        "body": json.dumps(result),
    }
