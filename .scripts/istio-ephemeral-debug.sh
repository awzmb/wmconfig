#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <namespace> <pod_name>"
    exit 1
fi

NAMESPACE=$1
POD_NAME=$2

# run the kubectl debug command
kubectl debug -it $POD_NAME --image=nicolaka/netshoot --namespace=$NAMESPACE
