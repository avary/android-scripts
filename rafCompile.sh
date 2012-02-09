#!/bin/bash

VERSIONS="1r9 2r0"

for VERSION in `echo $VERSIONS`
do

RAFDIR=kernel_rafpigna_${VERSION}_GB
KERNEL=$PWD/$RAFDIR/boot/zImage
INITRD=/data/android/leo/CM/source/out/target/product/leo/ramdisk.img
DATE=`date +%Y%m%d`

rm -rf $RAFDIR
mkdir $RAFDIR
cd $RAFDIR
unzip ../$RAFDIR.zip >/dev/null 2>&1
cd - >/dev/null 2>&1

# cLK

mkbootimg --kernel $KERNEL --ramdisk $INITRD --cmdline "console=null" --base 0x11800000 -o cLK/boot.img
mkdir -p cLK/system/lib/modules
rm -rf cLK/system/lib/modules/*
cp $RAFDIR/system/lib/modules/* cLK/system/lib/modules/.

rm -rf rafpigna_${VERSION}_charan_clk_${DATE}.zip
cd cLK 
zip -9Dr ../rafpigna_${VERSION}_charan_clk_${DATE}.zip * >/dev/null 2>&1
cd - >/dev/null 2>&1

# magldr

mkdir -p magldr/system/lib/modules
mkdir -p magldr/boot
rm -rf magldr/system/lib/modules/*
cp $RAFDIR/system/lib/modules/* magldr/system/lib/modules/.
cp $RAFDIR/boot/zImage magldr/boot/.

rm -rf rafpigna_${VERSION}_charan_magldr_${DATE}.zip
cd magldr
zip -9Dr ../rafpigna_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip * >/dev/null 2>&1
cd - >/dev/null 2>&1

scp rafpigna_${VERSION}_charan_magldr_${DATE}.zip rafpigna_${VERSION}_charan_clk_${DATE}.zip arif-ali.co.uk:cmleonightly/kernels/.
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf rafpigna_${VERSION}_charan_magldr_${DATE}.zip rafpigna_${VERSION}_charan_magldr_latest.zip"
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf rafpigna_${VERSION}_charan_clk_${DATE}.zip rafpigna_${VERSION}_charan_clk_latest.zip"

done
