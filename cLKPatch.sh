#!/bin/bash

KERNEL=/data/android/git/android_device_htc_leo_cm/prebuilt/kernel
INITRD=/data/android/leo/CM/source/out/target/product/leo/ramdisk.img
DATE=`date +%m%d%Y`

mkbootimg --kernel $KERNEL --ramdisk $INITRD --cmdline "console=null" --base 0x11800000 -o cLK/boot.img

cd cLK > /dev/null 2>&1
zip -9Dr ../charan_${DATE}_cLK_ppp_cache.zip * > /dev/null 2>&1
cd - > /dev/null 2>&1

scp charan_${DATE}_cLK_ppp_cache.zip arif-ali.co.uk:cmleonightly/cLK/. 
ssh arif-ali.co.uk "cd cmleonightly/cLK ; ln -sf charan_${DATE}_cLK_ppp_cache.zip charan_latest_cLK_ppp_cache.zip"
