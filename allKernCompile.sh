#!/bin/bash

cp /data/android/leo/CM/source/out/target/product/leo/ramdisk.img .

for kernel in `echo charan marc tytung rafpigna`
do
cd $kernel > /dev/null 2>&1
./script.sh
cd - > /dev/null 2>&1
done
