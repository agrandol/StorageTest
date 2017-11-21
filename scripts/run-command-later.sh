#!/bin/bash
#
# Run a command at a later time
#
# Filename: run-command-later.sh
#
# vim: tabstop=4: noexpandtab
#set -x

usage() {
	echo ""
	echo "Run a command at a later time. The command and the time to execute the command must be supplied."
	echo "usage: $0 [OPTIONS]"
	echo "  -c <COMMAND_TO_RUN> | --command <COMMAND_TO_RUN>  the command to run including all arguments. The command should be"
	echo "                                                    enclosed in quotes.  Example \"ls -al\""
	echo "  -t <TIME>           | --time <TIME>               the time to run the command in date \"+%m%d%H%M\" format."	
	echo "  -h                  | --help                      display this help message."
	echo ""
}

# number of required arguments
NUM_REQUIRED_ARGS=2

# Time to sleep before testing if it's time to run command
SLEEP_TIME="5m"

# sample command
START_TIME="11180200"  # date-time in the format mmddHHMM
CMD_TO_RUN="ls -al"

# if less that two arguments passed in
if [[ $# -lt ${NUM_REQUIRED_ARGS} ]]; then
	echo "$0 must be called with ${NUM_REQUIRED_ARGS} arguments"
	usage
	exit 1
fi

# Process command line arguments
while [ "$1" != "" ]; do
	case $1 in
		-c | --command )
			shift
			COMMAND_TO_RUN=$1
			;;
		-t | --time )
			shift
			START_TIME=$1
			;;
		-h | --help )
			usage
			exit 1
			;;
		* )
			usage
			exit 1
			;;
	esac
	shift
done

# wait for the start time
while :
do
	CURRENT_TIME=`date +%m%d%H%M`
	if [ ${CURRENT_TIME} -gt ${START_TIME} ]; then
		date; echo "Starting command"
		break
	fi

	sleep ${SLEEP_TIME}
done

# run the command
${CMD_TO_RUN}
