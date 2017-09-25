#!/bin/sh
#
# Filename: run-iozone-job.sh
#
# Run the IOzone metric container as a job
#
#set -x

IOZONE_POD_NAME="iozone-job"


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
LENGTH_OF_RUN="0 hour"    # minimum test duration, use Linux data notation
                          # that will add time to the time the test started
END_TIME=$(date -ud "+${LENGTH_OF_RUN}" "+%m%d%H%M")
#END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
CWD=${PWD}

# YAML files defining execution parameters of the container
IOZONE_JOB_YAML="${CWD}/iozone-job.yml"
IOZONE_JOB_YAML_TEMPLATE="${CWD}/iozone-job-template.yml"

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.0.148.1:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=

# Stay alive time, default in container is 5 minutes
STAY_ALIVE_SLEEP_TIME="1m"

# Create the YAML for the test job
cat "${IOZONE_JOB_YAML_TEMPLATE}" \
    | sed "s|__TEST_END_TIME__|${END_TIME}|g" \
	| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
	| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
	| sed "s|__ELASTICSEARCH_PASSWORD|${ELASTICSEARCH_PASSWORD}|g" \
	| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
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
