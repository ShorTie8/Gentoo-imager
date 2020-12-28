#!/usr/bin/env bash
# A simple script to setup Gentoo in your image
#
# BeerWare By ShorTie	<idiot@dot.com> 

# Define message colors
OOPS="\033[1;31m"    # red
DONE="\033[1;32m"    # green
INFO="\033[1;33m"    # yellow
STEP="\033[1;34m"    # blue
WARN="\033[1;35m"    # hot pink
BOUL="\033[1;36m"	 # light blue
NO="\033[0m"         # normal/light

MAKEOPTS="-j`nproc`"

echo -e "${STEP}  Setting Trap ${NO}"
trap "echo; echo \"Unmounting /proc\"; exit 1" SIGINT SIGTERM

echo -e "${STEP}\n  Sourcing /etc/profile ${NO}"
source /etc/profile

echo -e "${STEP}  Sourcing /etc/portage/board.conf ${NO}"
source /etc/portage/board.conf
cat /etc/portage/board.conf

echo -e "${STEP}\n  Reading news  ${NO}"
eselect news read new


if [ "$USE_PORTAGE_LATEST" = "yes" ]; then
  echo -e "${STEP}\n  Nuffin to do, ${DONE}using portage-latest, ${STEP}moving right along  ${NO}"
else
  start_time=$(date)
  echo -e "${STEP}\n  emerge-webrsync  ${NO}"
  emerge-webrsync
  echo; echo $start_time
  echo $(date); echo
fi

echo -e "${STEP}\n  Checking eselect profile list \n ${NO}"
eselect profile list

echo -e "${STEP}\n  Checking the USE variable \n ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} --info | grep ^USE

echo -en "${STEP}\n  Changing timezone too...  \n ${NO}"
cat /etc/timezone

echo -en "${STEP}\n  Generating locals ${DONE} "
grep -v '^#' /etc/locale.gen
echo -e "${NO}"
locale-gen

echo -e "${STEP}\n  Adjusting default local too...   ${NO}"
eselect locale list

echo -e "${STEP}\n  Now reload the environment ${NO}"
env-update && source /etc/profile

echo -e "${STEP}\n  Checking/Adjusting gcc verions ${NO}"
CURRENT_VERSION=gcc-`gcc --version | grep gcc | cut -d" " -f3`
PORTAGE_VERSION=`emerge -pv sys-devel/gcc | grep gcc- | cut -d"/" -f2 | cut -d":" -f1`
echo "    CURRENT_VERSION is $CURRENT_VERSION"
echo "    PORTAGE_VERSION is $PORTAGE_VERSION"
sed -i "s/GCC_VERSION/$PORTAGE_VERSION/g" /etc/portage/make.conf

if [ "$CURRENT_VERSION" != "$PORTAGE_VERSION" ] || [ "$REBUILD_GCC" = "yes" ]; then
  echo -e "${STEP}\n  emerge --oneshot sys-devel/gcc  ${NO}"
  start_time=$(date)
  emerge ${JOBS} --oneshot sys-devel/gcc --quiet-build
  echo; echo $start_time
  echo $(date); echo
  if [ "$CURRENT_VERSION" != "$PORTAGE_VERSION" ]; then
    gcc-config --list-profiles
    gcc-config 2
  fi
  rm -v $PKGDIR/$PORTAGE_VERSION.*
  source /etc/profile
  emerge --oneshot --usepkg=n sys-devel/libtool --quiet-build
  REBUILD_SYSTEM=yes
  echo; echo $start_time
  echo $(date); echo
fi

echo -e "${STEP}\n  Emerging kernel sources  ${NO}"
if [ "$USE_FOUNDATION_SOURES" = "yes" ]; then
  emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/raspberrypi-sources --quiet-build
else
  emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/gentoo-sources --quiet-build
fi

start_time=$(date)
if [ "$REBUILD_SYSTEM" = "yes" ]; then
  echo -e "${STEP}\n  emerge @system  ${NO}"
  emerge @system --quiet-build
  echo -e "${STEP}\n  emerge -vuDU --with-bdeps=y @world  ${NO}"
  emerge -vuDU --with-bdeps=y @world --quiet-build
else
  echo -e "${STEP}\n  emerge ${USE_BINS} ${USE_BINHOST} -vuDU --with-bdeps=y @world  ${NO}"
  emerge ${USE_BINS} ${USE_BINHOST} -vuDU --with-bdeps=y @world --quiet-build
fi
echo; echo $start_time
echo $(date); echo
#etc-update

echo -e "${STEP}\n  emerge ${USE_BINS} ${USE_BINHOST} gentoolkit  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} app-portage/gentoolkit --quiet-build

echo -e "${STEP}\n  System logger syslog-ng  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} app-admin/syslog-ng app-admin/logrotate --quiet-build
sed -i 's/#rc_logger="NO"/rc_logger="YES"/' /etc/rc.conf
sed -i 's|#rc_log_path="/var/log/rc.log"|rc_log_path="/var/log/rc.log"|' /etc/rc.conf
rc-update add sshd default

