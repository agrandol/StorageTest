#!/bin/sh
#
# Filename: run-iozone-job.sh
#
# Run the IOzone metric container as a job
#
#set -x

usage() {
	echo "Start one or many jobs based on optional command line arguments supplied"
	echo "usage: $0 [OPTIONS]"
	echo "  -c, --completions <COMPLETIONS>  the number of completions per job."
	echo "  -d, --duration <DURATION>>       the minimum job duration, use Linux date notation."
	echo "                                   The value entered will be added to the time started."
	echo "                                   Examples include \"0 hour\" to run once, \"5 hour\" will"
	echo "                                   run for 5 hours."
	echo "  -j, --jobs <JOBS>                the number of jobs to run."	
	echo "  -n, --namespace <NAMESPACE>      the namespace that should be used for the run."	
	echo "  -s, --sleep <STAY_ALIVE_TIME>    the amount of time to sleep when the job completes to " 
	echo "                                   allow results collection and export."
	echo "                                   Use standard Linux sleep notation. Example: \"5m\" to"
	echo "                                   sleep for 5 minutes, which is the default."
	echo "  -h, --help                       display this help message."
	echo "  --cache-sizes <CACHE_SIZES>      the cache sizes IOzone will use, these are in k."
	echo "                                   Note: the record size will be set to the same value."
	echo "                                   This can be an array, enclose in single quotes. "
	echo "                                   e.g. --cache-sizes '4 8 16 32'."
	echo "  --file-sizes <FILE_SIZES>        the file sizes IOzone will use when running. The values"
	echo "                                   must include the unit (k, m, g for KB, MB, and GB respectively."
	echo "                                   This can be an array, enclose in single quotes. "
	echo "                                   e.g. --file-sizes '40k 100m 10g'."
	echo "  --num-threads <NUM_THREADS>      the number of threads IOzone will use, can be an array,"
	echo "                                   enclose in single quotes. e.g. --threads '4 8'."
}

# Execution parameters and settings
K8S_NAMESPACE="meadowgate"
NUMBER_OF_JOBS="1"
COMPLETIONS="1"
IOZONE_POD_NAME="iozone-job"
IOZONE_JOB_NAME=${IOZONE_POD_NAME}
PERSISTENT_STORAGE_NAME="penguin-ceph-appliance"
PERSISTENT_STORAGE_VERSION="1.0.1"
IOZONE_STARTUP_WAIT="60s"
JOB_START_WAIT="5s"
IOZONE_CONTAINER_AND_VERSION="ranada/iozone:0.0.7"
JOB_DURATION="0 hour"   # minimum test duration, use Linux data notation
                        # that will add time to the time the test started
STAY_ALIVE_SLEEP_TIME="5m"  # Stay alive time, default in container is 5 minutes

# IOzone parameters
FILE_SIZES='10m'        #'10m'  # for small tests, assume one file size will be used for now
CACHE_SIZES='4 8 16 32'  # note: these are in k; the record size will be set to the same value
NUMBER_OF_THREADS='8'

# Process command line arguments
while [ "$1" != "" ]; do
	case $1 in
		-c | --completions )
			shift
			COMPLETIONS=$1
			;;
		-d | --duration )
			shift
			JOB_DURATION=$1
			;;
		-j | --jobs )
			shift
			NUMBER_OF_JOBS=$1
			;;
		-n | --namespace )
			shift
			K8S_NAMESPACE=$1
			;;
		-s | --sleep )
			shift
			STAY_ALIVE_SLEEP_TIME=$1
			;;
		--cache-sizes )
			shift
			CACHE_SIZES=$1
			;;
		--file-sizes )
			shift
			FILE_SIZES=$1
			;;
		--threads )
			shift
			NUMBER_OF_THREADS=$1
			;;
		-h | --help )
			usage
			exit 1
	esac
	shift
done

# k8s commands
KUBECTL="kubectl" # for local minikube on Mac
#KUBECTL="oc"      # for main system, recommended by OpenShift

if [ "${KUBECTL}" = "oc" ]
then
	# oc setup to assure running the correct project
	${KUBECTL} project ${K8S_NAMESPACE}
	END_TIME=$(date -ud "+${JOB_DURATION}" "+%m%d%H%M")

else
	# running local minikube on Mac
	${KUBECTL} project default
	END_TIME=$(date -u  "+%m%d%H%M")   # when running on MacOS, -d does not work
fi

# stop previous IOzone jobs
# now done in loop below
#${KUBECTL} delete jobs ${IOZONE_POD_NAME}

# Useful variables
CWD=${PWD}

# Template YAML files
IOZONE_JOB_YAML_TEMPLATE="${CWD}/${IOZONE_JOB_NAME}-template.yml"
PVC_YAML_TEMPLATE="${CWD}/iozone-pvc-ceph-template.yml"

