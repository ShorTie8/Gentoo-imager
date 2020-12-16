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
  echo -e "${STEP}\n  Nuffin to do, using portage-latest, moving right along  ${NO}"
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

echo -en "${STEP}\n  Generating locals  ${NO}"
echo -en "${STEP}\n    Checking /etc/locale.gen \n ${NO}"
grep -v '^#' /etc/locale.gen
locale-gen

echo -en "${STEP}\n  Adjusting default local too...   ${NO}"
eselect locale list

echo -e "${STEP}\n  Now reload the environment ${NO}"
env-update && source /etc/profile

echo -e "${STEP}\n  Automatically start networking at boot  ${NO}"
cd /etc/init.d
ln -sv net.lo net.eth0
rc-update add net.eth0 default

echo -e "${STEP}\n  Setting up the root password... ${DONE} $root_password ${NO} "
echo root:$root_password | chpasswd

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
  gcc-config --list-profiles
  gcc-config 2
  source /etc/profile
  emerge --oneshot --usepkg=n sys-devel/libtool --quiet-build
  REBUILD_SYSTEM=yes
  echo; echo $start_time
  echo $(date); echo
fi

echo -e "${STEP}\n  Emerging kernel sources  ${NO}"
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi4" ] && [ "$USE_FOUNDATION_SOURES" = "yes" ]; then
  #emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/raspberrypi-sources --quiet-build
  emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/gentoo-sources --quiet-build
#pushd /usr/src
#ln -sv  linux-* linux 
#popd
else
  emerge ${USE_BINS} ${USE_BINHOST} sys-kernel/gentoo-sources --quiet-build
fi

if [ "$REBUILD_SYSTEM" = "yes" ]; then
  echo -e "${STEP}\n  emerge ${USE_BINS} ${USE_BINHOST} @system  ${NO}"
  start_time=$(date)
  emerge ${USE_BINS} ${USE_BINHOST} @system --quiet-build
  echo; echo $start_time
  echo $(date); echo
fi

echo -e "${STEP}\n  emerge ${USE_BINS} ${USE_BINHOST} -vuDU --with-bdeps=y @world  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} -vuDU --with-bdeps=y @world --quiet-build

#echo -e "${STEP}\n  emerge --depclean \n ${NO}"
#emerge --depclean

echo -e "${STEP}\n  emerge ${USE_BINS} ${USE_BINHOST} gentoolkit  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} app-portage/gentoolkit --quiet-build

echo -e "${STEP}\n  System logger syslog-ng  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} app-admin/syslog-ng app-admin/logrotate --quiet-build
sed -i 's/#rc_logger="NO"/rc_logger="YES"/' /etc/rc.conf
sed -i 's/#rc_log_path="/var/log/rc.log"/rc_log_path="/var/log/rc.log"/' /etc/rc.conf
rc-update add sshd default

echo -e "${STEP}\n  Cron daemon dcron  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-process/cronie --quiet-build
rc-update add cronie default

echo -e "${STEP}\n  File indexing  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} sys-apps/mlocate --quiet-build

echo -e "${STEP}\n  Setting up ${DONE}ssh  ${NO}"
sed -i 's/.*PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo -e "${STEP}    generating keys \n ${NO}"
/usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ""
/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
/usr/bin/ssh-keygen -t ed25519 -a 100 -f /etc/ssh/ssh_host_ed25519_key -N ""
#/usr/bin/ssh-keygen -t rsa -b 4096 -o -a 100 -f /etc/ssh/ssh_host_rsa_key -N ""
rc-update add sshd default
cat /etc/ssh/sshd_config | grep PermitRootLogin

echo -e "${STEP}\n  Installing a DHCP client  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-misc/dhcpcd --quiet-build

echo -e "${STEP}\n  Install wireless-regdb  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/wireless-regdb --quiet-build

echo -e "${STEP}\n  Install wpa_supplicant  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/wpa_supplicant --quiet-build

echo -e "${STEP}\n  Install wireless networking tools  ${NO}"
emerge ${USE_BINS} ${USE_BINHOST} net-wireless/iw --quiet-build

if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi4" ]; then
  echo -e "${STEP}\n  Installing sys-apps/pv  ${NO}"
  emerge ${USE_BINS} ${USE_BINHOST} sys-apps/pv --quiet-build
  echo -e "${STEP}\n    Extracting Raspiberry pi kernel $DEB_VERSION ${NO}"
  bash /root/update_kernel.sh
  echo -e "${STEP}\n  Installing sys-boot/raspberrypi-firmware  ${NO}"
  emerge sys-boot/raspberrypi-firmware --quiet-build
  echo -e "${STEP}\n    Crud Removal  ${NO}"
  if [ "$BOARD" = "pi" ]; then
    rm -v /boot/{fixup4.dat,fixup4x.dat,fixup4cd.dat,fixup4db.dat}
    rm -v /boot/{start4.elf,start4x.elf,start4cd.elf,start4db.elf}
  else
    rm -v /boot/{bootcode.bin,fixup.dat,fixup_x.dat,fixup_cd.dat,fixup_db.dat}
    rm -v /boot/{start.elf,start_x.elf,start_cd.elf,start_db.elf}
  fi
  echo -e "${STEP}\n  Installing sys-firmware/raspberrypi-wifi-ucode  ${NO}"
  emerge sys-firmware/raspberrypi-wifi-ucode --quiet-build
  echo -e "${STEP}\n  Installing media-libs/raspberrypi-userland  ${NO}"
  emerge ${USE_BINS} ${USE_BINHOST} media-libs/raspberrypi-userland --quiet-build
  # emerge ${USE_BINS} ${USE_BINHOST} -pv sys-kernel/raspberrypi-sources
fi

echo -e "${STEP}\n  Adding growpart.init in   ${NO}"
rc-update add growpart boot

echo -e "${STEP}\n  Adding dphys-swapfile.init in   ${NO}"
rc-update add dphys-swapfile default

echo -e "${STEP}\n  Sync'n  ${NO}"
sync

echo -e "${STEP}\n  Checking Install size  ${NO}"
df -h

exit 0
