#!/bin/sh
#
# Filename: run-iozone-job.sh
#
# Run the IOzone metric container as a job
#
#set -x

IOZONE_POD_NAME="iozone-job"
IOZONE_JOB_NAME=${IOZONE_POD_NAME}
PERSISTENT_STORAGE_NAME="penguin-ceph-appliance"
PERSISTENT_STORAGE_VERSION="1.0.1"

# IOzone parameters
FILE_SIZES='200g'        #'10m'  # for small tests
CACHE_SIZES='4 8 16 32'  # note: these are in k; the record size will be set to the same value
NUMBER_OF_THREADS='8'

#KUBECTL="kubectl" # for local minikube
KUBECTL="oc"      # for main system, recommended by OpenShift

if [ "${KUBECTL}" = "oc" ]
then
	# oc setup to assure running the correct project
	${KUBECTL} project meadowgate

	# refresh volume claim
	${KUBECTL} delete pvc iozone-pvc-ceph
	${KUBECTL} create -f iozone-pvc-ceph.yml
fi

# stop previous IOzone jobs
${KUBECTL} delete jobs ${IOZONE_POD_NAME}

# Useful variables
IOZONE_STARTUP_WAIT="60s"
IOZONE_CONTAINER_AND_VERSION="ranada/iozone:0.0.7"
LENGTH_OF_RUN="0 hour"    # minimum test duration, use Linux data notation
                          # that will add time to the time the test started
END_TIME=$(date -ud "+${LENGTH_OF_RUN}" "+%m%d%H%M")
#END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
CWD=${PWD}

# YAML files defining execution parameters of the container
IOZONE_JOB_YAML="${CWD}/${IOZONE_JOB_NAME}.yml"
IOZONE_JOB_YAML_TEMPLATE="${CWD}/${IOZONE_JOB_NAME}-template.yml"

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.50.100.5:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=
LOGSTASH_DATE=`date -u "+%Y.%m.%d"`
LOGSTASH_INDEX="logstash-iozone-${LOGSTASH_DATE}"
#LOGSTASH_INDEX="logstash-iozone-test1"

# Stay alive time, default in container is 5 minutes
STAY_ALIVE_SLEEP_TIME="5m"

# Create the YAML for the test job
cat "${IOZONE_JOB_YAML_TEMPLATE}" \
    | sed "s|__CONTAINER_AND_VERSION__|${IOZONE_CONTAINER_AND_VERSION}|g" \
    | sed "s|__TEST_END_TIME__|${END_TIME}|g" \
	| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
	| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
	| sed "s|__ELASTICSEARCH_PASSWORD__|${ELASTICSEARCH_PASSWORD}|g" \
	| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
	| sed "s|__LOGSTASH_INDEX__|${LOGSTASH_INDEX}|g" \
	| sed "s|__PERSISTENT_STORAGE_NAME__|${PERSISTENT_STORAGE_NAME}|g" \
	| sed "s|__PERSISTENT_STORAGE_VERSION__|${PERSISTENT_STORAGE_VERSION}|g" \
	| sed "s|__JOB_NAME__|${IOZONE_JOB_NAME}|g" \
	| sed "s|__FILE_SIZES__|${FILE_SIZES}|g" \
	| sed "s|__CACHE_SIZES__|${CACHE_SIZES}|g" \
	| sed "s|__NUMBER_OF_THREADS__|${NUMBER_OF_THREADS}|g" \
	| sed "##/d" \
	> ${IOZONE_JOB_YAML}

# Start the IOzone test
${KUBECTL} create -f ${IOZONE_JOB_YAML}
sleep ${IOZONE_STARTUP_WAIT}

IOZONE_POD=`${KUBECTL} get --no-headers=true pods -o wide | grep ${IOZONE_POD_NAME} | grep Running | awk '{print $1}'`

# Watch the IOzone log for results
if [ -n ${IOZONE_POD} ]
then
	${KUBECTL} logs ${IOZONE_POD} -f
else
	echo "There are no ${IOZONE_POD_NAME} pods running"
fi
