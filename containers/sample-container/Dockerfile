# start with a CentOS 7 base
from centos

label version="0.0.2" \
      run="docker run sample-container" \
	  source="" \
	  description="Sample container to verify base configuration and operation." \
	  purpose="Test container pull, storage allocation and writing to storage." \
	  parameters="Execution parameters are set via environment variables." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \	  
	  name="Sample Container" \
	  build-date="2017-10-19"

# set environment variables
ENV CONTAINER_NAME centos-sample
ENV CONTAINER_VERSION "0.0.2"
ENV HOME_DIR /home/test
ENV DATA_DIR /data

# perform yum installs
RUN yum -y update; yum clean all

# create a directory to hold scripts and data
RUN mkdir /home/test
RUN mkdir /data

COPY keep-alive.sh /home/test/
COPY run-test.sh /home/test/

# change to the home directory, configure container to run test
WORKDIR /home/test

# run the blockstorage test
CMD ["/bin/sh", "run-test.sh"]
