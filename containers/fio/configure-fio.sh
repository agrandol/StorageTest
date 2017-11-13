#!/bin/bash
#
# Configure fio container to run tests
#
# Filename: configure-fio.sh
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
LOGSTASH_RPM="logstash-5.6.2.rpm"
LOGSTASH_APP="/usr/share/logstash/bin/logstash"
LOGSTASH_SETTINGS="/etc/logstash"
LOGSTASH_CONF="logstash.conf"

# set JAVA_HOME, needed for Logstash
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

# if the Elasticsearch host is defined
if [ -n "${ELASTICSEARCH_HOST}" ]; then
	# determine if logstash is already running
	RETVAL=`pgrep -f logstash`
	
	# if a logstash instance is not running
	if [ $? -ne 0 ]; then
		# set the logstash host in the configuration file
		LOGSTASH_CONFIG_FILE="${CWD}/logstash.conf"
		LOGSTASH_CONFIG_FILE_TEMPLATE="${CWD}/logstash.conf-template"
		
		# create the logstash.conf file
		cat "${LOGSTASH_CONFIG_FILE_TEMPLATE}" \
			| sed "s|__ELASTICSEARCH_HOST__|${ELASTICSEARCH_HOST}|g" \
			| sed "s|__ELASTICSEARCH_USER__|${ELASTICSEARCH_USER}|g" \
			| sed "s|__ELASTICSEARCH_PASSWORD__|${ELASTICSEARCH_PASSWORD}|g" \
			| sed "s|__LOGSTASH_INDEX__|${LOGSTASH_INDEX}|g" \
			| sed "##/d" \
			> ${LOGSTASH_CONFIG_FILE}
			
		# remove the elasticsearch user and password lines if the information is not provided
		if [ -z ${ELASTICSEARCH_USER} ]; then
			sed '/user =>/d' ${LOGSTASH_CONFIG_FILE} > ${LOGSTASH_CONFIG_FILE}1
			cat ${LOGSTASH_CONFIG_FILE}1 > ${LOGSTASH_CONFIG_FILE}
		fi
		if [ -z ${ELASTICSEARCH_PASSWORD} ]; then
			sed '/password =>/d' ${LOGSTASH_CONFIG_FILE} > ${LOGSTASH_CONFIG_FILE}1
			cat ${LOGSTASH_CONFIG_FILE}1 > ${LOGSTASH_CONFIG_FILE}
		fi
		if [ -z ${LOGSTASH_INDEX} ]; then
			sed '/index =>/d' ${LOGSTASH_CONFIG_FILE} > ${LOGSTASH_CONFIG_FILE}1
			cat ${LOGSTASH_CONFIG_FILE}1 > ${LOGSTASH_CONFIG_FILE}
		fi
	
		# try accessing the elasticsearch host
		${PING_CMD} ${PING_COUNT_ARG} $(echo ${ELASTICSEARCH_HOST} | cut -d: -f1)
		
		# if access to the elasticsearch host was successful
		if [ $? -eq 0 ]; then
			# start logstash
			echo "Starting logstash"
			${LOGSTASH_APP} --path.settings ${LOGSTASH_SETTINGS} -f ${LOGSTASH_CONF} &
		fi
	fi
fi

#----------------------------------------------------------------------
# perform test set-up
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i)

#----------------------------------------------------------------------
# if the test time is not set
if [ -z "${TEST_END_TIME}" ]; then
	# set the test end time to current time, test will run one time
	TEST_END_TIME=`date -u +%m%d%H%M`
	echo "Setting test end time to ${TEST_END_TIME}"
fi

#----------------------------------------------------------------------
# set the results directory

TEST_DIR="/data";

#----------------------------------------------------------------------
# start the  test
CONTINUE_TEST="TRUE"
SECONDS=0
echo "Starting fio test"
while [ "${CONTINUE_TEST}" = "TRUE" ]; do
	. ${CWD}/run-fio.sh
	
	CURRENT_TIME=`date -u +%m%d%H%M`
	if [ ${CURRENT_TIME} -gt ${TEST_END_TIME} ]
	then
		date; echo "Stopping run"
		CONTINUE_TEST="FALSE"
	fi
done # while loop
DURATION=$SECONDS
echo "Test duration: $(($DURATION / 60)) minutes, $((DURATION % 60)) seconds"

#----------------------------------------------------------------------
# keep the script running so the container has time to write results to logstash
echo "Writing results (waiting ${STAY_ALIVE_SLEEP_TIME})"
sleep ${STAY_ALIVE_SLEEP_TIME}
