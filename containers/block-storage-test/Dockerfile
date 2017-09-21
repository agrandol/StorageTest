# start with a CentOS 7 base
from centos

label version="0.0.2" \
      run="docker run block-storage-test" \
	  source="" \
	  description="Block storage test configured to run with a startup scripts that will perform speed test on a specific mount point. Results will be sent to Logstash, results of individual runs will be stored in /home/block-storage/results." \
	  purpose="Test block storage performance." \
	  parameters="Execution parameters are set via environment variables. The environment variables used include: FILES_SIZES, TEST_END_TIME, BLOCK_STORAGE_TEST_DIR, MOUNT_DEVICE, ELASTICSEARCH_HOST, ELASTICSEARCH_USER, and ELASTICSEARCH_PASSWORD. These variables are set in the K8S YAML file." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \	  
	  name="Block Storage Test" \
	  build-date="2017-09-15"

# set environment variables
ENV container block-storage-test
ENV HOME_DIR /home/block-storage
ENV DATA_DIR /data

# perform yum installs
RUN yum -y update && yum -y install \
	perl 
#	java-1.8.0-openjdk   # needed for logstash
#RUN yum -y install openssh-server; yum clean all       # for file transfer, in case a transfer in
#RUN yum -y install openssh-clients; yum clean all      # for file transfer, transfer out
#RUN yum -y install python; yum clean all               # for connection to MongoDB
#RUN yum -y install pymongo; yum clean all              # for connection to MongoDB

# create a directory to hold the configuration script, application, and results
RUN mkdir /home/block-storage
RUN mkdir /home/block-storage/tests
RUN mkdir /home/block-storage/results
RUN mkdir /data

# copy RPMs to install at startup
# assumes the RPMs have been copied to the same directory as this Dockerfile
#COPY logstash.rpm /home/block-storage/

# copy the block storage files to the container
COPY set-env.sh /home/block-storage/
COPY configure-block-store.sh /home/block-storage/
COPY run-block-store.sh /home/block-storage/
COPY logstash.conf-template /home/block-storage/
COPY keep-alive.sh /home/block-storage/
COPY tests/ /home/block-storage/tests/

# change to the home directory, configure container to run test
WORKDIR /home/block-storage

# run the blockstorage test
CMD ["/bin/sh", "configure-block-store.sh"]
#CMD ["/bin/sh", "keep-alive.sh"]
