#!/bin/sh
#
# Keep the container alive using an endless loop
#
# Filename: keep-alive.sh
#
#set -x

STAY_ALIVE_SLEEP_TIME="1m"
LOOP_SLEEP="2s"
NUMBER_OF_LOOPS=100
DATA_DIR="/data"
ONE_K="1024"
BUFFER_SIZE=$((8 * ${ONE_K}))

echo "File system information"
df -hT

for i in `seq 1 ${NUMBER_OF_LOOPS}`
do
    FILENAME="${DATA_DIR}/sample-file-$i.text"
    echo "Writing content to: ${FILENAME}"
    echo "Sample content for file $i" > ${FILENAME}
    echo "The text below is random text to fill the file" >> ${FILENAME}
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${BUFFER_SIZE} | head -n ${BUFFER_SIZE} >> ${FILENAME}
    sleep ${LOOP_SLEEP}
done

echo "Display the contents of each file"

# for all files in the data directory
FILES="${DATA_DIR}/*"
for f in $FILES
do
    echo "Processing $f file..."
    wc -l $f
    #cat $f
    echo ""
done

echo ""
echo "File system information"
df -hT

echo "Sleeping for ${STAY_ALIVE_SLEEP_TIME}, gather results" 
sleep ${STAY_ALIVE_SLEEP_TIME}
echo "Complete"
