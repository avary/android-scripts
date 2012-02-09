#!/bin/bash

#VERSIONS="0_0_4d 0_0_4e"
VERSIONS="0_0_4l"
RELEASE=

for VERSION in `echo $VERSIONS` ; do 

MARCDIR=marc1706_cm_${VERSION}
KERNEL=$PWD/$MARCDIR/boot/zImage
INITRD=/data/android/leo/CM/misc/kernels/ramdisk.img
DATE=`date +%Y%m%d`

rm -rf $MARCDIR
mkdir $MARCDIR
cd $MARCDIR
unzip ../$MARCDIR.zip >/dev/null 2>&1
cd - >/dev/null 2>&1

# cLK

mkbootimg --kernel $KERNEL --ramdisk $INITRD --cmdline "console=null" --base 0x11800000 -o cLK/boot.img
mkdir -p cLK/system/lib/modules
rm -rf cLK/system/lib/modules/*
cp $MARCDIR/system/lib/modules/* cLK/system/lib/modules/.

rm -rf marc1706_cm_${VERSION}_charan_clk_${DATE}.zip
cd cLK
zip -9Dr ../marc1706_cm_${VERSION}_charan_clk_${DATE}.zip * > /dev/null 2>&1
cd - > /dev/null 2>&1

# magldr

mkdir -p magldr/system/lib/modules
mkdir -p magldr/boot
rm -rf magldr/system/lib/modules/*
cp $MARCDIR/system/lib/modules/* magldr/system/lib/modules/.
cp $MARCDIR/boot/zImage magldr/boot/.

rm -rf marc1706_cm_${VERSION}_charan_magldr_${DATE}.zip
cd magldr
zip -9Dr ../marc1706_cm_${VERSION}_charan_magldr_${DATE}.zip * > /dev/null 2>&1
cd - > /dev/null 2>&1

scp marc1706_cm_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip marc1706_cm_${VERSION}${RELEASE}_charan_clk_${DATE}.zip arif-ali.co.uk:cmleonightly/kernels/.
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf marc1706_cm_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip marc1706_cm_${VERSION}${RELEASE}_charan_magldr_latest.zip"
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf marc1706_cm_${VERSION}${RELEASE}_charan_clk_${DATE}.zip marc1706_cm_${VERSION}${RELEASE}_charan_clk_latest.zip"

done
