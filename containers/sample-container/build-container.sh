#!/bin/sh
#
# Build the test container
#
# Filename: build-container.sh
#
#set -x

CONTAINER_NAME="sample-container"
CONTAINER_IMAGE="0.0.1"
REPO_AND_NAME="ranada/${CONTAINER_NAME}:${CONTAINER_IMAGE}"

CWD=`pwd`

# build the container
docker build -t ${REPO_AND_NAME} .
