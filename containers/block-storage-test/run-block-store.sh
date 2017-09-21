#!/bin/sh
#
# Run the block storage test
#
#set -x
PERL="/usr/bin/perl"

# set the test environment
source ./set-env.sh

# capture the results in a file
LOG_FILENAME="BlockStore-$(date +%Y%m%d-%H%M%S).log"

if [ -z "${TEST_HOME}" ]
then
	echo "TEST_HOME is not defined"
	exit 1
fi

# redirect all output and errors to the log file
#exec 3>&1 4>&2 >> ${TEST_HOME}/${LOG_FILENAME} 2>&1
exec 3>&1 4>&2 >> ${DATA_DIR}/${LOG_FILENAME} 2>&1

# default mount and file system
#mntSpot=${TEST_HOME}/blockStoreWork
mntSpot=${DATA_DIR}/blockStoreWork
FS=overlayfs # will actually check a bit further down

# if the file system mount point is set in environment
#if [ -n "${BLOCK_STORAGE_TEST_DIR}" ]
#then
#	# set the file system mount to use for testing
#	echo "Setting mount point to ${BLOCK_STORAGE_TEST_DIR}"
#	mntSpot=${BLOCK_STORAGE_TEST_DIR}
#fi

# data files will be written to the /data directory, this directory can be mounted
# to another or file system type using container/k8s mount feature

instance=${1:-container}

source ${TEST_HOME}/SETUP.${instance}
source ${TEST_HOME}/TEST.bash

MY_HOSTNAME=`hostname`

#----------------------------------------------------------------------------
#
# Run the Block Storage Test
#
SIZES='102400 1048576 1073741824 10737418240 1099511627776' #  100KB 1MB 1GB 10GB 1TB
SIZES='102400 1048576 1073741824 10737418240' #  100KB 1MB 1GB 10GB
SIZES='102400 1048576 1073741824' #  100KB 1MB 1GB
#SIZES='102400 1048576' #  100KB 1MB

if [ -n "${FILE_SIZES}" ] # FILE_SIZES defined in environment passed in
then
	echo "Setting file sizes to: ${FILE_SIZES}"
	SIZES=${FILE_SIZES}
fi

#----------------------------------------------------------------------------

blockHome=${mntSpot}/${MY_HOSTNAME}
[ -d ${blockHome} ] || mkdir -p ${blockHome}

# find file system type of the test directory
FS=`stat --file-system --format=%T ${mntSpot}`

_label Using ${blockHome}
_label Metric: blockStorage
_label Hostname: ${MY_HOSTNAME}

START_TIME=`date "+%Y-%m-%d'T'%H:%M:%S"`
_label Start Time: ${START_TIME}
_label Block Store Units: MB/s
_label File System Type: ${FS}

pushd ${blockHome}
for loop in a b c d e f g h
do
	_label Loop ${loop}
	for size in ${SIZES}
	do
		tfile=tmp${size}.dat
		_label ${FS} Block Write ${size} bytes
		${TEST_HOME}/BinaryGen.py -o ${tfile} -s ${size}
		ls -l ${blockHome}
		df -h ${blockHome}
		_label ${FS} Block Read ${size} bytes
		_run dd if=${tfile} bs=1M of=/dev/null
		
		rm -f ${tfile}
	done
done

popd

STOP_TIME=`date "+%Y-%m-%d'T'%H:%M:%S"`
_label Stop Time: ${STOP_TIME}

rmdir ${blockHome}

echo "Block store test complete"
# redirect output to standard devices
exec 1>&3 3>&- 2>&4 4>&-

# extract results
#${PERL} ${TEST_HOME}/simpleKPP.pl ${TEST_HOME}/${LOG_FILENAME}
${PERL} ${TEST_HOME}/simpleKPP.pl ${DATA_DIR}/${LOG_FILENAME}