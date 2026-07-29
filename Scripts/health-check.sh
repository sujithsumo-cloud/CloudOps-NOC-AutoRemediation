#!/bin/bash

echo "HTTP Check"
curl http://localhost

echo ""

echo "HTTPS Check"
curl -k https://localhost
