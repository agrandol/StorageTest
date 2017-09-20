#!/bin/sh
#
# Filename: view-test-results.sh
#
#set -x

# Useful variables
POD_NAME_STEM="block-storage"

# Find the pod that is running
RUNNING_POD_NAME=`kubectl get --no-headers=true pods -o wide | grep ${POD_NAME_STEM} | grep Running | awk '{print $1}'`

# Watch the logs for results
kubectl logs ${RUNNING_POD_NAME}
