#!/bin/bash

WORKDIR=/data/android/git

cd $WORKDIR
rm -rf CM-gerrit

for file in `ls`
do
  if [[ -d $file ]] ; then
    pushd $file

    if [[ "$file" == "CM" ]] || [[ "$file" == "aosp"  ]]; then
      /data/bin/repo sync -j 5 -f
      /data/bin/repo sync -j 5 -f
      /data/bin/repo sync -j 5 -f
    else
      git pull
    fi

    popd
  fi
done

cp -al CM CM-gerrit
cd CM-gerrit
repo init -u git://github.com/CyanogenMod/android.git -b gingerbread
repo sync -j 5 -f
repo sync -j 5 -f
repo sync -j 5 -f
cd -
