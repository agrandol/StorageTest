#!/bin/bash
#
# Keep the container alive using an endless loop
#
# Filename: keep-alive.sh
#

STAY_ALIVE_SLEEP_TIME="1m"
MESSAGE="Looping to stay alive"

echo "${MESSAGE} "
while true
do
	echo "."
	sleep ${STAY_ALIVE_SLEEP_TIME}
done
