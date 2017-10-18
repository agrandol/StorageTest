#!/bin/sh
#
# Keep the container alive using an endless loop
#
# Filename: keep-alive.sh
#
#set -x

STAY_ALIVE_SLEEP_TIME="1m"
LOOP_SLEEP="2s"
NUMBER_OF_LOOPS=10
DATA_DIR="/data"

echo "File system information"
df -hT

for i in `seq 1 ${NUMBER_OF_LOOPS}`
do
    FILENAME="${DATA_DIR}/sample-file-$i.text"
    echo "Writing content to: ${FILENAME}"
    echo "Sample content for file $i" > ${FILENAME}
    sleep ${LOOP_SLEEP}
done

echo "Display the contents of each file"

# for all files in the data directory
FILES="${DATA_DIR}/*"
for f in $FILES
do
    echo "Processing $f file..."
    cat $f
    echo ""
done

echo "Sleeping for ${STAY_ALIVE_SLEEP_TIME}, gather results" 
sleep ${STAY_ALIVE_SLEEP_TIME}
echo "Complete"
