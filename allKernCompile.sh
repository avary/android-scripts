#!/bin/bash

for kernel in `ls | grep -v doKern`
do
cd $kernel > /dev/null 2>&1
./script.sh
cd - > /dev/null 2>&1
done
