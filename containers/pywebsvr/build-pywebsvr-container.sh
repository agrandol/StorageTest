#!/bin/sh
#
# Build the pysebsvr container
#
# Filename: build-pywebsvr-container.sh
#
#set -x

DOCKER_REPO="ranada"
CONTAINER_NAME="pywebsvr"
CONTAINER_IMAGE="0.0.1"
REPO_AND_NAME="${DOCKER_REPO}/${CONTAINER_NAME}:${CONTAINER_IMAGE}"

# build the container
docker build -t ${REPO_AND_NAME} .
