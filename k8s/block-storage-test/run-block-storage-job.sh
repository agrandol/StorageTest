#!/bin/sh
#
# Filename: run-block-storage-job.sh
#
# Run the block storage test container as a job
#
#set -x

# File sizes that can be run
FILE_SIZES='102400 1048576 1073741824 10737418240 1099511627776' #  100KB 1MB 1GB 10GB 1TB
FILE_SIZES='102400 1048576 1073741824 10737418240' #  100KB 1MB 1GB 10GB
FILE_SIZES='102400 1048576 1073741824' #  100KB 1MB 1GB
#FILE_SIZES='102400 1048576' #  100KB 1MB

FILE_SIZES='1048576 1073741824' #  1MB 1GB

# Useful variables
BLOCK_STORAGE_STARTUP_WAIT="30s"
LENGTH_OF_RUN="0 hour"    # minimum test duration, use Linux data notation
                          # that will add time to the time the test started
#END_TIME=$(date -ud "+${LENGTH_OF_RUN}" "+%m%d%H%M")
END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
BLOCK_STORAGE_POD_NAME="block-storage-job"
CWD=${PWD}

# YAML files defining execution parameters of the container
BLOCK_STORAGE_JOB_YAML="${CWD}/block-storage-job.yml"
BLOCK_STORAGE_JOB_YAML_TEMPLATE="${CWD}/block-storage-job-template.yml"

# Storage mount point
BLOCK_STORAGE_TEST_DIR=""
MOUNT_DEVICE=""

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.0.148.1:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=

# Stay alive time, default in container is 5 minutes
STAY_ALIVE_SLEEP_TIME="1m"

# Create the YAML for the test job
cat "${BLOCK_STORAGE_JOB_YAML_TEMPLATE}" \
    | sed "s|__FILE_SIZES__|${FILE_SIZES}|g" \
    | sed "s|__TEST_END_TIME__|${END_TIME}|g" \
	| sed "s|__BLOCK_STORAGE_TEST_DIR__|${BLOCK_STORAGE_TEST_DIR}|g" \
	| sed "s|__MOUNT_DEVICE__|${MOUNT_DEVICE}|g" \
	| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
	| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
	| sed "s|__ELASTICSEARCH_PASSWORD|${ELASTICSEARCH_PASSWORD}|g" \
	| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
	| sed "##/d" \
	> ${BLOCK_STORAGE_JOB_YAML}

# Start the IOzone test
kubectl create -f ${BLOCK_STORAGE_JOB_YAML}
sleep ${BLOCK_STORAGE_STARTUP_WAIT}

BLOCK_STORAGE_POD=`kubectl get --no-headers=true pods -o wide | grep ${BLOCK_STORAGE_POD_NAME} | grep Running | awk '{print $1}'`

# Watch the block storage log for results
kubectl logs ${BLOCK_STORAGE_POD} -f
