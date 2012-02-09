#!/bin/bash

RECOVERY_URL=git://github.com/CyanogenMod/android_bootable_recovery.git
LEO_URL=git://github.com/CyanogenMod/android_device_htc_leo.git

RECOVERY_DIR=/data/android/git/android_bootable_recovery
LEO_DIR=/data/android/git/android_device_htc_leo_cm
CM_DIR=/data/android/git/CM

WORKDIR=/data/android/recovery
OUTPUT=$WORKDIR/out
SOURCE=$WORKDIR/source

mkdir -p $OUTPUT
mkdir -p $SOURCE
rm -rf $OUTPUT/*

cd $WORKDIR

NIGHTLY=0

[[ "$1" == "NIGHTLY" ]] && NIGHTLY=1

syncDirs()
{
  echo -n "Synchronising directories ... "
  cp -alf $CM_DIR/* $SOURCE/.

  echo -n "Recovery ... "
  pushd $SOURCE/bootable/recovery > /dev/null 2>&1

  rm -rf *
  rsync -az $RECOVERY_DIR/* .

  popd  > /dev/null 2>&1
  echo -n "leo ... "
  pushd $SOURCE/device/htc/leo > /dev/null 2>&1

  rm -rf *
  rsync -az $LEO_DIR/* .

  popd  > /dev/null 2>&1
  echo "DONE"
}

clean()
{
  echo -n "Cleaning up ... "
  pushd $SOURCE > /dev/null 2>&1
  rm -rf $OUTPUT/*
  make -j2 clean dataclean installclean > /dev/null 2>&1
  rm -rf * > /dev/null 2>&1
  popd > /dev/null 2>&1
  echo "DONE"
}

compile()
{
  device=$1
  bootloader=$2

  clean
  syncDirs

  echo -n "Compiling image ... "
  pushd $SOURCE > /dev/null 2>&1

  VERSION1=`grep RECOVERY_VERSION bootable/recovery/Android.mk  | head -n 1 | awk '{ print $NF }' | sed s/v//`
  VERSION2=$VERSION1

  if [[ $NIGHTLY -eq 1 ]] ; then
    VERSION2=$VERSION1-`date +%Y%m%d`
  fi

  cp ./vendor/cyanogen/products/cyanogen_${device}.mk buildspec.mk
  echo -n "setting up environment ... "
  . build/envsetup.sh > /dev/null 2>&1
  echo -n "running lunch ... "
  lunch cyanogen_${device}-eng > /dev/null 2>&1
  echo -n "compiling recovery ... "
  make -j2 recoveryimage 2>&1 | tail -n 10
  echo "DONE"
  
  popd > /dev/null 2>&1

  if [[ "${device}" == "leo" ]] ; then
    cp $SOURCE/out/target/product/${device}/recovery.img $OUTPUT/recovery_${VERSION2}_${device}.img
    cp $SOURCE/out/target/product/${device}/recovery.img $WORKDIR/CWR/recovery_${device}.img

cat > $WORKDIR/CWR/sdcard/clockworkmod/.settings << EOF
{"paypal_transaction_id":"","is_clockworkmod":true,"current_recovery_version":"${VERSION1}","flash_recovery":"","detected_device":"leo","readonly_recovery":false,"recovery_timestamp":"`date +%s`
","reboot_recovery":""}
EOF

pushd $WORKDIR/CWR > /dev/null 2>&1
      zip -9Dr $OUTPUT/recovery_${VERSION2}_${device}_CWR.zip *
    popd > /dev/null 2>&1
    zip -9Dr $OUTPUT/recovery_${VERSION2}_${device}.img.zip $OUTPUT/recovery_${VERSION2}_${device}.img
    pushd $OUTPUT > /dev/null 2>&1
      mkdir -p ${VERSION2}_${device}_sd
      cp $SOURCE/out/target/product/${device}/ramdisk-recovery.img ${VERSION2}_${device}_sd/initrd.gz
      cp $SOURCE/out/target/product/${device}/kernel ${VERSION2}_${device}_sd/zImage
      zip -9Dr recovery_${VERSION2}_${device}_sd.zip ${VERSION2}_${device}_sd
      rm -rf ${VERSION2}_${device}_sd
    popd > /dev/null 2>&1
  else
    cp $SOURCE/out/target/product/${device}/recovery.img $OUTPUT/recovery_${VERSION2}_${device}.img
    zip -9Dr $OUTPUT/recovery_${VERSION2}_${device}.img.zip $OUTPUT/recovery_${VERSION2}_${device}.img
  fi

  mkdir -p /data/dropbox/Dropbox/${device}/android/recovery/${VERSION1}
  if [[ $NIGHTLY -eq 1 ]] ; then
     cp $OUTPUT/*.img /data/dropbox/Dropbox/${device}/android/recovery/${VERSION1}/.
  else
     cp $OUTPUT/* /data/dropbox/Dropbox/${device}/android/recovery/${VERSION1}/.

  fi 
  chown -R dropbox:dropbox /data/dropbox/Dropbox/${device}/android/recovery/*
}

echo -n "Syncing latest repos ... "
echo -n "Recovery ... "
pushd ${RECOVERY_DIR} > /dev/null 2>&1
git pull > /dev/null 2>&1
git pull ${RECOVERY_URL} gingerbread > /dev/null 2>&1
popd > /dev/null 2>&1
echo -n "leo ... "
pushd ${LEO_DIR} > /dev/null 2>&1
git pull > /dev/null 2>&1
git pull ${LEO_URL} gingerbread > /dev/null 2>&1
popd > /dev/null 2>&1
echo "DONE"

compile leo
compile click
