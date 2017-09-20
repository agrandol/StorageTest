#!/bin/sh
#
# Filename: run-iozone-job.sh
#
# Run the IOzone metric container as a job
#
#set -x

# Useful variables
IOZONE_STARTUP_WAIT="30s"
LENGTH_OF_RUN="0 hour"    # minimum test duration, use Linux data notation
                          # that will add time to the time the test started
#END_TIME=$(date -ud "+${LENGTH_OF_RUN}" "+%m%d%H%M")
END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
IOZONE_POD_NAME="iozone-job"
CWD=${PWD}

# YAML files defining execution parameters of the container
IOZONE_JOB_YAML="${CWD}/iozone-job.yml"
IOZONE_JOB_YAML_TEMPLATE="${CWD}/iozone-job-template.yml"

# Storage mount point
IOZONE_TEST_DIR=""
MOUNT_DEVICE=""

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.0.148.1:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=

# Stay alive time, default in container is 5 minutes
STAY_ALIVE_SLEEP_TIME="1m"

# Create the YAML for the test job
cat "${IOZONE_JOB_YAML_TEMPLATE}" \
    | sed "s|__TEST_END_TIME__|${END_TIME}|g" \
	| sed "s|__IOZONE_TEST_DIR__|${IOZONE_TEST_DIR}|g" \
	| sed "s|__MOUNT_DEVICE__|${MOUNT_DEVICE}|g" \
	| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
	| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
	| sed "s|__ELASTICSEARCH_PASSWORD|${ELASTICSEARCH_PASSWORD}|g" \
	| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
	| sed "##/d" \
	> ${IOZONE_JOB_YAML}

# Start the IOzone test
kubectl create -f ${IOZONE_JOB_YAML}
sleep ${IOZONE_STARTUP_WAIT}

IOZONE_POD=`kubectl get --no-headers=true pods -o wide | grep ${IOZONE_POD_NAME} | grep Running | awk '{print $1}'`

# Watch the IOzone log for results
kubectl logs ${IOZONE_POD} -f
