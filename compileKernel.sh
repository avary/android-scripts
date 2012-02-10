#!/bin/bash

# Set-up environment
NAME=aa-mdj-s
VER=aa_0.7

export K_ROOT=$PWD/../
export K_SRC=$K_ROOT/$NAME
export K_WORK=$K_SRC-work
export K_OUTPUT=$K_SRC-out
export ARCH=arm
export CROSS_COMPILE=/data/android/toolchain/arm-2010.09/bin/arm-none-eabi-
export INSTALL_MOD_PATH=$K_OUTPUT/system/lib/modules

# Set-up directories
# Working Directories
rm -rf $K_WORK
cp -al $K_SRC $K_WORK

# Output directories
rm -rf $K_OUTPUT/boot/*
rm -rf $K_OUTPUT/system/lib/modules/*
rm -rf $K_OUTPUT/devs/*
rm -rf $K_OUTPUT/*.zip
mkdir -p $K_OUTPUT/boot
mkdir -p $K_OUTPUT/devs

# Start compilation process
# Go into working directory
cd $K_WORK

# Grab the relevant config
make htcleo-aa_defconfig

# Number of processors
NP=`cat /proc/cpuinfo  | grep processor | wc -l`
THREADS=`echo "$NP + 1" | bc`

# Compile the zImage
make -j$THREADS zImage

cp $K_WORK/arch/arm/boot/zImage $K_OUTPUT/boot/
cp .config $K_OUTPUT/devs/build_config

# Create README
cat > $K_OUTPUT/devs/README.txt << EOF
Based on clone: http://git.gitorious.org/~arif-ali/linux-on-wince-htc/aa-mdj-s.git
Please reference it for diffs and further notes.

EOF

# Grab the git log
git log --since="Mon Aug 27 11:19:00 2010 +1000" >> $K_OUTPUT/devs/README.txt

# Compile/install the modules
make -j4 modules
make -j4 modules_install
cd $K_OUTPUT/system/lib/modules
find -iname *.ko | xargs -i -t cp {} .
rm -rf $K_OUTPUT/system/lib/modules/lib

# Check to see if the zImage is the right one 
stat $K_OUTPUT/boot/zImage

# Create the CWM zip file
cd $K_OUTPUT
cp -r $K_SRC/build-stuff/META-INF .
zip -9r kernel_$VER.zip .
