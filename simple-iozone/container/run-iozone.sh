#!/bin/bash
#
# Make and run the IOzone benchmark
#
#set -x
IOZONE_CMD="/usr/bin/iozone"

# test parameters
FILE_SIZE='10m'
CACHE_SIZE='4' #8 16 32'
RECORD_SIZE='4k' # 8k 16k 32k'
NUM_THREADS='1' #'8'

# start measuring time
SECONDS=0

# display filesystem information
df -hT

# change to the test directory, run there
TEST_DIR="/data"
cd ${TEST_DIR}

# run IOzone, IOS then BW
${IOZONE_CMD} -o -O -r${RECORD_SIZE} -S${CACHE_SIZE} -s${FILE_SIZE} -l${NUM_THREADS}
${IOZONE_CMD} -o -r${RECORD_SIZE} -S${CACHE_SIZE} -s${FILE_SIZE} -l${NUM_THREADS}

# display filesystem information
df -hT

# How long did the test run
DURATION=$SECONDS
echo "Test duration: $(($DURATION / 60)) minutes, $((DURATION % 60)) seconds"
