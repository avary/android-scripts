#!/bin/bash

VERSIONS="r11 r12 r12.4"
RELEASE=

for VERSION in `echo $VERSIONS` ; do 

if [[ "$VERSION" == "r12.4" ]] ; then
  RELEASE=_v3
fi

TYTDIR=kernel_tytung_${VERSION}_update${RELEASE}
KERNEL=$PWD/$TYTDIR/boot/zImage
INITRD=/data/android/leo/CM/source/out/target/product/leo/ramdisk.img
DATE=`date +%Y%m%d`

rm -rf $TYTDIR
mkdir $TYTDIR
cd $TYTDIR
unzip ../$TYTDIR.zip >/dev/null 2>&1
cd - >/dev/null 2>&1

# cLK

mkbootimg --kernel $KERNEL --ramdisk $INITRD --cmdline "console=null" --base 0x11800000 -o cLK/boot.img
mkdir -p cLK/system/lib/modules
rm -rf cLK/system/lib/modules/*
cp $TYTDIR/system/lib/modules/* cLK/system/lib/modules/.

rm -rf tytung_${VERSION}_charan_clk_${DATE}.zip
cd cLK
zip -9Dr ../tytung_${VERSION}${RELEASE}_charan_clk_${DATE}.zip * > /dev/null 2>&1
cd - > /dev/null 2>&1

# magldr

mkdir -p magldr/system/lib/modules
mkdir -p magldr/boot
rm -rf magldr/system/lib/modules/*
cp $TYTDIR/system/lib/modules/* magldr/system/lib/modules/.
cp $TYTDIR/boot/zImage magldr/boot/.

rm -rf tytung_${VERSION}_charan_magldr_${DATE}.zip
cd magldr
zip -9Dr ../tytung_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip * > /dev/null 2>&1
cd - > /dev/null 2>&1

scp tytung_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip tytung_${VERSION}${RELEASE}_charan_clk_${DATE}.zip arif-ali.co.uk:cmleonightly/kernels/.
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf tytung_${VERSION}${RELEASE}_charan_magldr_${DATE}.zip tytung_${VERSION}${RELEASE}_charan_magldr_latest.zip"
ssh arif-ali.co.uk "cd cmleonightly/kernels ; ln -sf tytung_${VERSION}${RELEASE}_charan_clk_${DATE}.zip tytung_${VERSION}${RELEASE}_charan_clk_latest.zip"

done
