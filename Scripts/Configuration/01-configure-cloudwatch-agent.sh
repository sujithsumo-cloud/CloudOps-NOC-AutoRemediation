#!/bin/bash

set -e

echo "================================================"
echo " CloudOps NOC V2.0 - CloudWatch Agent Config"
echo "================================================"

AGENT_DIR="/opt/aws/amazon-cloudwatch-agent"
CONFIG_FILE="${AGENT_DIR}/etc/p1-p2-final.json"

echo "[1/5] Checking CloudWatch Agent..."

if [ ! -x "${AGENT_DIR}/bin/amazon-cloudwatch-agent-ctl" ]; then
    echo "ERROR: CloudWatch Agent is not installed."
    echo "Run 02-install-cloudwatch-agent.sh first."
    exit 1
fi

echo "CloudWatch Agent found."

echo "[2/5] Creating P1/P2 configuration..."

sudo tee "${CONFIG_FILE}" > /dev/null <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "totalcpu": true,
        "resources": [
          "*"
        ]
      },
      "procstat": [
        {
          "exe": "httpd",
          "measurement": [
            "pid_count"
          ],
          "metrics_collection_interval": 60
        }
      ]
    },
    "append_dimensions": {
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    }
  }
}
EOF

echo "Configuration file created:"
echo "${CONFIG_FILE}"

echo "[3/5] Validating configuration..."

"${AGENT_DIR}/bin/amazon-cloudwatch-agent-ctl" \
    -a fetch-config \
    -m ec2 \
    -c "file:${CONFIG_FILE}" \
    -s

echo "[4/5] Checking generated configuration..."

if grep -q '\[\[inputs.procstat\]\]' \
    "${AGENT_DIR}/etc/amazon-cloudwatch-agent.toml"; then
    echo "P1 HTTPD procstat configuration detected."
else
    echo "ERROR: procstat configuration was not generated."
    exit 1
fi

if grep -q '\[\[inputs.cpu\]\]' \
    "${AGENT_DIR}/etc/amazon-cloudwatch-agent.toml"; then
    echo "P2 CPU configuration detected."
else
    echo "ERROR: CPU configuration was not generated."
    exit 1
fi

echo "[5/5] Checking CloudWatch Agent service..."

systemctl is-active --quiet amazon-cloudwatch-agent

echo
echo "=============================================="
echo " CloudWatch Agent configuration completed."
echo "=============================================="
echo
echo "Configuration : ${CONFIG_FILE}"
echo "P1 metric     : procstat_lookup_pid_count"
echo "P2 metrics    : CPU utilization"
echo "Interval      : 60 seconds"
echo "Namespace     : CWAgent"
echo "Service       : $(systemctl is-active amazon-cloudwatch-agent)"
