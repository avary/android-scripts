#!/bin/bash

CM_DIR=/data/android/git/CM-ics

WORKDIR=/data/android/leo/CM-ics
OUTPUT=$WORKDIR/out
SOURCE=$WORKDIR/source

date1=`date +%Y%m%d`
date2=`date +%m%d%Y`
date3=`date +%m-%d-%Y`

mkdir -p $OUTPUT
mkdir -p $SOURCE

export PATH=/data/andriodsdk/platform-tools:$PATH
export PATH=/data/andriodsdk/tools:$PATH
export USER=$LOGNAME

syncDirs()
{
  echo -n "Synchronising directories ... "
  mkdir -p $SOURCE
  rsync -a --del $CM_DIR/* $SOURCE/.
  mkdir $SOURCE/out
  mount -t tmpfs -o size=13312M tmpfs $SOURCE/out

  echo "DONE"
}

clean()
{
  echo -n "Cleaning up ... "
  pushd $SOURCE > /dev/null 2>&1
  make -j5 clean dataclean installclean > /dev/null 2>&1
  rm -rf out/* > /dev/null 2>&1
  umount out > /dev/null 2>&1
  popd > /dev/null 2>&1
  #rm -rf $SOURCE > /dev/null 2>&1
  echo "DONE"
}

compile()
{
  device=$1

  clean
  syncDirs

  echo -n "Compiling image ... "
  pushd $SOURCE > /dev/null 2>&1

  export CM_NIGHTLY=1
  export USE_CCACHE=1

  sed -i s/developerid=cyanogenmodnightly/developerid=cyanogenmodleonightly/g vendor/cyanogen/products/common.mk

  echo "Getting ROMManager"
  pushd vendor/cm/ > /dev/null 2>&1
  ./get-prebuilts
  popd > /dev/null 2>&1
  echo -n "setting up environment ... "
  . build/envsetup.sh > /dev/null 2>&1
  echo -n "running brunch ... "
  lunch cm_${device}-eng
  make -j 5 bootimage
  make -j 5 bacon
  echo "DONE"

  release=""

  if [[ "$device" == "leo" ]] 
  then
    release="-magldr"
  fi

  cp out/target/product/${device}/update-squished.zip $OUTPUT/update-cm9-${device}${release}-${date1}.zip
  cp out/target/product/${device}/update-squished.zip /var/www/update-cm9-${device}${release}-${date1}.zip

  if [[ "$device" == "leo" ]] 
  then
    release="-clk"

    sed -i 's/\(^TARGET_CUSTOM_RELEASETOOL.*\)/#\1/g' device/htc/${device}/BoardConfig.mk

    make -j 5 bacon 
  
    cp out/target/product/${device}/update-squished.zip $OUTPUT/update-cm9-${device}${release}-${date1}.zip
    cp out/target/product/${device}/update-squished.zip /var/www/update-cm9-${device}${release}-${date1}.zip
  fi 

  popd > /dev/null 2>&1
}

upload()
{
  device=$1
  release=""

  if [[ "$device" == "leo" ]] 
  then
    release="-magldr"
  fi

  cp $OUTPUT/update-cm9-${device}${release}-${date1}.zip  /data/httpd/cm${device}nightly/rom/update-cm9-${device}${release}-${date1}.zip
  rsync -az $OUTPUT/update-cm9-${device}${release}-${date1}.zip arif-ali.co.uk:cmleonightly/rom/test/.

  if [[ "$device" == "leo" ]]
  then
    release="-clk"
    
    cp $OUTPUT/update-cm9-${device}${release}-${date1}.zip  /data/httpd/cm${device}nightly/rom/update-cm9-${device}${release}-${date1}.zip
    rsync -az $OUTPUT/update-cm9-${device}${release}-${date1}.zip arif-ali.co.uk:cmleonightly/rom/test/.
  fi
}

compile leo
#upload leo
#compile click
#upload click
