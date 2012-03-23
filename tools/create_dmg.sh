#!/bin/sh

BUILT_PRODUCTS_DIR=${BUILT_PRODUCTS_DIR:-${SYMROOT}/Release}
CURRENT_MARKETING_VERSION=${CURRENT_MARKETING_VERSION:-x.x.x}

MY_DIR=`dirname "$0"`
BUILD_DIR="${BUILT_PRODUCTS_DIR}/dmg"
MNT_DIR="/tmp/mameosx-mnt"

mkdir -p "$BUILD_DIR"
mkdir -p "$MNT_DIR"

TEMPLATE_IMAGE="${BUILD_DIR}/mameosx-template.sparseimage"
DISK_IMAGE="${BUILD_DIR}/MAMEOSX-${CURRENT_MARKETING_VERSION}.dmg"
MOUNTED_VOLUME="${MNT_DIR}/MAME OS X"
APP="MAME OS X.app"

echo "${MY_DIR}"
cp "${MY_DIR}/mameosx-template.sparseimage.bz2" "$BUILD_DIR"
bunzip2 -f "${TEMPLATE_IMAGE}.bz2"

if [ -e "$MOUNTED_VOLUME" ]; then
    hdiutil detach "$MOUNTED_VOLUME" -force
fi

hdiutil attach -mountroot "${MNT_DIR}" "${TEMPLATE_IMAGE}"
rsync -Ea "${BUILT_PRODUCTS_DIR}/${APP}/" "${MOUNTED_VOLUME}/${APP}"
hdiutil detach "$MOUNTED_VOLUME" -force

if [ -e "$DISK_IMAGE" ]; then
    rm -f "$DISK_IMAGE"
fi

COMPRESSION="-format UDZO -imagekey zlib-level=9"
#COMPRESSION="-format UDBZ"
#COMPRESSION="-format UDRO"
hdiutil convert ${COMPRESSION} -o "${DISK_IMAGE}" "${TEMPLATE_IMAGE}"
#bzip2 "${DISK_IMAGE}"
