#!/bin/sh

mkdir -p build

CONFIG=${CONFIG:-Release}
xcodebuild -target 'Disk Image' -configuration ${CONFIG} \
        2>&1 | tee build/build_dmg_log.txt
