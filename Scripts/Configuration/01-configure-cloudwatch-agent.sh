#!/bin/bash
set -Eeuo pipefail

# CloudOps NOC V2.0
# Apply the single canonical CloudWatch Agent JSON stored in:
# CloudWatch/cloudwatch-agent-config.json
#
# P1 source:
#   CloudWatch Agent -> procstat -> procstat_lookup_pid_count
#
# P2 source:
#   AWS/EC2 -> CPUUtilization
# The agent CPU metrics are additional observability only.

if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: Run this script as root:"
    echo "  sudo bash $0"
    exit 1
fi

AGENT_DIR="/opt/aws/amazon-cloudwatch-agent"
AGENT_CTL="${AGENT_DIR}/bin/amazon-cloudwatch-agent-ctl"
DEST_CONFIG="${AGENT_DIR}/etc/cloudops-noc-v2.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_CONFIG="${REPO_ROOT}/CloudWatch/cloudwatch-agent-config.json"

echo "================================================"
echo " CloudOps NOC V2.0 - Configure CloudWatch Agent"
echo "================================================"

echo "[1/6] Checking CloudWatch Agent..."
if [[ ! -x "${AGENT_CTL}" ]]; then
    echo "ERROR: CloudWatch Agent is not installed."
    echo "Run:"
    echo "  sudo bash Scripts/Installation/02-install-cloudwatch-agent.sh"
    exit 1
fi

echo "[2/6] Checking canonical configuration..."
if [[ ! -f "${SOURCE_CONFIG}" ]]; then
    echo "ERROR: Canonical config not found:"
    echo "  ${SOURCE_CONFIG}"
    exit 1
fi

echo "[3/6] Validating JSON..."
if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "${SOURCE_CONFIG}" >/dev/null
    echo "JSON is valid."
else
    echo "WARNING: python3 not found; skipping local JSON syntax validation."
fi

echo "[4/6] Installing canonical configuration..."
install -o root -g root -m 0644 "${SOURCE_CONFIG}" "${DEST_CONFIG}"

echo "[5/6] Loading configuration and starting agent..."
"${AGENT_CTL}" \
    -a fetch-config \
    -m ec2 \
    -c "file:${DEST_CONFIG}" \
    -s

echo "[6/6] Verifying CloudWatch Agent..."
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "SUCCESS: CloudWatch Agent is active."
else
    echo "ERROR: CloudWatch Agent is not active."
    systemctl status amazon-cloudwatch-agent --no-pager || true
    exit 1
fi

echo
echo "Canonical source : ${SOURCE_CONFIG}"
echo "Installed config : ${DEST_CONFIG}"
echo "Namespace        : CWAgent"
echo "Interval         : 60 seconds"
echo
echo "P1 monitoring:"
echo "  HTTPD -> procstat pid_count -> procstat_lookup_pid_count"
echo
echo "P2 monitoring:"
echo "  AWS/EC2 -> CPUUtilization -> cpu alert"
echo
echo "Agent CPU metrics are additional observability, not the P2 alarm source."
