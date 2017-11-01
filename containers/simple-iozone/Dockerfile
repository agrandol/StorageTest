# start with a CentOS 7 base
from centos

label version="0.0.1" \
      run="docker run simple-iozone" \
	  source="" \
	  description="A simplified IOzone benchmark container." \
	  purpose="Test storage performance." \
	  parameters="Execution parameters are set via environment variables." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  test-source="http://www.iozone.org/" \
	  name="IOzone test" \
	  build-date="2017-10-31"

# set environment variables
ENV CONTAINER_NAME simple-iozone
ENV CONTAINER_VERSION "0.0.1"
ENV HOME_DIR /home/iozone
ENV DATA_DIR /data

# perform yum installs
#RUN yum -y update && yum -y install perl gcc make java-1.8.0-openjdk && \
RUN yum -y update && yum -y install gcc make && \
	yum clean all && \
	rm -rf /var/cache/yum

# create a directory to hold the IOzone benchmark files
RUN mkdir /home/iozone \
	/home/iozone/iozone3_471 \
	/data 

# copy the IOzone benchmark files to the container
COPY run-iozone.sh /home/iozone/
COPY iozone3_471/ /home/iozone/iozone3_471/


# build the benchmark and install logstash
#RUN cd /home/iozone/iozone3_469/src/current && \
RUN cd /home/iozone/iozone3_471/src/current && \
	make linux-ia64 && \
	cp iozone /usr/bin/iozone

# change to the iozone directory, prepare to run benchmark
WORKDIR /home/iozone

# run the iozone benchmark
CMD ["/bin/sh", "/home/iozone/run-iozone.sh"]
