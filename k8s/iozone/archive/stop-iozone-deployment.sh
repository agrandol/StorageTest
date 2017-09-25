#!/bin/sh
#
# Filename: stop-iozone-deployment.sh
#
# Stop IOzone deployments
#
# NOTE: If you are obtaining the results from the log or files, be sure to
#       gather the results prior to stopping the deployments.
#
#set -x

# Useful variables
DEPLOYMENT_STEM="iozone"

# Delete the deployments
kubectl delete deployment $( \
        kubectl get --no-headers deployments | \
		grep ${DEPLOYMENT_STEM} | \
		awk '{print $1}' | tr '\n' ' ')
