#!/bin/sh
#
# Filename: run-block-storage-job.sh
#
# Run the block storage test container as a job
#
#set -x

BLOCK_STORAGE_POD_NAME="block-storage-job"

#KUBECTL="/usr/bin/kubectl" # for local minikube
KUBECTL="/usr/bin/oc"      # for main system, recommended by OpenShift

if [ "${KUBECTL}" = "/usr/bin/oc" ]
then
	# oc setup to assure running the correct project
	${KUBECTL} project meadowgate

	# refresh volume claim
#	${KUBECTL} delete pvc block-storage-pvc-ceph
#	${KUBECTL} create -f block-storage-pvc-ceph.yml	
fi

# stop previous block-storage jobs
${KUBECTL} delete jobs ${BLOCK_STORAGE_POD_NAME}

# File sizes that can be run
FILE_SIZES='102400 1048576 1073741824 10737418240 1099511627776' #  100KB 1MB 1GB 10GB 1TB
FILE_SIZES='102400 1048576 1073741824 10737418240' #  100KB 1MB 1GB 10GB
#FILE_SIZES='102400 1048576 1073741824' #  100KB 1MB 1GB
#FILE_SIZES='102400 1048576' #  100KB 1MB

# a good initial test setting
#FILE_SIZES='1048576 1073741824' #  1MB 1GB

# Useful variables
BLOCK_STORAGE_STARTUP_WAIT="60s"
BLOCK_STORAGE_CONTAINER_AND_VERSION="ranada/block-storage-test:0.0.4"
LENGTH_OF_RUN="1 hour"    # minimum test duration, use Linux data notation
                          # that will add time to the time the test started
END_TIME=$(date -ud "+${LENGTH_OF_RUN}" "+%m%d%H%M")
#END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
CWD=${PWD}

# YAML files defining execution parameters of the container
BLOCK_STORAGE_JOB_YAML="${CWD}/block-storage-job.yml"
BLOCK_STORAGE_JOB_YAML_TEMPLATE="${CWD}/block-storage-job-template.yml"

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.50.100.5:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=

# Stay alive time, default in container is 5 minutes
STAY_ALIVE_SLEEP_TIME="10m"

# Create the YAML for the test job
cat "${BLOCK_STORAGE_JOB_YAML_TEMPLATE}" \
    | sed "s|__CONTAINER_AND_VERSION__|${BLOCK_STORAGE_CONTAINER_AND_VERSION}|g" \
	| sed "s|__FILE_SIZES__|${FILE_SIZES}|g" \
	| sed "s|__TEST_END_TIME__|${END_TIME}|g" \
	| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
	| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
	| sed "s|__ELASTICSEARCH_PASSWORD|${ELASTICSEARCH_PASSWORD}|g" \
	| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
	| sed "##/d" \
	> ${BLOCK_STORAGE_JOB_YAML}

# Start the block Storage test
${KUBECTL} create -f ${BLOCK_STORAGE_JOB_YAML}
sleep ${BLOCK_STORAGE_STARTUP_WAIT}

BLOCK_STORAGE_POD=`${KUBECTL} get --no-headers=true pods -o wide | grep ${BLOCK_STORAGE_POD_NAME} | grep Running | awk '{print $1}'`

# Watch the block storage log for results
if [ -n ${BLOCK_STORAGE_POD} ]
then
	${KUBECTL} logs ${BLOCK_STORAGE_POD} -f
else
	echo "There are no ${BLOCK_STORAGE_POD_NAME} pods running"
fi
