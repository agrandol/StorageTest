# start with a CentOS 7 base
from centos

label version="0.0.4" \
      run="docker run iozone" \
	  source="" \
	  description="IOzone benchmark container that executes IOPS and Bandwidth test on a specific mount point. Results can be sent to Logstash, results of individual runs will be stored in /home/iozone/results." \
	  purpose="Test storage performance." \
	  parameters="Execution parameters are set via environment variables. The environment variables used include: TEST_END_TIME, IOZONE_TEST_DIR, MOUNT_DEVICE, ELASTICSEARCH_HOST, ELASTICSEARCH_USER, and ELASTICSEARCH_PASSWORD. These variables are set in the K8S YAML file." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  test-source="http://www.iozone.org/" \
	  name="IOzone test" \
	  build-date="2017-10-03"

# set environment variables
ENV container iozone-test
ENV HOME_DIR /home/iozone
ENV DATA_DIR /data

# perform yum installs
RUN yum -y update && yum -y install \
	perl \
	gcc \ 
	make \
	java-1.8.0-openjdk   # needed for logstash
#RUN yum -y install openssh-server; yum clean all       # for file transfer, in case a transfer in
#RUN yum -y install openssh-clients; yum clean all      # for file transfer, transfer out
#RUN yum -y install python; yum clean all               # for connection to MongoDB
#RUN yum -y install pymongo; yum clean all              # for connection to MongoDB

# create a directory to hold the IOzone benchmark files
RUN mkdir /home/iozone
RUN mkdir /home/iozone/iozone3_469
RUN mkdir /home/iozone/results
RUN mkdir /data  # to hold results, can also be mounted to store results outside container

# copy RPMs to install at startup
# assumes the RPMs have been copied to the same directory as this Dockerfile
COPY logstash-5.6.2.rpm /home/iozone/

# copy the IOzone benchmark files to the container
COPY iozoneMark.pl /home/iozone/
COPY configure-iozone.sh /home/iozone/
COPY run-iozone.sh /home/iozone/
COPY logstash.conf-template /home/iozone/
COPY iozone3_469/ /home/iozone/iozone3_469/

# change to the iozone directory, prepare to run benchmark
WORKDIR /home/iozone

# run the iozone benchmark
CMD ["/bin/sh", "/home/iozone/configure-iozone.sh"]
