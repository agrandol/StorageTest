# start with a CentOS 7 base
from centos

label version="0.0.2" \
      run="docker run ranada/fio" \
	  source="" \
	  description="fio benchmark container. Results can be sent to Logstash, results will be stored in /data." \
	  purpose="Test storage performance." \
	  parameters="Execution parameters are set via environment variables. The environment variables used include: TEST_END_TIME, ELASTICSEARCH_HOST, ELASTICSEARCH_USER, and ELASTICSEARCH_PASSWORD. These variables are set in the K8S YAML file." \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  test-source="https://centos.pkgs.org/7/epel-x86_64/fio-2.2.8-2.el7.x86_64.rpm.html" \
	  name="fio test" \
	  build-date="2017-10-31"

# set environment variables
ENV CONTAINER_NAME fio
ENV CONTAINER_VERSION "0.0.2"
ENV HOME_DIR /home/fio
ENV DATA_DIR /data

# perform yum installs
RUN yum -y update && yum -y install perl gcc make java-1.8.0-openjdk \
	libaio libaio-devel libibverbs librdmacm librados2-devel && \
	yum clean all && \
	rm -rf /var/cache/yum

# create a directory to hold the fio benchmark files
RUN mkdir /home/fio \
	/home/fio/rpms \
	/config \
	/data 

# copy the rpms needed
COPY rpms/ /home/fio/rpms/

# copy fio config files
COPY config/ /config/

# Install the benchmark and supporting libraries
RUN rpm -Uvh /home/fio/rpms/librbd1-0.94.5-2.el7.x86_64.rpm && \
	rpm -Uvh /home/fio/rpms/fio-2.2.8-2.el7.x86_64.rpm && \
	export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") && \
	rpm -Uvh /home/fio/rpms/logstash-5.6.2.rpm && \
	rm -rf /home/fio/rpms

# copy the fio benchmark files to the container
COPY configure-fio.sh /home/fio/
COPY run-fio.sh /home/fio/
COPY keep-alive.sh /home/fio/
COPY logstash.conf-template /home/fio/
COPY parse-fio.pl /home/fio

# change to the fio directory, prepare to run benchmark
WORKDIR /home/fio

# run the fio benchmark
CMD ["/bin/sh", "/home/fio/configure-fio.sh"]
