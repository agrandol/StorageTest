#!/bin/bash
#
# Configure IOzone container to run tests
#
# Filename: configure-iozone.sh
#
#set -x

# if stay alive time is not set, set it to 5 minutes
[ -n "${STAY_ALIVE_SLEEP_TIME}" ] || STAY_ALIVE_SLEEP_TIME="5m"

# current working directory
CWD=`pwd`

# variables used to test elasticsearch host access
PING_CMD="ping"
PING_COUNT_ARG="-c 1"

# logstash variables
LOGSTASH_RPM="logstash.rpm"
LOGSTASH_APP="/usr/share/logstash/bin/logstash"
LOGSTASH_SETTINGS="/etc/logstash"
LOGSTASH_CONF="logstash.conf"

# set JAVA_HOME, needed for Logstash
#export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

# if the Elasticsearch host is defined
if [ -n "${ELASTICSEARCH_HOST}" ]
then
	# determine if logstash is already running
	RETVAL=`pgrep -f logstash`
	
	# if a logstash instance is not running
	if [ $? -ne 0 ]
	then
		# set the logstash host in the configuration file
		LOGSTASH_CONFIG_FILE="${CWD}/logstash.conf"
		LOGSTASH_CONFIG_FILE_TEMPLATE="${CWD}/logstash.conf-template"
		
		# create the logstash.conf file
		cat "${LOGSTASH_CONFIG_FILE_TEMPLATE}" \
		    | sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
			| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
			| sed "s|__ELASTICSEARCH_PASSWORD__|${ELASTICSEARCH_PASSWORD}|g" \
			| sed "##/d" \
			> ${LOGSTASH_CONFIG_FILE}
			
		# remove the elasticsearch user and password lines if the information is not provided
		if [ -z ${ELASTICSEARCH_USER} ]
		then
			sed '/user =>/d' ${LOGSTASH_CONFIG_FILE} > ${LOGSTASH_CONFIG_FILE}1
			cat ${LOGSTASH_CONFIG_FILE}1 > ${LOGSTASH_CONFIG_FILE}
		fi
	
		if [ -z ${ELASTICSEARCH_PASSWORD} ]
		then
			sed '/password =>/d' ${LOGSTASH_CONFIG_FILE} > ${LOGSTASH_CONFIG_FILE}1
			cat ${LOGSTASH_CONFIG_FILE}1 > ${LOGSTASH_CONFIG_FILE}
		fi
	
		# try accessing the elasticsearch host
		${PING_CMD} ${PING_COUNT_ARG} $(echo ${ELASTICSEARCH_HOST} | cut -d: -f1)
		
		# if access to the elasticsearch host was successful
		if [ $? -eq 0 ]
		then
			# install logstash
			rpm -Uvh ${LOGSTASH_RPM}

			# start logstash
			echo "Starting logstash"
			${LOGSTASH_APP} --path.settings ${LOGSTASH_SETTINGS} -f ${LOGSTASH_CONF} &
		fi
	fi
fi

#----------------------------------------------------------------------
# perform test set-up
h=$(hostname)
ip=$(hostname -i)

#----------------------------------------------------------------------
# if the test time is not set
if [ -z "${TEST_END_TIME}" ]
then
	# set the test end time to current time, test will run one time
	TEST_END_TIME=`date -u +%m%d%H%M`
	echo "Setting test end time to ${TEST_END_TIME}"
fi

#----------------------------------------------------------------------
# if a mount device and an IOzone test directory has been set
##### 
# Test this block with a real device, change or delete as needed
#####
#if [ -n "${MOUNT_DEVICE}" ] && [ -n "${IOZONE_TEST_DIR}" ]
#then
#	# create the local directory for the mount
#	mkdir -p ${IOZONE_TEST_DIR}
#	
#	# mount the directory
#	mount ${MOUNT_DEVICE} ${IOZONE_TEST_DIR}
#fi

IOZONE_TEST_DIR="/data";

#----------------------------------------------------------------------
# build the IOzone benchmark

# save the working directory location
WORKING_PWD=${CWD}

# change to the benchmark directory and build the benchmark
BENCHMARK_PWD="${CWD}/iozone3_469/src/current"

cd ${BENCHMARK_PWD}
MKTYPE=linux
PROC=$(uname -p)
[ PROC = x86_64 ] && MKTYPE='linux-ia64'
[ PROC = ppc64 ] && MKTYPE='linux-powerpc64'
make clean
make ${MKTYPE}

# return to the working directory
cd ${WORKING_PWD}

#----------------------------------------------------------------------
# start the IOzone test
CONTINUE_TEST="TRUE"
while [ "${CONTINUE_TEST}" = "TRUE" ]
do
	. ${CWD}/run-iozone.sh
	
	CURRENT_TIME=`date -u +%m%d%H%M`
	if [ ${CURRENT_TIME} -gt ${TEST_END_TIME} ]
	then
		date; echo "Stopping run"
		CONTINUE_TEST="FALSE"
	fi
done # while loop

#----------------------------------------------------------------------
# package results and send to web server
RESULTS_PACKAGE_FILENAME="${IOZONE_TEST_DIR}/${h}-iozone.tar.gz"
tar -cvzf ${RESULTS_PACKAGE_FILENAME} --exclude='/data/output.txt' /data/*.txt
echo "Results written to: ${RESULTS_PACKAGE_FILENAME}"

#----------------------------------------------------------------------
# keep the script running so the container has time to write results to logstash
echo "Writing results (waiting ${STAY_ALIVE_SLEEP_TIME})"
sleep ${STAY_ALIVE_SLEEP_TIME}

#----------------------------------------------------------------------
# keep the script running so the container remains running
#while true
#do
#	echo "Press {CTRL+C} to stop."
#	sleep ${STAY_ALIVE_SLEEP_TIME}
#done
