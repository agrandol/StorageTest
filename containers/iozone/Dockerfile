# start with a CentOS 7 base
from centos

label version="0.0.10" \
      run="docker run iozone" \
	  source="" \
	  description="IOzone benchmark container that executes IOPS and Bandwidth test on a specific mount point. Results can be sent to Logstash, results of individual runs will be stored in /data." \
	  purpose="Test storage performance." \
	  parameters="Execution parameters are set via environment variables. The environment variables used include: TEST_END_TIME, ELASTICSEARCH_HOST, ELASTICSEARCH_USER, and ELASTICSEARCH_PASSWORD. These variables are set in the K8S YAML file." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  test-source="http://www.iozone.org/" \
	  name="IOzone test" \
	  build-date="2017-10-31"

# set environment variables
ENV CONTAINER_NAME iozone
ENV CONTAINER_VERSION "0.0.10"
ENV HOME_DIR /home/iozone
ENV DATA_DIR /data

# perform yum installs
#RUN yum -y install perl gcc make java-1.8.0-openjdk && \
RUN yum -y update && yum -y install perl gcc make java-1.8.0-openjdk && \
	yum clean all && \
	rm -rf /var/cache/yum

# create a directory to hold the IOzone benchmark files
RUN mkdir /home/iozone \
	/home/iozone/iozone3_471 \
	/data 

# copy the IOzone benchmark files to the container
COPY iozoneMark.pl /home/iozone/
#COPY simpleIozoneMark.pl /home/iozone/
COPY configure-iozone.sh /home/iozone/
COPY run-iozone.sh /home/iozone/
COPY keep-alive.sh /home/iozone/
COPY logstash.conf-template /home/iozone/
#COPY iozone3_469/ /home/iozone/iozone3_469/
COPY iozone3_471/ /home/iozone/iozone3_471/

# copy ELK RPMs to install
# assumes the RPMs have been copied to the same directory as this Dockerfile
COPY logstash-5.6.2.rpm /home/iozone/


# build the benchmark and install logstash
#RUN cd /home/iozone/iozone3_469/src/current && \
RUN cd /home/iozone/iozone3_471/src/current && \
	make linux-ia64 && \
	cp iozone /usr/bin/iozone && \
	export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") && \
	rpm -Uvh /home/iozone/logstash-5.6.2.rpm && \
	rm /home/iozone/logstash-5.6.2.rpm 

#RUN yum -y install openssh-server; yum clean all       # for file transfer, in case a transfer in
#RUN yum -y install openssh-clients; yum clean all      # for file transfer, transfer out
#RUN yum -y install python; yum clean all               # for connection to MongoDB
#RUN yum -y install pymongo; yum clean all              # for connection to MongoDB


# change to the iozone directory, prepare to run benchmark
WORKDIR /home/iozone

# run the iozone benchmark
CMD ["/bin/sh", "/home/iozone/configure-iozone.sh"]
#CMD ["/bin/sh", "/home/iozone/keep-alive.sh"]
