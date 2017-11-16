#!/bin/sh
#
# Filename: run-websvr.sh
#
# Run the pywebsvr to collect results. A PVC will be claimed to collect all results.
#
# vim: tabstop=4: noexpandtab
#set -x

# k8s commands
#KUBECTL="kubectl" # for local minikube
KUBECTL="oc"     # for Redhat based systems

# PVC information
WEBSVR_PVC_NAME="pywebsvr-pvc"
WEBSVR_PVC_YAML_FILE="pywebsvr-pvc.yml"

# webserver information
WEBSVR_YAML_FILE="pywebsvr-deployment.yml"

# general information
CWD=`pwd`

# does the webserver PVC exist
${KUBECTL} get pvc | grep ${WEBSVR_PVC_NAME} > /dev/null

# if the webserver PVC has not been allocated
if [ $? -ne 0 ]; then
    # allocate the PVC
    echo "Creating webserver PVC (${WEBSVR_PVC_NAME})."
    ${KUBECTL} create -f ${CWD}/${WEBSVR_PVC_YAML_FILE}
else
    echo "The webserver PVC (${WEBSVR_PVC_NAME}) exists."
fi

# start the webserver
${KUBECTL} create -f ${WEBSVR_YAML_FILE}
