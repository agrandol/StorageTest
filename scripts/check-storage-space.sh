#!/bin/bash
#
# Check the storage space on a set of servers
#
# Filename: check-storage-space.sh
#
# vim: tabstop=4: noexpandtab
#set -x

NODE_LIST="rhclient1 rhclient2 rhclient3 rhclient4"
SSH_CMD="ssh -q"
DF_CMD="df -hT"

for node in ${NODE_LIST}; do
    echo "Checking: ${node}"
    RETVAL=`${SSH_CMD} ${node} ${DF_CMD}`
    echo ${RET_VAL}
done