# Logstash configuration parameters, Elasticsearch location
ELASTICSEARCH_HOST="10.50.100.5:9200"
ELASTICSEARCH_USER=
ELASTICSEARCH_PASSWORD=
LOGSTASH_DATE=`date -u "+%Y.%m.%d"`
LOGSTASH_INDEX="logstash-iozone-${LOGSTASH_DATE}"
#LOGSTASH_INDEX="logstash-iozone-test1"

# for all jobs to run
for i in `seq 1 ${NUMBER_OF_JOBS}`; do
	JOB_TO_RUN="${IOZONE_JOB_NAME}-$i"
	echo "$i: Job: ${JOB_TO_RUN}; job will run ${COMPLETIONS} time(s)"

	# delete previous IOzone job with same name
	${KUBECTL} delete jobs ${JOB_TO_RUN}

	# update the PVC allocation YAML
	PVC_NAME="iozone-pvc-ceph-$i"
	PVC_YAML="${CWD}/iozone-pvc-ceph-$i.yml"

	# find the PVC size
	ALLOCATION_FACTOR="2"
	TEST_FILE_SIZE=$(echo ${FILE_SIZES} | sed 's/[^0-9]*//g')
	PVC_SIZE=$((${TEST_FILE_SIZE} * ${ALLOCATION_FACTOR} * ${NUMBER_OF_THREADS}))
	FILE_SIZE_UNITS=$(echo ${FILE_SIZES} | sed 's/[^a-zA-Z]*//g')
	PVC_UNITS="$(echo ${FILE_SIZE_UNITS} | tr '[:lower:]' '[:upper:]')i"
	PVC_SIZE="${PVC_SIZE}${PVC_UNITS}"

	# create the YAML for the PVC
	cat "${PVC_YAML_TEMPLATE}" \
		| sed "s|__PVC_NAME__|${PVC_NAME}|g" \
		| sed "s|__PVC_SIZE__|${PVC_SIZE}|g" \
		| sed "##/d" \
		> ${PVC_YAML}

	# delete previous claim and submit new claim
	#echo ${PVC_NAME}
	${KUBECTL} delete pvc ${PVC_NAME}
	${KUBECTL} create -f ${PVC_YAML}
	
	# the YAML file that will be used to create the job
	IOZONE_JOB_YAML="${CWD}/${JOB_TO_RUN}.yml"

	# Create the YAML for the test job
	cat "${IOZONE_JOB_YAML_TEMPLATE}" \
		| sed "s|__COMPLETIONS__|${COMPLETIONS}|g" \
		| sed "s|__NAMESPACE__|${K8S_NAMESPACE}|g" \
		| sed "s|__CONTAINER_AND_VERSION__|${IOZONE_CONTAINER_AND_VERSION}|g" \
		| sed "s|__TEST_END_TIME__|${END_TIME}|g" \
		| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
		| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
		| sed "s|__ELASTICSEARCH_PASSWORD__|${ELASTICSEARCH_PASSWORD}|g" \
		| sed "s|__STAY_ALIVE_SLEEP_TIME__|${STAY_ALIVE_SLEEP_TIME}|g" \
		| sed "s|__LOGSTASH_INDEX__|${LOGSTASH_INDEX}|g" \
		| sed "s|__PERSISTENT_STORAGE_NAME__|${PERSISTENT_STORAGE_NAME}|g" \
		| sed "s|__PERSISTENT_STORAGE_VERSION__|${PERSISTENT_STORAGE_VERSION}|g" \
		| sed "s|__FILE_SIZES__|${FILE_SIZES}|g" \
		| sed "s|__CACHE_SIZES__|${CACHE_SIZES}|g" \
		| sed "s|__NUMBER_OF_THREADS__|${NUMBER_OF_THREADS}|g" \
		| sed "s|__JOB_NAME__|${JOB_TO_RUN}|g" \
		| sed "s|__PVC_NAME__|${PVC_NAME}|g" \
		| sed "##/d" \
		> ${IOZONE_JOB_YAML}

	# Start the IOzone test
	${KUBECTL} create -f ${IOZONE_JOB_YAML}

	# allow the job to start before attempting another job start
	sleep ${JOB_START_WAIT}
done  # end of job creation loop

# wait for all jobs to start
sleep ${IOZONE_STARTUP_WAIT}

# rethink how to view the running pods as part of this script
# for now, just exit
exit


# find running pods
IOZONE_POD=`${KUBECTL} get --no-headers=true pods -o wide | grep ${IOZONE_POD_NAME} | grep Running | awk '{print $1}'`

# Watch the IOzone log for results
if [ -n ${IOZONE_POD} ]
then
	${KUBECTL} logs ${IOZONE_POD} -f
else
	echo "There are no ${IOZONE_POD_NAME} pods running"
fi
