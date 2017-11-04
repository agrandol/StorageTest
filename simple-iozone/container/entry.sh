#!/bin/sh
#
# The initial script run when the container starts
#
# Filename: entry.sh
#

# make sure all scripts are executable
chmod u+x -R ${HOME_DIR}/*.sh

# run the iozone script
/bin/sh -c ${HOME_DIR}/run-iozone.sh
