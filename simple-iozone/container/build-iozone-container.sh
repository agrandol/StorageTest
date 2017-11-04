#!/bin/sh
#
# Build the IOzone container
#
# Filename: build-iozone-container.sh
#
#set -x

CONTAINER_NAME="simple-iozone"
CONTAINER_IMAGE="0.0.1"
REPO_AND_NAME="agtestorg/${CONTAINER_NAME}:${CONTAINER_IMAGE}"

# build the container
docker build -t ${REPO_AND_NAME} .
