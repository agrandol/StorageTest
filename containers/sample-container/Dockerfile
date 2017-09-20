# start with a CentOS 7 base
from centos

# set environment variables
ENV container centos-sample
ENV HOME_DIR /home/test

# perform yum installs
RUN yum -y update; yum clean all

# create a directory to hold the configuration script, application, and results
RUN mkdir /home/test

COPY keep-alive.sh /home/test/

# change to the home directory, configure container to run test
WORKDIR /home/test

# run the blockstorage test
CMD ["/bin/sh", "keep-alive.sh"]
