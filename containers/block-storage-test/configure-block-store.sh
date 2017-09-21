#!/bin/bash
#
# Configure the Block Storage container to run tests
#
# Filename: configure-block-store.sh
#
#set -x

# if stay alive time is not set, set it to 5 minutes
[ -n "${STAY_ALIVE_SLEEP_TIME}" ] || STAY_ALIVE_SLEEP_TIME="5m"

# set the test environment
source ./set-env.sh

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

# configure the test network (artifact from previous executions, sets variables)
source ${TEST_HOME}/SETUP.container

# change permissions of file test script
chmod a+x ${TEST_HOME}/BinaryGen.py

#----------------------------------------------------------------------
# if the test time is not set
if [ -z "${TEST_END_TIME}" ]
then
	# set the test end time to current time, test will run one time
	TEST_END_TIME=`date -u +%m%d%H%M`
	echo "Setting test end time to ${TEST_END_TIME}"
fi

#----------------------------------------------------------------------
# if a mount device and a block storage directory has been set
##### 
# Test this block with a real device, change or delete as needed
#####
#if [ -n "${MOUNT_DEVICE}" ] && [ -n "${BLOCK_STORAGE_TEST_DIR}" ]
#then
#	# create the local directory for the mount
#	mkdir -p ${BLOCK_STORAGE_TEST_DIR}
#	
#	# mount the directory
#	mount ${MOUNT_DEVICE} ${BLOCK_STORAGE_TEST_DIR}
#fi

#----------------------------------------------------------------------
# start the test
TEST_START_TIME=`date`
echo "Start block storage test: ${TEST_END_TIME}"

#CONTINUOUS_OUTPUT_FILE="${CWD}/output.txt"
CONTINUOUS_OUTPUT_FILE="${DATA_DIR}/output.txt"

CONTINUE_TEST="TRUE"
while [ "${CONTINUE_TEST}" = "TRUE" ]
do
	# create a file to store individual results
	TEST_START_TIME=`date "+%Y%m%d-%H%M%S"`
	#INDIVIDUAL_OUTPUT_FILE="${CWD}/results/${h}-${TEST_START_TIME}.txt"
	INDIVIDUAL_OUTPUT_FILE="${DATA_DIR}/${h}-${TEST_START_TIME}.txt"
	
	# run the test	
	. ${CWD}/run-block-store.sh > ${INDIVIDUAL_OUTPUT_FILE}
	
	# update the continuous output file for logstash consumption
	cat ${INDIVIDUAL_OUTPUT_FILE} >> ${CONTINUOUS_OUTPUT_FILE}
	
	# add a new line to the continuous output file to assist logstash
	echo "" >> ${CONTINUOUS_OUTPUT_FILE}
	
	# display the continuous output file to user and logs
	cat ${CONTINUOUS_OUTPUT_FILE}
	echo ""
	
	CURRENT_TIME=`date -u +%m%d%H%M`
	if [ ${CURRENT_TIME} -gt ${TEST_END_TIME} ]
	then
		date; echo "Stopping run"
		CONTINUE_TEST="FALSE"
	fi
done # while loop

#----------------------------------------------------------------------
# keep the script running so the container has time to write results to logstash
echo "Writing results"
sleep ${STAY_ALIVE_SLEEP_TIME}

#----------------------------------------------------------------------
# keep the script running so the container remains running
#while true
#do
#	echo "Press {CTRL+C} to stop."
#	sleep ${STAY_ALIVE_SLEEP_TIME}
#done