echo -e "${STEP}\n  Cron daemon dcron  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-process/cronie --quiet-build
rc-update add cronie default

echo -e "${STEP}\n  File indexing  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-apps/mlocate --quiet-build

#echo -e "${STEP}\n  Automatically start networking at boot  ${NO}"
##cd /etc/init.d
#pushd /etc/init.d
#ln -sv net.lo net.eth0
#popd
#rc-update add net.eth0 default

echo -e "${STEP}\n  Setting up ${DONE}ssh  ${NO}"
sed -i 's/.*PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
grep "PermitRootLogin " /etc/ssh/sshd_config
echo -e "${STEP}    generating keys \n ${NO}"
/usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ""
/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
/usr/bin/ssh-keygen -t ed25519 -a 100 -f /etc/ssh/ssh_host_ed25519_key -N ""
#/usr/bin/ssh-keygen -t rsa -b 4096 -o -a 100 -f /etc/ssh/ssh_host_rsa_key -N ""
rc-update add sshd default
cat /etc/ssh/sshd_config | grep PermitRootLogin

echo -e "${STEP}\n  Setting up the root password... ${DONE} $root_password ${NO} "
echo root:$root_password | chpasswd

echo -e "${STEP}\n  Installing a DHCP client  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-misc/dhcpcd --quiet-build

echo -e "${STEP}\n  Install wireless-regdb  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/wireless-regdb --quiet-build

echo -e "${STEP}\n  Install wpa_supplicant  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/wpa_supplicant --quiet-build
rc-update -v add wpa_supplicant
rc-update -v add wifi boot

echo -e "${STEP}\n  Install wireless networking tools  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/iw --quiet-build

if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ] \
		 || [ "$BOARD" = "pi3-64" ] || [ "$BOARD" = "pi4-64" ]; then
  echo -e "${STEP}\n  Installing ${DONE} ${BOARD} ${STEP} stuff ${NO}"
  if [ "$USE_FOUNDATION_PRE_COMPILE" = "yes" ]; then
    echo -e "${STEP}\n  Installing sys-kernel/raspberrypi-image  ${NO}"
    emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/raspberrypi-image --quiet-build
    #emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/raspberrypi-image --autounmask-write --quiet-build
    KERNEL=$(ls /lib/modules | grep v8+ | cut -d"-" -f1 | awk '{print$1}')
    echo -e "${STEP}      Crud Removal for kernel  ${DONE} ${BOARD} ${KERNEL}  ${NO}"
    if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ]; then
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
    echo -en "${STEP}    Modules that are left are  ${DONE}"; ls /lib/modules; echo -e "${NO}"
  else
    echo -e "${STEP}\n  Installing sys-boot/raspberrypi-firmware  ${NO}"
    emerge sys-boot/raspberrypi-firmware --quiet-build
  fi
  echo -e "${STEP}    More Crud Removal  ${NO}"
  if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ]; then
    rm -v /boot/{fixup4.dat,fixup4x.dat,fixup4cd.dat,fixup4db.dat}
    rm -v /boot/{start4.elf,start4x.elf,start4cd.elf,start4db.elf}
  else
    rm -v /boot/{bootcode.bin,fixup.dat,fixup_x.dat,fixup_cd.dat,fixup_db.dat}
    rm -v /boot/{start.elf,start_x.elf,start_cd.elf,start_db.elf}
  fi
  echo -e "${STEP}\n  Reading news  ${NO}"
  eselect news read new

  echo -e "${STEP}\n  Installing sys-firmware/raspberrypi-wifi-ucode  ${NO}"
  emerge sys-firmware/raspberrypi-wifi-ucode --quiet-build
  echo -e "${STEP}\n  Installing media-libs/raspberrypi-userland  ${NO}"
  emerge ${USE_BINS} ${USE_BINHOST} media-libs/raspberrypi-userland --quiet-build
  # emerge ${USE_BINS} ${USE_BINHOST} -pv sys-kernel/raspberrypi-sources
fi

echo -e "${STEP}\n  Installing git  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} dev-vcs/git --quiet-build

echo -e "${STEP}\n  Installing sys-fs/growpart   ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-fs/growpart --nodeps --quiet-build
rc-update add growpart boot

echo -e "${STEP}\n  Installing dphys-swapfile  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-apps/dphys-swapfile --quiet-build
sed "s/#CONF_SWAPSIZE=/CONF_SWAPSIZE=$swap_size/g" -i /etc/dphys-swapfile
grep 'CONF_SWAPSIZE=' /etc/dphys-swapfile
rc-update -v add dphys-swapfile default


echo -e "${STEP}\n  Sync'n  ${NO}"
sync

echo -e "${STEP}\n  Checking Install size  ${NO}"
df -h

exit 0
