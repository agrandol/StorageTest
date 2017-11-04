# Simple IOzone
Simple IOzone container and k8s YAML

# Docker execution
To run via Docker:
  docker run agtestorg/simple-iozone:0.0.1

Note: This container will run the same test twice, the first will output IOPS, the second Bandwidth.

# k8s execution
First allocate a PVC:
  oc create -f simple-iozone-ceph.yml

Then run the IOzone container as a job:
  oc create -f simple-iozone-job.yml

The above two commands are included in the run-simple-iozone-job.sh. This can be run on the system or on minikube on your laptop.

# Notes
If you run the job you will see the job/pod start, looking at the logs the initial test will start, the test does not complete. If you wish to run pod interactvely, uncomment the line below in simple-iozone-job.yml:
```command: [ "/bin/bash", "-c", "/home/iozone/keep-alive.sh" ]```

The pod will run in an endless loop, exec into the pod and run the script ./run-iozone.sh
