# start with a CentOS 7 base
from centos

label version="0.0.1" \
      run="docker run sample-container" \
	  source="" \
	  description="Sample container to verify base configuration and operation." \
	  purpose="Test container pull, storage allocation and writing to storage." \
	  parameters="Execution parameters are set via environment variables." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \	  
	  name="Sample Container" \
	  build-date="2017-10-17"

# set environment variables
ENV container centos-sample
ENV HOME_DIR /home/test

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
