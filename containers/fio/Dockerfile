# start with a CentOS 7 base
from centos

label version="0.0.1" \
      run="docker run ranada/fio" \
	  source="" \
	  description="fio benchmark container. Results can be sent to Logstash, results of individual runs will be stored in /data." \
	  purpose="Test storage performance." \
	  parameters="Execution parameters are set via environment variables. The environment variables used include: TEST_END_TIME, ELASTICSEARCH_HOST, ELASTICSEARCH_USER, and ELASTICSEARCH_PASSWORD. These variables are set in the K8S YAML file." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  test-source="http://www.iozone.org/" \
	  name="fio test" \
	  build-date="2017-10-24"

# set environment variables
ENV CONTAINER_NAME fio
ENV CONTAINER_VERSION "0.0.1"
ENV HOME_DIR /home/fio
ENV DATA_DIR /data

# perform yum installs
RUN yum -y update && yum -y install perl gcc make java-1.8.0-openjdk && \
	yum clean all && \
	rm -rf /var/cache/yum

# create a directory to hold the fio benchmark files
RUN mkdir /home/fio \
	/home/fio/fio-2.1.10 \
	/data 

# copy the fio benchmark files to the container
COPY configure-fio.sh /home/fio/
COPY run-fio.sh /home/fio/
COPY keep-alive.sh /home/fio/
COPY logstash.conf-template /home/fio/
COPY fio-2.1.10/ /home/fio/fio-2.1.10/
COPY trivial.fio /home/fio/

# copy ELK RPMs to install
# assumes the RPMs have been copied to the same directory as this Dockerfile
COPY logstash-5.6.2.rpm /home/fio/


# build the benchmark and install logstash
RUN cd /home/fio/fio-2.1.10 && \
	./configure && \
	make && \
	make install && \
	export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") && \
	rpm -Uvh /home/fio/logstash-5.6.2.rpm && \
	rm /home/fio/logstash-5.6.2.rpm 

# change to the fio directory, prepare to run benchmark
WORKDIR /home/fio

# run the fio benchmark
#CMD ["/bin/sh", "/home/fio/configure-fio.sh"]
CMD ["/bin/sh", "/home/fio/run-fio.sh"]
