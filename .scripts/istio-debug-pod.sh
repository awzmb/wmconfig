#!/bin/bash

# Check if the required input variables are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <namespace> <serviceaccount>"
  exit 1
fi

NAMESPACE=$1
SERVICEACCOUNT=$2

# Define the YAML content for the debug pod
POD_YAML=$(cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: netshoot-mesh-debug
  labels:
    sidecar.istio.io/inject: "true"
spec:
  serviceAccount: $SERVICEACCOUNT
  serviceAccountName: $SERVICEACCOUNT
  containers:
  - name: tmp-shell
    image: nicolaka/netshoot
    tty: true
EOF
)

# Create the debug pod in the specified namespace
echo "$POD_YAML" | kubectl apply -f - -n $NAMESPACE

# Check if the pod was created successfully
if [ $? -eq 0 ]; then
  echo "Debug pod 'netshoot-mesh-debug' created successfully in namespace '$NAMESPACE'."
else
  echo "Failed to create the debug pod."
  exit 1
fi

# Wait for the pod to be in a running state
echo "Waiting for the pod to be in a running state..."
kubectl wait --for=condition=Ready pod/netshoot-mesh-debug -n $NAMESPACE --timeout=60s

# Check if the pod is ready
if [ $? -eq 0 ]; then
  echo "Debug pod 'netshoot-mesh-debug' is ready."
else
  echo "Debug pod 'netshoot-mesh-debug' is not ready."
  exit 1
fi

# Get the pod details
kubectl get pod netshoot-mesh-debug -n $NAMESPACE -o wide

# Provide instructions to exec into the pod
echo "To exec into the pod, run:"
echo "kubectl exec -it netshoot-mesh-debug -n $NAMESPACE -- /bin/bash"
