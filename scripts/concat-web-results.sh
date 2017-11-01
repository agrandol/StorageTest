#!/bin/sh
#
# Concatenate the results stored the /opt/pywebsvr/results directory for a specific test
#
# Filename: concat-web-results.sh
#
# set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
#set -x

TEST_RESULTS_TO_PROCESS="fio"
RESULTS_ROOT_DIR="/opt/pywebsvr/results"
OUTPUT_FILENAME="output.txt"

CWD=`pwd`
DATE_HOUR_MIN=`date "+%Y%m%d-%H%M"`
CONCAT_OUTPUT_FILE="${DATE_HOUR_MIN}-${OUTPUT_FILENAME}"

TOP_LEVEL_DIRS=$(find ${RESULTS_ROOT_DIR} -type d -name ${TEST_RESULTS_TO_PROCESS})
#find /opt/pywebsvr/results -type d -name "fio"

# for all directories with results
for topdir in ${TOP_LEVEL_DIRS}; do

    # find all result files
    RESULT_FILES=${topdir}/*.tgz

    # for all result files
    for f in ${RESULT_FILES}; do
        TEMP_DIR="${CWD}/temp-results-to-extract"
        echo "Extracting results from $f"
        mkdir ${TEMP_DIR}
        tar -xzf $f --directory ${TEMP_DIR}

        OUTPUT_FILE=$(find ${TEMP_DIR} -type f -name ${OUTPUT_FILENAME})
        cat ${OUTPUT_FILE} >> ${CWD}/${CONCAT_OUTPUT_FILE}
        rm -rf ${TEMP_DIR}
    done # end for all tgz files in dir
done # end for all directories with results
