#!/bin/bash

# Quick test deployment script
set -e

echo "Deploying Kubecost agent to local cluster..."

# Check if values file exists
if [ ! -f "values.yaml" ]; then
    echo "Error: values.yaml not found. Copy from values.yaml.example and update with your credentials."
    exit 1
fi

# Deploy with Helm
helm upgrade --install kubecost-agent kubecost/cost-analyzer \
    --namespace kubecost \
    --create-namespace \
    --values values.yaml \
    --wait

echo "Deployment complete!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n kubecost"
echo ""
echo "View logs with:"
echo "  kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer -f"
