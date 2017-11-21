#!/bin/bash
#
# Filename: move-results.sh
#
# Move results to the jump box, run on the server where results reside
#
# vim: tabstop=4: noexpandtab
#set -x

# commands
PING_CMD="ping"
PING_COUNT_ARG="-c 1"

# sleep delay time to allow transfer
SLEEP_DELAY="10s"

# the server to send results
RESULTS_WEBSERVER="10.50.100.5"
WWW_TARGET_HOST="http://${RESULTS_WEBSERVER}:8080"

# the directory on the remote server to store results
REMOTE_DIR="fio-new"

# the directory on the server where results reside
LOCAL_RESULTS_DIR="/results/fio"

# the list of files to transfer
TAR_FILES_TO_TRANSFER=`ls ${LOCAL_RESULTS_DIR}/*.tgz`

# if the webserver is set
if [ -n "${RESULTS_WEBSERVER}" ]; then

	# try accessing the results web server
	${PING_CMD} ${PING_COUNT_ARG} $(echo ${RESULTS_WEBSERVER} | cut -d: -f1)

	# if access to the results web server was successful
	if [ $? -eq 0 ]; then	
    	# for all results files found
		for tarFile in ${TAR_FILES_TO_TRANSFER}; do
			# extract the filename from the full file path
			TAR_RESULTS_FILENAME=$(echo ${tarFile} | sed "s|${LOCAL_RESULTS_DIR}/||g")

			# send results via curl
			curl -X POST -H "Content-Type: application/x-tar" --data-binary @${tarFile}  ${WWW_TARGET_HOST}/${REMOTE_DIR}/${TAR_RESULTS_FILENAME}
			sleep ${SLEEP_DELAY}
		done
	fi
fi
