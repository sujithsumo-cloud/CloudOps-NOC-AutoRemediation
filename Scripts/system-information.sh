#!/bin/bash

echo "Hostname:"
hostname

echo ""

echo "Operating System:"
cat /etc/os-release

echo ""

echo "Kernel:"
uname -r

echo ""

echo "Disk Usage:"
df -h

echo ""

echo "Memory:"
free -h

echo ""

echo "CPU:"
lscpu
