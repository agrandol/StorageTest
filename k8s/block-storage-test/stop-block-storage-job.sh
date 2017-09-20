#!/bin/sh
#
# Filename: stop-block-storage-job.sh
#
# Stop block storage jobs
#
# NOTE: If you are obtaining the results from the log or files, be sure to
#       gather the results prior to stopping the jobs.
#
#set -x

# Useful variables
JOB_STEM="block-storage-job"

# Delete the jobs
kubectl delete job $( \
        kubectl get --no-headers jobs | \
		grep ${JOB_STEM} | \
		awk '{print $1}' | tr '\n' ' ')
