#!/bin/bash
#
# Start the webserver

PGREP="/usr/bin/pgrep"
PYTHON="/usr/bin/python"
PYTHON_WEBSVR="websvr.py"
CWD=`pwd`

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i)

# is the webserver running
${PGREP} -f ${PYTHON_WEBSVR}

# if the webserver is not running
if [[ $? -gt 0 ]] ; then
    # output the hostname and ip address
    echo "Starting webserver on: ${HOSTNAME}, IP address: ${IP_ADDRESS}"

    # start the web server in the background
    #${PYTHON} ${CWD}/${PYTHON_WEBSVR} &
    ${PYTHON} ${CWD}/${PYTHON_WEBSVR}
fi

# keep the container alive
#. ${CWD}/keep-alive.sh
