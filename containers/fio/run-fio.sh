#!/bin/bash
#
# Run fio
#
#set -x
PERL="/usr/bin/perl"
PARSING_SCRIPT="parse-fio.pl"
PARSED_OUTPUT_FILE="output.txt"
PARSING_SCRIPT_CSV="parse-fio-save-csv.pl"
PARSED_CSV_FILE="output.csv"
FIO_EXE="/usr/bin/fio"

# check environment variables, set to default values if not set
[ -n "${JOB_NAME}" ] || JOB_NAME="fio-job"
[ -n "${HOSTNAME}" ] || HOSTNAME=$(hostname)
[ -n "${DATA_DIR}" ] || DATA_DIR="/data"

# display the initial state of the file systems
df -hT

# run the test
echo "Starting fio test"

# for all config files
CONFIG_FILES=/config/*.fio
for f in ${CONFIG_FILES}
do
    echo "Running ${f}"
    DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
    OUT_FILENAME=$(echo $f | sed "s|/config/||g" | sed "s|.fio||g")
    OUTPUT_FILE="${DATA_DIR}/${JOB_NAME}_${HOSTNAME}_${DATE_WITH_TIME}-${OUT_FILENAME}.out"
    ${FIO_EXE} ${f} --output=${OUTPUT_FILE}  
done

echo "fio test complete."

# display the final state of the file systems
df -hT

# save the current directory
SAVED_CWD=`pwd`

# change to the results directory
cd ${DATA_DIR}
RESULT_FILES=`ls *.out`

# parse results
${PERL} ${HOME_DIR}/${PARSING_SCRIPT} ${RESULT_FILES} >> ${DATA_DIR}/${PARSED_OUTPUT_FILE}
${PERL} ${HOME_DIR}/${PARSING_SCRIPT_CSV} ${RESULT_FILES} >> ${DATA_DIR}/${PARSED_CSV_FILE}

# print results to the logs
#cat ${RESULT_FILES}
cat ${DATA_DIR}/${PARSED_OUTPUT_FILE}
cat ${DATA_DIR}/${PARSED_CSV_FILE}

#----------------------------------------------------------------------
# package results and send to web server

#RESULTS_WEBSERVER="10.50.100.5"  # should be set in environment

# if the results webserver is defined
if [ -n "${RESULTS_WEBSERVER}" ]; then
	JOB_NAME="fio"
	WWW_TARGET_HOST="http://${RESULTS_WEBSERVER}:8080"

	DATE_HOUR_MIN_SEC=`date "+%Y%m%d-%H%M%S"`
	RESULTS_PACKAGE_FILENAME="${HOSTNAME}-${DATE_HOUR_MIN_SEC}.tgz"
	RESULTS_PACKAGE_FULL_FILEPATH="${TEST_DIR}/${RESULTS_PACKAGE_FILENAME}"

	# package all test files in the /data directory except the test files
	tar -cvzf ${RESULTS_PACKAGE_FULL_FILEPATH} --exclude=${DATA_DIR}/*.data ${DATA_DIR}/*.*
	echo "Results written to: ${RESULTS_PACKAGE_FULL_FILEPATH}"
	
	# try accessing the results web server
	${PING_CMD} ${PING_COUNT_ARG} $(echo ${RESULTS_WEBSERVER} | cut -d: -f1)

	# if access to the results web server was successful
	if [ $? -eq 0 ]; then
		# send results via curl
		curl -X POST -H "Content-Type: application/x-tar" --data-binary @${RESULTS_PACKAGE_FULL_FILEPATH}  ${WWW_TARGET_HOST}/${JOB_NAME}/${RESULTS_PACKAGE_FILENAME}
	fi
fi

#----------------------------------------------------------------------
# remove test file and fio resutls
rm *.data
rm ${RESULT_FILES}

# return to the old directory
cd ${SAVED_CWD}
