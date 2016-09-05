#!/bin/bash

NUM=$1
echo $NUM
if [ "$NUM" == '1' ]; then
    cd ../../../
else
    cd ../../
fi
source bin/lims2_setup.sh
lims2 test
lims2 webapp
