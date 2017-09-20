#!/bin/bash
#
# Make and run the IOzone benchmark
#
#set -x
PERL="/usr/bin/perl"

# run the benchmark
${PERL} iozoneMark.pl ${IOZONE_TEST_DIR}
