#!/bin/bash
#
# Run fio
#
#set -x
PERL="/usr/bin/perl"

df -hT

fio trivial.fio

df -hT

