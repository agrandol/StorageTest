#!/bin/bash
#
# Run fio
#
#set -x
PERL="/usr/bin/perl"
PARSING_SCRIPT="parse-fio.pl"
PARSED_OUTPUT_FILE="output.txt"

# check environment variables, set to default values if not set
[ -n "${JOB_NAME}" ] || JOB_NAME="fio-job"
[ -n "${HOSTNAME}" ] || HOSTNAME=$(hostname)
[ -n "${DATA_DIR}" ] || DATA_DIR="/data"

# display the initial state of the file systems
df -hT

# create the output filename
DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
OUTPUT_FILE="${DATA_DIR}/${JOB_NAME}_${HOSTNAME}_${DATE_WITH_TIME}.out"

# run the test
echo "Starting fio job"
/usr/bin/fio /config/random-write.fio --output=${OUTPUT_FILE}
echo "Done with test."

# display the final state of the file systems
df -hT

# save the current directory
SAVED_CWD=`pwd`

# change to the results directory
cd ${DATA_DIR}
RESULT_FILES=`ls *.out`

# parse results
${PERL} ${HOME_DIR}/${PARSING_SCRIPT} ${RESULT_FILES} >> ${DATA_DIR}/${PARSED_OUTPUT_FILE}

# print results to the logs
cat ${RESULT_FILES}
cat ${DATA_DIR}/${PARSED_OUTPUT_FILE}

# remove test file and fio resutls
rm *.data
rm ${RESULT_FILES}

# return to the old directory
cd ${SAVED_CWD}



#COUNTER=0
#yourfilenames=`find ~/dev/meadowgate/rhlab/results/ -name *.out`
#for eachfile in $yourfilenames
#do
#   echo "Processing file $eachfile"
#   echo "{ \"create\" : { \"_index\" : \"fio5\", \"_type\" : \"fio\", \"_id\" : \"$COUNTER\" } }" >> results.json
#   ./parse-fio.pl $eachfile >> results.json
#   COUNTER=$[$COUNTER +1]
#done

# remove the test file
#rm -rf ${OUTPUT_FILE}

# old test runs
#fio /config/trivial.fio
#fio /config/random-write.fio
