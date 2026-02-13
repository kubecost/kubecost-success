#!/bin/bash

# Script to create a Kubernetes deployment with constant CPU load (~200m per pod)
# and ResourceQuota for the namespace
# Usage: ./create-cpu-load-deployment.sh [namespace] [deployment-name]

# Default values
DEFAULT_NAMESPACE="cpu-load-test"
DEFAULT_DEPLOYMENT_NAME="cpu-load-deployment"

# Get parameters or use defaults
NAMESPACE="${1:-$DEFAULT_NAMESPACE}"
DEPLOYMENT_NAME="${2:-$DEFAULT_DEPLOYMENT_NAME}"

echo "================================================"
echo "CPU Load Deployment Creation Script"
echo "================================================"
echo "Namespace: $NAMESPACE"
echo "Deployment Name: $DEPLOYMENT_NAME"
echo "Replicas: 2"
echo "CPU Load per Pod: ~200m (0.2 cores)"
echo "Total CPU Load: ~400m (0.4 cores)"
echo "Resource Quota: 500m CPU, 600Mi Memory"
echo "================================================"

# Create namespace
echo ""
echo "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Namespace '$NAMESPACE' created successfully"
elif kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "ℹ Namespace '$NAMESPACE' already exists"
else
    echo "✗ Failed to create namespace '$NAMESPACE'"
    exit 1
fi

# Create ResourceQuota
echo ""
echo "Creating ResourceQuota for namespace: $NAMESPACE"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.cpu: "500m"
    requests.memory: "600Mi"
    limits.cpu: "500m"
    limits.memory: "600Mi"
EOF

if [ $? -eq 0 ]; then
    echo "✓ ResourceQuota created successfully"
else
    echo "✗ Failed to create ResourceQuota"
    exit 1
fi

# Display ResourceQuota
echo ""
echo "ResourceQuota Details:"
kubectl describe resourcequota compute-quota -n "$NAMESPACE"

# Create deployment manifest with CPU stress
echo ""
echo "Creating deployment with CPU load: $DEPLOYMENT_NAME"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cpu-load
  template:
    metadata:
      labels:
        app: cpu-load
    spec:
      containers:
      - name: cpu-stress
        image: progrium/stress
        command: ["stress"]
        args:
          - "--cpu"
          - "1"
          - "--timeout"
          - "3600s"
        resources:
          limits:
            memory: 256Mi
            cpu: 200m
          requests:
            memory: 128Mi   
            cpu: 200m
EOF

if [ $? -eq 0 ]; then
    echo "✓ Deployment '$DEPLOYMENT_NAME' created successfully in namespace '$NAMESPACE'"
else
    echo "✗ Failed to create deployment '$DEPLOYMENT_NAME'"
    exit 1
fi

# Wait a moment for pods to start
echo ""
echo "Waiting for pods to start..."
sleep 5

# Display deployment status
echo ""
echo "================================================"
echo "Deployment Status"
echo "================================================"
kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"

echo ""
echo "================================================"
echo "Pod Status"
echo "================================================"
kubectl get pods -n "$NAMESPACE" -l app=cpu-load

echo ""
echo "================================================"
echo "ResourceQuota Usage"
echo "================================================"
kubectl get resourcequota compute-quota -n "$NAMESPACE"

echo ""
echo "================================================"
echo "Resource Usage (wait ~30 seconds for metrics)"
echo "================================================"
echo "Run this command to see CPU usage:"
echo "  kubectl top pods -n $NAMESPACE"

echo ""
echo "================================================"
echo "Script completed successfully!"
echo "================================================"
echo ""
echo "Useful commands:"
echo "  View deployment details: kubectl describe deployment $DEPLOYMENT_NAME -n $NAMESPACE"
echo "  View pods: kubectl get pods -n $NAMESPACE"
echo "  View pod logs: kubectl logs -n $NAMESPACE -l app=cpu-load"
echo "  View CPU usage: kubectl top pods -n $NAMESPACE"
echo "  View ResourceQuota: kubectl describe resourcequota compute-quota -n $NAMESPACE"
echo "  Delete deployment: kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE"
echo "  Delete namespace: kubectl delete namespace $NAMESPACE"
echo "================================================"