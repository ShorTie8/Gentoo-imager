#!/bin/bash
# A simple script to update to the latest foundation version
#
# BeerWare By ShorTie	<idiot@dot.com> 
#	Buy your Bud a beer if you like.
#	Pleaze Greenly recycle if you don't.

# Define message colors
OOPS="\033[1;31m"    # red
DONE="\033[1;32m"    # green
INFO="\033[1;33m"    # yellow
STEP="\033[1;34m"    # blue
WARN="\033[1;35m"    # hot pink
BOUL="\033[1;36m"	 # light blue
NO="\033[0m"         # normal/light


echo -e "${STEP}  Getting DEB_VERSION ${NO}"
DEB_VERSION=`curl --silent -L http://archive.raspberrypi.org/debian/dists/buster/main/binary-arm64/Packages | grep 'raspberrypi-firmware/raspberrypi-kernel-headers'  | cut -d"_" -f2`

CURRENT_VERSION=`cat /root/kernel_date` 2>/dev/null
KERNEL_DEB="raspberrypi-kernel_${DEB_VERSION}_arm64.deb"
echo -e "${STEP}\n  DEB_VERSION   is   ${DONE}$DEB_VERSION ${NO}"
echo -e "${STEP}  CURRENT_VERSION is ${DONE}$CURRENT_VERSION ${NO}"

if [ "$CURRENT_VERSION" != "$DEB_VERSION" ]; then
  mkdir -vp /var/tmp/kernel
  pushd /var/tmp/kernel

  echo -e "${STEP}    Downloadin Raspiberry pi kernel tarball ${DONE}$KERNEL_DEB ${NO}"
  wget -q -nc http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/$KERNEL_DEB || exit 1
  rm -vf /boot/{*.dtb,*.img}
  rm -rf /lib/modules/*

  echo -e "${STEP}    Extracting Raspiberry pi kernel $KERNEL_DEB ${NO}"
  ar x $KERNEL_DEB
  pv data.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C / || exit 1
  popd
  echo "${DEB_VERSION}" > /root/kernel_date

  ARCH=`uname -m`
  KERNEL=$(ls /lib/modules | grep v8+ | cut -d"-" -f1 | awk '{print$1}')
  echo -e "${STEP}      Crud Removal for kernel  ${DONE} ${ARCH} ${KERNEL}  ${NO}"
  if [ "$ARCH" = "arm" ]; then
    rm -v /boot/kernel8.img
    rm -v /boot/{bcm2711-rpi-4-b.dtb,bcm2711-rpi-cm4.dtb}
    echo "And /lib/modules/${KERNEL}-v8+"
    rm -rf /lib/modules/${KERNEL}-v8+
  else
    rm -v /boot/{kernel.img,kernel7.img,kernel7l.img}
    rm -v /boot/{bcm2708-rpi-cm.dtb,bcm2708-rpi-b.dtb,bcm2708-rpi-b-rev1.dtb,bcm2708-rpi-b-plus.dtb}
    rm -v /boot/{bcm2708-rpi-zero.dtb,bcm2708-rpi-zero-w.dtb,bcm2709-rpi-2-b.dtb}
    rm -v /boot/{bcm2710-rpi-2-b.dtb,bcm2710-rpi-cm3.dtb,bcm2710-rpi-3-b.dtb,bcm2710-rpi-3-b-plus.dtb}
    echo "And /lib/modules/{${KERNEL}+,${KERNEL}-v7+,${KERNEL}-v7l+}"
    rm -rf /lib/modules/{${KERNEL}+,${KERNEL}-v7+,${KERNEL}-v7l+}
  fi
  echo -en "${STEP}\n    Modules that are left are  ${DONE}"; ls /lib/modules; echo -e "${NO}"
else
  echo -e "${STEP}\n  Kernel is all ready ${INFO}@ ${DONE}$DEB_VERSION ${NO}"
  echo -e "${BOUL}  Y'all Have A Great Day now   ${NO}"
fi
rm -rf /var/tmp/kernel

exit 0
