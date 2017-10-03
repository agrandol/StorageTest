#!/bin/sh
#
# Build the block storage test container
#
# Filename: build-block-storage-container.sh
#
#set -x

CONTAINER_NAME="block-storage-test"
CONTAINER_IMAGE="0.0.4"
REPO_AND_NAME="ranada/${CONTAINER_NAME}:${CONTAINER_IMAGE}"
RPM_DIRECTORY="../../elk-rpms"
LOGSTASH_RPM="logstash-5.6.2.rpm"            # set actual name of rpm file
#ELASTICSEARCH_RPM="elasticsearch.rpm"  # set actual name of rpm file

CWD=`pwd`

# copy the RPMs to the directory where the container will be built
cp ${RPM_DIRECTORY}/${LOGSTASH_RPM} ${CWD}

# build the container
docker build -t ${REPO_AND_NAME} .

# delete the RPMs from the Docker build directory
rm ${CWD}/${LOGSTASH_RPM}
