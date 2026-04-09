#!/bin/bash

# Helper script to continue setup after Docker installation
# This refreshes your group membership and continues the setup

echo "=========================================="
echo "Continuing Kubecost Setup"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Refresh your Docker group membership"
echo "2. Continue with cluster creation"
echo ""

# Check if Docker is accessible
if docker info >/dev/null 2>&1; then
    echo "✓ Docker is accessible"
else
    echo "Refreshing Docker group membership..."
    echo "You may need to enter your password."
    exec newgrp docker <<EONG
./scripts/setup-local-test-environment.sh
EONG
fi

# Made with Bob
