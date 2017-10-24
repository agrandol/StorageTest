#!/bin/bash
#
# Make and run the IOzone benchmark
#
#set -x
PERL="/usr/bin/perl"

SIZES='10m' # 500m' 
CACHE='4' #8 16 32'
#RECORD_SIZES='4k 8k 16k 32k'
NUM_THREADS='1' #'8'

#TEST_FILE_SIZE="10m"
#TEST_CACHE_SIZE="8"
#TEST_RECORD_SIZE="8k"
#TEST_NUM_THREADS="8"

# display filesystem information
df -hT

if [ -n "${FILE_SIZES}" ] # FILE_SIZES defined in environment passed in
then
	echo "Setting file sizes to: ${FILE_SIZES}"
	SIZES=${FILE_SIZES}
fi

if [ -n "${CACHE_SIZES}" ] # CACHE_SIZES defined in environment passed in
then
	echo "Setting cache sizes to: ${CACHE_SIZES}"
	CACHE=${CACHE_SIZES}
fi

if [ -n "${NUMBER_OF_THREADS}" ] # NUMBER_OF_THREADS defined in environment passed in
then
	echo "Setting number of threads to: ${NUMBER_OF_THREADS}"
	NUM_THREADS=${NUMBER_OF_THREADS}
fi


# for all test sizes to test
for TEST_FILE_SIZE in ${SIZES}
do
    echo "Test file size is: ${TEST_FILE_SIZE}"
    # for all cache sizes
    # cache size is in k
    for TEST_CACHE_SIZE in ${CACHE}
    do
        # align record size and cache size, need to add the k to record size
        TEST_RECORD_SIZE="${TEST_CACHE_SIZE}k"
        echo "Test cache and record size is: ${TEST_CACHE_SIZE}k"

        for TEST_NUM_THREADS in ${NUM_THREADS}
        do
            # run this iteration of the test
            ${PERL} iozoneMark.pl ${IOZONE_TEST_DIR} ${TEST_FILE_SIZE} ${TEST_CACHE_SIZE} ${TEST_RECORD_SIZE} ${TEST_NUM_THREADS}
        done
    done
done

# run the benchmark
#${PERL} iozoneMark.pl ${IOZONE_TEST_DIR} ${TEST_FILE_SIZE} ${TEST_CACHE_SIZE} ${TEST_RECORD_SIZE} ${TEST_NUM_THREADS}
