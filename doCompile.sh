#!/bin/bash

LEO_URL=git://github.com/cmhtcleo/android_device_htc_leo.git

LEO_DIR=/data/android/git/android_device_htc_leo_cm
CM_DIR=/data/android/git/CM
KERN_DIR=/data/android/leo/CM/misc/kernels

WORKDIR=/data/android/leo/CM
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
  cp -al $CM_DIR/* $SOURCE/.
  mkdir $SOURCE/out
  mount -t tmpfs -o size=4608M tmpfs $SOURCE/out

  echo "DONE"
}

clean()
{
  echo -n "Cleaning up ... "
  pushd $SOURCE > /dev/null 2>&1
  make -j2 clean dataclean installclean > /dev/null 2>&1
  rm -rf out/* > /dev/null 2>&1
  umount out > /dev/null 2>&1
  popd > /dev/null 2>&1
  rm -rf $SOURCE > /dev/null 2>&1
  echo "DONE"
}

compile()
{
  device=$1

  clean
  syncDirs

  echo -n "Compiling image ... "
  pushd $SOURCE > /dev/null 2>&1

  export CYANOGEN_NIGHTLY=1
  export USE_CCACHE=1

  sed -i s/developerid=cyanogenmodnightly/developerid=cyanogenmodleonightly/g vendor/cyanogen/products/common.mk

  cp ./vendor/cyanogen/products/cyanogen_${device}.mk buildspec.mk
  cp ../out/update-cm-20111031.zip leo_update.zip
  echo "Getting ROMManager"
  ./vendor/cyanogen/get-rommanager
  #cp -r ../proprietory/htc ./vendor/.
  pushd device/htc/leo > /dev/null 2>&1
  ./unzip-files.sh > /dev/null 2>&1
  popd > /dev/null 2>&1
  echo -n "setting up environment ... "
  . build/envsetup.sh > /dev/null 2>&1
  echo -n "running brunch ... "
  lunch cyanogen_${device}-eng
  make -j 5 bootimage
  make -j 5 bacon
  echo "DONE"

  cp out/target/product/leo/update-squished.zip $OUTPUT/update-cm-${date1}.zip

  popd > /dev/null 2>&1
}

upload()
{
  device=$1

  cp $OUTPUT/update-cm-${date1}.zip /data/httpd/cm${device}nightly/rom/cm_${device}_full-${date1}.zip
  pushd $OUTPUT
  echo "\$ uploadnightly ${date1} " | ftp cmleonightly1.co.cc
  echo "\$ uploadnightly ${date1} " | ftp cyanogenmod.arif-ali.co.uk
  popd
}

createManifest()
{
MAIN=/data/dropbox/Dropbox/Public/RM.js

if [[ ! `grep CyanogenMod-7-${date2}-NIGHTLY-LEO $MAIN` ]]
then
if [[ -e $OUTPUT/update-cm-${date1}.zip ]] 
then

cat > $WORKDIR/RM/new.js << EOF
 {
  "modversion": "CyanogenMod-7-${date2}-NIGHTLY-LEO",
  "incremental": "${date1}",
  "name": "CM7 - Build #${date1}",
  "urls": ["http://cyanogenmod.arif-ali.co.uk/rom/cm_leo_full-${date1}.zip",
           "http://cmleonightly1.co.cc/rom/cm_leo_full-${date1}.zip"],
  "device": "leo",
  "addons": [{
    "name": "Google Apps 20110828",
    "urls": ["http://goo-inside.me/gapps/gapps-gb-20110828-signed.zip"]
   },
   {
    "name": "dtapps2sd 2.7.5.3b4",
    "urls": ["http://cyanogenmod.arif-ali.co.uk/misc/dtapps2sd-2.7.5.3-beta04-signed.zip"]
   },
   {
    "name": "3rd Party",
    "urls": ["http://cyanogenmod.arif-ali.co.uk/misc/3rdParty-20111025.zip"]
   },
   {
    "name": "CWR 5.0.2.6",
    "urls": ["http://cyanogenmod.arif-ali.co.uk/recoveries/recovery_5.0.2.6_leo_CWR.zip"]
   }
   ],
   "choices": [{
     "name": "Kernel",
     "options": [{
       "name": "charans ${date2}",
       "url": "http://cyanogenmod.arif-ali.co.uk/cLK/charan_${date2}_cLK_ppp_cache.zip"
     },
     {
       "name": "tytung r11",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/tytung_r11_charan_clk_${date1}.zip"
     },
     {
       "name": "tytung r12",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/tytung_r12_charan_clk_${date1}.zip"
     },
     {
       "name": "tytung r12.4_v3",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/tytung_r12.4_v3_charan_clk_${date1}.zip"
     },
     {
       "name": "rafpigna 1r9",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/rafpigna_1r9_charan_clk_${date1}.zip"
     },
     {
       "name": "rafpigna 2r0",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/rafpigna_2r0_charan_clk_${date1}.zip"
     }
     ]
    }],
   "product": "cyanogenmodleonightly",
   "summary": "${date3}"
  },
EOF

cp $MAIN $MAIN.$date1
LINES=`cat $MAIN | wc -l`
CUT=$(( $LINES - 5 ))
tail -n $CUT $MAIN > /tmp/rom.js
cat $WORKDIR/RM/head.js > ${MAIN}
cat $WORKDIR/RM/new.js >> ${MAIN}
cat /tmp/rom.js >> ${MAIN}
fi
fi
}

syncRepos()
{
  echo -n "Syncing latest repos ... "
  echo -n "leo ... "
  pushd $LEO_DIR > /dev/null 2>&1
  git pull > /dev/null 2>&1
  git pull $LEO_URL gingerbread > /dev/null 2>&1
  popd > /dev/null 2>&1
  echo "DONE"
}

doPatches()
{
  echo -n "Buildingg cLK and kernel patches ... "
  pushd $KERN_DIR > /dev/null 2>&1
  ./doKernels.sh > /dev/null 2>&1
  popd > /dev/null 2>&1
  echo "DONE"
}

syncRepos
compile leo
upload leo
doPatches
createManifest
clean
