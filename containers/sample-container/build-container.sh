#!/bin/sh
#
# Build the test container
#
# Filename: build-container.sh
#
#set -x


CWD=`pwd`


# build the container
docker build -t ranada/centos-sample .