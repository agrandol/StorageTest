# K8S - Kubernetes README File

## Overview

This directory contains scripts and YAML files that are used to perform storage system testing. Test results are written to the logs but can also be written Elasticsearch provided that host IP address, port, and login credentials are supplied.

## Directories

The directory structure and the contents of the k8s directory is as follows:
* StorageTest
  * k8s
    * **_block-storage-test_** - scripts and YAML files to run the Block Storage tests.
	* **_iozone_** - scripts and YAML files to run the IOzone bandwidth and IOPS tests.
