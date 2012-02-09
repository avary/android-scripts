#!/bin/bash

CM_DIR=/data/android/git/CM
KERN_DIR=/data/android/leo/CM/misc/kernels

WORKDIR=/data/android/leo/CM
OUTPUT=$WORKDIR/out
SOURCE=$WORKDIR/source

date1=`date +%Y%m%d`
date2=`date +%m%d%Y`
date3=`date +%m-%d-%Y`

numProcs=$(( `cat /proc/cpuinfo  | grep processor | wc -l` + 1 ))

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
  #rm -rf $SOURCE > /dev/null 2>&1
  echo "DONE"
}

compile()
{
  manufacturer=$1
  device=$2

  echo -n "Compiling image ... "
  pushd $SOURCE > /dev/null 2>&1

  export CYANOGEN_NIGHTLY=1
  export USE_CCACHE=1

  if [[ ${device} = "leo" ]] ; then
    sed -i s/developerid=cyanogenmodnightly/developerid=cyanogenmodleonightly/g vendor/cyanogen/products/common.mk
  fi 

  cp ./vendor/cyanogen/products/cyanogen_${device}.mk buildspec.mk
  cp ../out/${device}_update.zip ${device}_update.zip
  echo "Getting ROMManager"
  ./vendor/cyanogen/get-rommanager
  if [[ ${device} = "galaxys2" ]]; then
    pushd device/${manufacturer}/${device} > /dev/null 2>&1
    ./unzip-files.sh > /dev/null 2>&1
    popd > /dev/null 2>&1
  fi
  echo -n "setting up environment ... "
  . build/envsetup.sh > /dev/null 2>&1
  echo -n "running brunch ... "
  lunch cyanogen_${device}-eng
  make -j ${numProcs} bootimage
  make -j ${numProcs} bacon
  echo "DONE"

  cp out/target/product/${device}/update-squished.zip $OUTPUT/update-cm7-${device}-${date1}.zip

  if [[ "${device}" = "leo" ]] ; then
    doPatches
    createManifest
  fi

  rm -rf out/target/product/${device}

  popd > /dev/null 2>&1
}

upload()
{
  manufacturer=$1
  device=$2

  mkdir -p /data/httpd/cm${device}nightly/rom
  cp $OUTPUT/update-cm7-${device}-${date1}.zip /data/httpd/cm${device}nightly/rom/update-cm7-${device}-${date1}.zip
  pushd $OUTPUT
  if [[ "${device}" = "leo" ]] ; then
     echo "\$ uploadnightly ${device} ${date1} " | ftp cmleonightly1.co.cc
  fi
  rsync -az update-cm7-${device}-${date1}.zip arif-ali.co.uk:cmleonightly/rom/.
  popd
}

createManifest()
{
MAIN=/data/dropbox/Dropbox/Public/RM.js

if [[ ! `grep CyanogenMod-7-${date2}-NIGHTLY-LEO $MAIN` ]]
then
if [[ -e $OUTPUT/update-cm7-leo-${date1}.zip ]] 
then

cat > $WORKDIR/RM/new.js << EOF
 {
  "modversion": "CyanogenMod-7-${date2}-NIGHTLY-LEO",
  "incremental": "${date1}",
  "name": "CM7 - Build #${date1}",
  "urls": ["http://cyanogenmod.arif-ali.co.uk/rom/update-cm7-leo-${date1}.zip",
           "http://cmleonightly1.co.cc/rom/update-cm7-leo-${date1}.zip"],
  "device": "leo",
  "label": "CM-7",
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
    "name": "CWR 5.0.2.7",
    "urls": ["http://cyanogenmod.arif-ali.co.uk/recoveries/recovery_5.0.2.7_leo_CWR.zip"]
   }
   ],
   "choices": [{
     "name": "Kernel",
     "options": [{
       "name": "charans ${date2}",
       "url": "http://cyanogenmod.arif-ali.co.uk/cLK/charan_${date2}_cLK_ppp_cache.zip"
     },
     {
       "name": "tytung r14",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/tytung_r14_charan_clk_${date1}.zip"
     },
     {
       "name": "rafpigna 2r0",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/rafpigna_2r0_charan_clk_${date1}.zip"
     },
     {
       "name": "marc1706 cm 0.0.04l",
       "url": "http://cyanogenmod.arif-ali.co.uk/kernels/marc1706_cm_0_0_4l_charan_clk_${date1}.zip"
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

doPatches()
{
  echo -n "Building cLK and kernel patches ... "
  pushd $KERN_DIR > /dev/null 2>&1
  ./doKernels.sh > /dev/null 2>&1
  popd > /dev/null 2>&1
  echo "DONE"
}

clean

devices="htc_leo samsung_galaxys2 htc_click"

for phone in `echo $devices`
do
  syncDirs

  manufact=`echo $phone | cut -d_ -f1`
  device=`echo $phone | cut -d_ -f2`

  compile $manufact $device
  upload $manufact $device
  clean
done
