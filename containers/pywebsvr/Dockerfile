# Build a container to run a webserver to collect results 
# 

# start with a CentOS 7 base
from centos

label version="0.0.1" \
      run="docker run ranada/pywebsvr:0.0.1" \
	  source="" \
	  description="pywebsvr webserver to collect test resultsthat will be stored in /results." \
	  purpose="Collect test results." \
	  parameters="None" \
	  maintainer="" \
	  base-image="CentOS 7 Base Image" \
	  name="pywebsvr" \
	  build-date="2017-11-16"

# set environment variables
ENV CONTAINER_NAME="pywebsvr" \
	CONTAINER_VERSION="0.0.1" \
	HOME_DIR="/home/pywebsvr" \
	RESULTS_DIR="/results"

# perform yum installs and create directories
RUN yum -y update && \
	yum -y install git && \
	yum clean all && \
	mkdir  /home/pywebsvr  /results

# copy the pywebsvr files to the container
COPY websvr.py /home/pywebsvr/
COPY start.sh /home/pywebsvr/
#COPY keep-alive.sh /home/pywebsvr/

# copy the ssh keys
#COPY ssh/ /root/.ssh/
#RUN chmod 600 /root/.ssh/id_rsa /root/.ssh/id_rsa.pub

# change to the fio directory
WORKDIR /home/pywebsvr

# start the webserver
CMD ["/bin/bash", "/home/pywebsvr/start.sh"]
