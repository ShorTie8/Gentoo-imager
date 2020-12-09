#!/bin/bash
# A simple script to make your own Gentoo Images
#
# BeerWare By ShorTie	<idiot@dot.com> 
#
# This work is too trival to have any copyrights.
# So, I hereby wave any copyrights,
#	and there for release it into the Public Domain.

hostname=tux
root_password=root

#	# Currently supported boards, it's all I got .. :/~
#BOARD=pi
BOARD=pi4
#BOARD=rock64

#	# This is for pi boards and the foudation kernel
	# USE_FOUNDATION_PRE_COMPILE will use thier deb
	# else sys-kernel/gentoo-sources will be used
USE_FOUNDATION_SOURES=yes
USE_FOUNDATION_PRE_COMPILE=yes
DEB_VERSION=raspberrypi-kernel_1.20201022-1_arm64.deb

#	# This proforms a emerge @system if you want
	# which will optimize gcc for your board
	# just rem out if you do not wish to do this
REBUILD_GCC=yes

#	# Define your cpu and common flags
	# format will be COMMON_FLAGS="${CPU} ${COMMON_FLAGS}"
	# https://wiki.gentoo.org/wiki/Safe_CFLAGS#ARMv8-A.2FBCM2837
#CPU="-march=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
#CPU="--with-cpu=cortex-a53 --with-fpu=neon-fp-armv8 --with-float=hard"
#CPU="--with-cpu=cortex-a72 --with-fpu=vfp --with-float=hard --enable-linker-build-id"
#CPU="--with-cpu=cortex-a15 --with-cpu=cortex-a7 --with-fpu=vfpv3-d16 --with-float=hard "

CPU="-march=armv8-a+crc -mtune=cortex-a72"
#COMMON_FLAGS="-O2 -pipe"
COMMON_FLAGS="-O3 -pipe -fPIC"

#	# This will use roy's binhost if you wish, or any other if added/changed
	# Many Thankz goes out to Mr.Roy
#USE_BINHOST=--getbinpkg
BIN_HOST_URL=http://bloodnoc.org/~roy/BINHOSTS/gcc-10.x/armv8a/

#	# These will create/use binary packages 
CREATE_BINS=yes
USE_BINS=--usepkg

#	# To add the ACCEPT_KEYWORDS ~$ARCH  setting to /etc/portage/make.conf
ACCEPT_KEYWORDS=yes

PROFILE=17.0
USE=""

timezone=America/New_York
locales="en_US.UTF-8 UTF-8"
default_locale=en_US.UTF-8

#	# saves any distfiles downloaded
save_files=yes

number_of_keys="104"	# You can define this here or remark out or leave blank to use current systems
keyboard_layout="us"	# must be defined if number_of_keys is defined
keyboard_variant=""		# blank is normal
keyboard_options=""		# blank is normal
backspace="guess"		# guess is normal

#USE_PORTAGE_LATEST=yes

#	###################################  End Configuration  #########################################

DATE=$(date +"%Y%m%d")

# Define message colors
OOPS="\033[1;31m"    # red
DONE="\033[1;32m"    # green
INFO="\033[1;33m"    # yellow
STEP="\033[1;34m"    # blue
WARN="\033[1;35m"    # hot pink
BOUL="\033[1;36m"	 # light blue
NO="\033[0m"         # normal/light

echo -e "${STEP}\n  Setting ARCH ${NO}"
if [ "$1" = "armv4tl" ] || [ `uname -m` = "armv4tl" ]; then
    ARCH=armv4tl
elif [ "$1" = "armv5tel" ] || [ `uname -m` = "armv5tel" ]; then
    ARCH=armv5tel
elif [ "$1" = "armv6j" ] || [ `uname -m` = "armv6j" ]; then
    ARCH=armv6j_hardfp
elif [ "$1" = "armv7a" ] || [ `uname -m` = "armv7a" ]; then
    ARCH=armv7a_hardfp
elif [ `uname -m` = "aarch64" ]; then
    ARCH=arm64
elif [ "$1" = "i486" ] || [ `uname -m` = "i486" ]; then
    ARCH=i486
elif [ "$1" = "i686" ] || [ `uname -m` = "i686" ]; then
    ARCH=i686
elif [ `uname -m` = "amd64" ]; then
    ARCH=amd64
else
    echo "So, So, Sorry ,, ;(~"
    echo "Unsupported ARCH"
    exit 1
fi
echo -e "${STEP}  Building for ${DONE}${BOARD} ${STEP}for arch ${DONE}${ARCH} ${NO}"

# Define our oops and set trap
fail () {
    echo -e "${WARN}\n\n  Oh no's,${INFO} Sumfin went wrong\n ${NO}"
    echo -e "${STEP}  Cleaning up my mess .. ${OOPS}:(~ ${NO}"
    umount sdcard/dev
    umount sdcard/proc
    umount sdcard/sys
    umount sdcard/dev/pts
    #umount sdcard/tmp
    fuser -av sdcard
    fuser -kv sdcard
    umount sdcard/boot
    fuser -k sdcard
    umount sdcard
    kpartx -dv Image
    rm -rf sdcard
  #  rm Image
    exit 1
}

echo -e "${STEP}  Setting Trap ${NO}"
trap "echo; echo \"Unmounting /proc\"; fail" SIGINT SIGTERM

# Check to see if Gentoo-imager.sh is being run as root
start_time=$(date)
echo -e "${STEP}\n  Checking for root .. ${NO}"
if [ `id -u` != 0 ]; then
    echo "nop"
    echo -e "Ooops, Gentoo-imager.sh needs to be run as root !!\n"
    echo " Try 'sudo sh, ./Gentoo-imager.sh' as a user maybe"
    exit
else
    echo -e "${INFO}Yuppers,${BOUL} root it tis ..${DONE} :)~${NO}"
fi

if [ ! -e files/Dependencies-ok ]; then
  echo -e "${STEP}\n  Installing dependencies ..  ${NO}"
    if [ -f /etc/gentoo-release ]; then
      emerge sys-fs/dosfstools sys-fs/multipath-tools sys-apps/pv --quiet-build || fail
    else
      apt install binutils dosfstools file kpartx libc6-dev parted psmisc pv xz-utils || fail
    fi
  touch files/Dependencies-ok
fi

echo -e "${INFO}\n  Making sure of a kleen enviroment .. ${BOUL}:/~ ${NO}"
umount sdcard/dev
umount sdcard/proc
umount sdcard/sys
umount sdcard/dev/pts
#umount sdcard/tmp
fuser -av sdcard
fuser -kv sdcard
umount sdcard/boot
fuser -k sdcard
umount sdcard
kpartx -dv Image
rm -rvf sdcard
#rm Image

if [ ! -d files ]; then
  echo -e "${STEP}\n  Making files Directory ${NO}"
  mkdir -p files
fi

#	#######################################  Downloads  #############################################
echo -e "${STEP}\n  Checkin for ${DONE}$ARCH ${STEP} stage3 tarball ${NO}"
#	# For i486, i686 && amd64
RELEASE_DATE=20201130T214503Z
RELEASE_DATE_64=20201130T214503Z
RELEASE_DATE_arm=20201130T214503Z
RELEASE_DATE_arm64=20201004T190540Z

if [ "$ARCH" = "armv4tl" ] || [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv6j_hardfp" ] || [ "$ARCH" = "armv7a_hardfp" ] && [ ! -f files/stage3-${ARCH}-${RELEASE_DATE_arm}.tar.xz ]; then
  echo -e "${STEP}    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/arm/autobuilds/${RELEASE_DATE_arm}/stage3-${ARCH}-${RELEASE_DATE_arm}.tar.xz || fail

elif [ "$ARCH" = "arm64" ] && [ ! -f files/stage3-arm64-${RELEASE_DATE_arm64}.tar.xz ]; then
  echo -e "${STEP}    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64/stage3-arm64-${RELEASE_DATE_arm64}.tar.xz || fail

elif [ "$ARCH" = "i486" ] || [ "$ARCH" = "i686" ] && [ ! -f files/stage3-${ARCH}-${RELEASE_DATE}.tar.xz ]; then
  echo -e "${STEP}    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/x86/autobuilds/${RELEASE_DATE}/stage3-${ARCH}-${RELEASE_DATE}.tar.xz || fail

elif [ "$ARCH" = "amd64" ] && [ ! -f files/stage3-amd64-${RELEASE_DATE_64}.tar.xz ]; then
  echo -e "${STEP}    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/amd64/autobuilds/${RELEASE_DATE_64}/stage3-amd64-${RELEASE_DATE_64}.tar.xz || fail
fi

if [ "$USE_PORTAGE_LATEST" = "yes" ]; then
  echo -e "${STEP}\n    Downloadin portage-latest tarball ${NO}"
  wget -N -P files http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz || fail
  wget -N -P files http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz.gpgsig || fail
  wget -N -P files http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz.md5sum || fail
fi


#	#################################  Board specific Downloads  ####################################
echo -e "${STEP}   Checking ${DONE}${BOARD} ${STEP}stuff ${NO}"
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi4" ]; then
  if [ ! -f files/$DEB_VERSION ] && [ "$USE_FOUNDATION_PRE_COMPILE" = "yes" ]; then
    echo -e "${STEP}    Downloadin Raspiberry pi kernel tarball ${NO}"
    wget -P files http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/${DEB_VERSION} || fail
  fi
  if [ ! -d files/boot_files/${BOARD}/${ARCH} ]; then
    mkdir -vp files/boot_files/${BOARD}/${ARCH}
  fi
   if [ ! -d files/boot_files/${BOARD}/${ARCH} ]; then
    if [ "$ARCH" = "arm" ]; then
      echo -e "${STEP}      Getting ${ARCH} boot files ${NO}"
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/LICENCE.broadcom  -O files/boot_files/${BOARD}/${ARCH}/LICENCE.broadcom || fail
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/bootcode.bin  -O files/boot_files/${BOARD}/${ARCH}/bootcode.bin || fail
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/fixup.dat  -O files/boot_files/${BOARD}/${ARCH}/fixup.dat || fail
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/start.elf  -O files/boot_files/${BOARD}/${ARCH}/start.elf || fail
    else
      echo -e "${STEP}      Getting ${ARCH} boot files ${NO}"
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/LICENCE.broadcom  -O files/boot_files/${BOARD}/${ARCH}/LICENCE.broadcom || fail
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/fixup4.dat  -O files/boot_files/${BOARD}/${ARCH}/fixup4.dat || fail
      wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/start4.elf  -O files/boot_files/${BOARD}/${ARCH}/start4.elf || fail
    fi
  fi
  if [ ! -d files/${BOARD}/wifi_extras ]; then
    echo -e "${STEP}      Getting wifi files ${NO}"
    mkdir -vp files/${BOARD}/wifi_extras
    wget  https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.bin -O files/${BOARD}/wifi_extras/brcmfmac43455-sdio.bin || fail
    wget  https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.clm_blob -O files/${BOARD}/wifi_extras/brcmfmac43455-sdio.clm_blob || fail
    wget  https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm/brcmfmac43455-sdio.txt -O files/${BOARD}/wifi_extras/brcmfmac43455-sdio.txt || fail
  fi

  if [ ! -f files/boot_files/${BOARD}/${ARCH}/config.txt ]; then
    echo -e "${STEP}      Downloading config.txt ${NO}"
    if [ "$ARCH" = "arm" ]; then
      wget https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage1/00-boot-files/files/config.txt -O files/boot_files/${BOARD}/${ARCH}/config.txt || fail
    else
      wget https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage1/00-boot-files/files/config.txt || fail
      sed '4 i #dtoverlay=sdtweak,poll_once=on' config.txt > config.txt.new
      sed '4 i #dtoverlay=i2c-rtc,ds3231' config.txt.new > config.txt.new.1
      sed '4 i dtoverlay=i2c-rtc,ds1307' config.txt.new.1 > config.txt.new.2
      sed '4 i dtparam=random=on' config.txt.new.2 > config.txt.new.3
      sed '4 i arm_64bit=1' config.txt.new.3 > config.txt.new.4
      sed '/Some settings/G' config.txt.new.4 > config.txt.new.5
      sed '4 i #initramfs initrd-UNAME.gz' config.txt.new.5 > config.txt.new.6
      sed '4 i #kernel=vmlinux-UNAME.img' config.txt.new.6 > config.txt.new.7
      sed '/Some settings/G' config.txt.new.7 > files/boot_files/${BOARD}/${ARCH}/config.txt
      rm -v config.txt config.txt.new config.txt.new.*
      #sed -i 's/#hdmi_safe=1/#hdmi_safe=1/' debs/config.arm64
      #sed -i 's/#hdmi_group=1/hdmi_group=1/' arm64/config.arm64
      #sed -i 's/#hdmi_mode=1/hdmi_mode=4/' arm64/config.arm64
      #sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' arm64/config.arm64
      # dtparam=sd_poll_once
    fi
  fi

elif [ "$BOARD" = "rock64" ]; then
  echo -e "${STEP}\   Checking ${DONE}${BOARD} ${STEP}stuff ${NO}"
  if [ ! -d files/boot_files/${BOARD}/${ARCH} ]; then
    mkdir -vp files/boot_files/${BOARD}/${ARCH}
  fi
  echo "Nuffin yet dum dum !!"

#	# add more board stuff here as elif
#elif [ "$BOARD" = "Odroid" ]; then

fi

#	#####################################  End Downloads  ###########################################

#	#####  Creating Image file, partition, setup drive mapper, format and mount rootpart  ###########

echo -e "${DONE}\n  Creating Image ${NO}"
if [ ! -f Image ]; then
  echo -e "${STEP}    Creating a zero-filled file ${NO}"
  if [ "$my_DESKTOP" = "yes" ]; then
    dd if=/dev/zero of=Image  bs=1M  count=6420 iflag=fullblock
  else
    dd if=/dev/zero of=Image  bs=1M  count=16420 iflag=fullblock
  fi
fi

# Create partitions
echo -e "${STEP}    Creating partitions ${NO}"
fdisk Image <<EOF
o
n
p
1

+256M
a
t
b
n
p
2


w
EOF

echo -e "${STEP}\n  Setting up drive mapper ${NO}"
loop_device=$(losetup --show -f Image) || fail

echo -e "${STEP}    Loop device is ${DONE} $loop_device ${NO}"
echo -e "${STEP}    Partprobing $loop_device ${NO}"
partprobe ${loop_device}
bootpart=${loop_device}p1
rootpart=${loop_device}p2
echo -e "${STEP}      Boot partition is ${DONE} $bootpart ${NO}"
echo -e "${STEP}      Root partition is ${DONE} $rootpart ${NO}"

# Format partitions
echo -e "${STEP}    Formating partitions ${NO}"
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi4" ]; then
  echo "mkfs.vfat -n boot $bootpart"
  mkfs.vfat -n BOOT $bootpart
else
  echo "mkfs.ext4 -O ^huge_file  -L Gentoo $bootpart"; echo
  echo y | mkfs.ext4 -O ^huge_file  -L Gentoo $bootpart && sync
fi
echo
echo "mkfs.ext4 -O ^huge_file  -L Gentoo $rootpart"; echo
echo y | mkfs.ext4 -O ^huge_file  -L Gentoo $rootpart && sync
echo

P1_UUID="$(lsblk -o PTUUID "${loop_device}" | sed -n 2p)-01"
P2_UUID="$(lsblk -o PTUUID "${loop_device}" | sed -n 2p)-02"
echo "P1_UUID = ${P1_UUID}"
echo "P2_UUID = ${P2_UUID}"

echo -e "${STEP}\n  Setting up for ${DONE}Stage 3 ${STEP}Install ${NO}"
mkdir -v sdcard
mount -v -t ext4 -o sync $rootpart sdcard

#	###########################  Extracting Stage 3 tarball   #######################################
echo -e "${STEP}      Extracting Stage 3 tarball for ${DONE}${ARCH} ${NO}"
if [ "$ARCH" = "armv4tl" ] || [ "$ARCH" = "armv5tel" ] || [ "$ARCH" = "armv6j_hardfp" ] || [ "$ARCH" = "armv7a_hardfp" ]; then
  pv files/stage3-${ARCH}-${RELEASE_DATE_arm}.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
elif [ "$ARCH" = "arm64" ]; then
  pv files/stage3-arm64-${RELEASE_DATE_arm64}.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
elif [ "$ARCH" = "i486" ] || [ "$ARCH" = "i686" ]; then
  pv files/stage3-${ARCH}-${RELEASE_DATE}.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
elif [ "$ARCH" = "amd64" ]; then
  pv files/stage3-amd64-${RELEASE_DATE_64}.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
else
  echo "${OOPS}So, So, Sorry${NO}"
  echo "  Ain't got no stage 3 tarball for ${DONE}$ARCH ${NO} " 
  fail
fi

if [ "$USE_BINS" = "--usepkg" ] || [ "$USE_BINHOST" = "--getbinpkg" ]; then
  echo -e "${STEP}    Coping bin files ${NO}"
  cp -vR binpkgs/* sdcard/var/cache/binpkgs
fi

if [ "$USE_PORTAGE_LATEST" = "yes" ]; then
  echo -e "${STEP}    Installing ${DONE}portage-latest ${NO}"
  pv files/portage-latest.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard/usr || fail
  chown -v -R portage:portage sdcard/usr/portage
  echo -e "${STEP}      Setting up profile ${NO}"
  mv sdcard/usr/portage/profiles sdcard/var/db/repos/gentoo
  ##mkdir -vp sdcard/var/db/repos/gentoo/profiles
  ##cp -aR sdcard/usr/portage/profiles/* sdcard/var/db/repos/gentoo/profiles
  ##chroot sdcard/etc/portage /bin/ln -sv ../../var/db/repos/gentoo/profiles/default/linux/arm64/17.1 make.profile
  ##ls -l make.profile
  ##mv make.profile make.profile.orig
  ##ln -svf ../../usr/portage/profiles/default/linux/${ARCH}/${PROFILE} make.profile
  pushd sdcard/etc/portage
  ln -svf ../../var/db/repos/gentoo/profiles/default/linux/${ARCH}/${PROFILE} make.profile
  popd
fi


#	#################################  Creating make.conf   #########################################
echo -e "${STEP}\n  Playing make.conf ${NO}"
cp -v sdcard/etc/portage/make.conf sdcard/etc/portage/make.conf-orig
sed -i 's/COMMON_FLAGS="-O2 -pipe"/#COMMON_FLAGS="-O2 -pipe"/' sdcard/etc/portage/make.conf
sed '6 i COMMON_FLAGS="'"${CPU}"' '"${COMMON_FLAGS}"'"' sdcard/etc/portage/make.conf > sdcard/etc/portage/make.conf.1
rm -v sdcard/etc/portage/make.conf
if [ "$ACCEPT_KEYWORDS" = "yes" ]; then
  if [ "$ARCH" = "arm" ]; then
    sed '15 i ACCEPT_KEYWORDS="~arm"' sdcard/etc/portage/make.conf.1 > sdcard/etc/portage/make.conf.2
  elif [ "$ARCH" = "arm64" ]; then
    sed '15 i ACCEPT_KEYWORDS="~arm64"' sdcard/etc/portage/make.conf.1 > sdcard/etc/portage/make.conf.2
  elif [ "$ARCH" = "x86" ]; then
    sed '15 i ACCEPT_KEYWORDS="~x86"' sdcard/etc/portage/make.conf.1 > sdcard/etc/portage/make.conf.2
  elif [ "$ARCH" = "amd64" ]; then
    sed '15 i ACCEPT_KEYWORDS="~amd64"' sdcard/etc/portage/make.conf.1 > sdcard/etc/portage/make.conf.2
  fi
else
  cp -v sdcard/etc/portage/make.conf.1 sdcard/etc/portage/make.conf.2
fi
sed '16 i CONFIG_PROTECT="/var/bind"' sdcard/etc/portage/make.conf.2 > sdcard/etc/portage/make.conf.3
sed '17 i PORT_LOGDIR="/var/log/portage/"' sdcard/etc/portage/make.conf.3 > sdcard/etc/portage/make.conf.4
sed '/PORT_LOGDIR/G' sdcard/etc/portage/make.conf.4 > sdcard/etc/portage/make.conf
rm -v sdcard/etc/portage/make.conf.*
echo "" >> sdcard/etc/portage/make.conf
if [ "$CREATE_BINS" = "yes" ]; then
  echo "FEATURES=\"buildpkg\"" >> sdcard/etc/portage/make.conf
fi
echo "PORTAGE_BINHOST=\"$BIN_HOST_URL\"" >> sdcard/etc/portage/make.conf
echo "" >> sdcard/etc/portage/make.conf
echo; cat sdcard/etc/portage/make.conf

#	#################################  Creating board.conf  #########################################
echo -e "${STEP}\n  Creating board.conf ${NO}"
tee sdcard/etc/portage/board.conf <<EOF
# This file automagically created by Gentoo-imager.sh for Gentoo-install.sh
BOARD=$BOARD
REBUILD_GCC=$REBUILD_GCC
ACCEPT_KEYWORDS=$ACCEPT_KEYWORDS
USE_PORTAGE_LATEST=$USE_PORTAGE_LATEST
USE_BINS=$USE_BINS
USE_BINHOST=$USE_BINHOST

hostname=$hostname

EOF

#	#################  Copying gentoo.conf adjust and configure some stuff  #########################
echo -e "${STEP}\n  Copying gentoo.conf ${NO}"
mkdir -vp sdcard/etc/portage/repos.conf
cp -v sdcard/usr/share/portage/config/repos.conf sdcard/etc/portage/repos.conf/gentoo.conf
#cat sdcard/etc/portage/repos.conf/gentoo.conf

echo -e "${STEP}\n  Copy DNS info ${NO}"
cp -v --dereference /etc/resolv.conf sdcard/etc/

echo -en "${STEP}\n  Changing timezone too...   ${timezone} \n  ${NO}"
echo ${timezone} > sdcard/etc/timezone
cat sdcard/etc/timezone

echo -en "${STEP}\n  Adjusting locales too... ${DONE}$locales  ${NO}"
sed -i "s|#$locales|$locales|g" sdcard/etc/locale.gen
grep -v '^#' sdcard/etc/locale.gen

echo -en "${STEP}\n  Adjusting default local too...  ${default_locale} \n ${NO}"
tee sdcard/etc/env.d/02locale <<EOF
LANG="${default_locale}"
LC_COLLATE="C"

EOF

echo -e "${STEP}\n  Setting up networking ${NO}"
tee sdcard/etc/conf.d/hostname <<EOF
# Set the hostname variable to the selected host name
hostname="#hostname"

EOF

echo
tee sdcard/etc/conf.d/net <<EOF
# Set the dns_domain_lo variable to the selected domain name
dns_domain_lo="homenetwork"

# Set the nis_domain_lo variable to the selected NIS domain name
#nis_domain_lo="my-nisdomain"

# DHCP definition
config_eth0="dhcp"

# Static IP definition
#config_eth0="192.168.0.2 netmask 255.255.255.0 brd 192.168.0.255"
#routes_eth0="default via 192.168.0.1"

EOF

echo
tee sdcard/etc/hosts <<EOF
# This defines the current system and must be set
127.0.0.1     tux.homenetwork tux localhost

EOF

echo -e "${STEP}\n  set hwclock to clock=local \n ${NO}"
sed -i 's/clock="UTC"/clock="local"/' sdcard/etc/conf.d/hwclock
grep "clock=" sdcard/etc/conf.d/hwclock

echo -e "${STEP}\n\n  Creating fstab ${NO}"
cp -v sdcard/etc/fstab sdcard/etc/fstab.orig
tee sdcard/etc/fstab <<EOF
#<file system>  <dir>          <type>   <options>       <dump>  <pass>
proc            /proc           proc    defaults          0       0
PARTUUID=${P1_UUID}  /boot           vfat    defaults          0       2
PARTUUID=${P2_UUID}  /               ext4    defaults,noatime  0       1

EOF

if [ -d distfiles ]; then
  echo -e "${STEP}\n  Coping distfiles over to sdcard \n ${NO}"
  cp distfiles/* sdcard/var/cache/distfiles
fi

echo -e "${STEP}\n  Copy Gentoo-imager.sh files \n ${NO}"
install -v -m 0755 -D Gentoo-imager.sh sdcard/root/Gentoo-imager/Gentoo-imager.sh
install -v -m 0755 Gentoo-install.sh sdcard/root/Gentoo-imager/Gentoo-install.sh
install -v -m 0644 READme sdcard/root/Gentoo-imager
install -v -m 0644 growpart/growpart sdcard/root/Gentoo-imager
install -v -m 0644 growpart/growpart.init sdcard/root/Gentoo-imager
install -v -m 0755 growpart/growpart sdcard/usr/bin/growpart
install -v -m 0755 growpart/growpart.init sdcard/etc/init.d/growpart
install -v -m 0755 dphys-swapfile/dphys-swapfile sdcard/sbin/dphys-swapfile
install -v -m 0755 dphys-swapfile/dphys-swapfile.init sdcard/etc/init.d/dphys-swapfile
install -v -m 0644 dphys-swapfile/dphys-swapfile.conf sdcard/etc/dphys-swapfile
echo "And .git"
cp -aR .git sdcard/root/Gentoo-imager/.git

#	#####################  Mounting the boot partition and copy stuff  ##############################
echo -e "${STEP}\n  Mounting the boot partition\n ${NO}"
mount -v -t vfat -o sync $bootpart sdcard/boot

if [ -f wpa_supplicant.conf ]; then
  echo -e "${STEP}\n  Coping wpa_supplicant.conf over to sdcard \n ${NO}"
  cp -v wpa_supplicant.conf sdcard/boot/wpa_supplicant.conf
fi


#	#########################################  Foundation's stuff  #################################
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi4" ]; then
  echo -e "${STEP}\n  Doing a  Raspiberry ${DONE}$BOARD${STEP} install ${NO}"
#  <gavlee> ShorTie: have to add the licenses to /etc/portage/package.license ... something like "sys-boot/raspberrypi-firmware raspberrypi-videocore-bin" in there (without quotes)


  echo -e "${STEP}    Adding stuff to package.license ${NO}"
  echo "media-libs/raspberrypi-userland-bin raspberrypi-videocore-bin" >> sdcard/etc/portage/package.license
  echo "sys-boot/raspberrypi-firmware raspberrypi-videocore-bin" >> sdcard/etc/portage/package.license
  echo "sys-firmware/raspberrypi-wifi-ucode Broadcom" >> sdcard/etc/portage/package.license


  echo -e "${STEP}    Adding stuff to package.accept_keywords for ~${ARCH} ${NO}"
  mkdir -vp sdcard/etc/portage/package.accept_keywords
  echo "media-libs/raspberrypi-userland ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-libs
  echo "media-libs/raspberrypi-userland-bin ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-libs
  echo "media-video/raspberrypi-omxplayer ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-video
  echo "sys-boot/raspberrypi-firmware ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-boot
  echo "sys-firmware/raspberrypi-wifi-ucode ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-firmware
  echo "sys-kernel/raspberrypi-image ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-kernel
  echo "sys-kernel/raspberrypi-sources ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-kernel



# #if [ ! -f files/$DEB_VERSION ] && [ "$USE_FOUNDATION_PRE_COMPILE" = "yes" ]; then
  if [ "$USE_FOUNDATION_PRE_COMPILE" = "yes" ]; then
    if [ ! -d Linux ]; then
      echo -e "${STEP}    Making Linux directory and extracting deb ${NO}"
      mkdir -vp Linux
      cd Linux
      ar x ../files/$DEB_VERSION
      cd ..
    fi

    echo -e "${STEP}    Extracting Raspiberry pi kernel $DEB_VERSION ${NO}"
    pv Linux/data.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail

    KERNEL=$(ls sdcard/lib/modules | grep v8+ | cut -d"-" -f1 | awk '{print$1}')
    echo -e "${STEP}      Crud Removal for kernel  ${DONE} ${ARCH} ${KERNEL}  ${NO}"
    if [ "$ARCH" = "arm" ]; then
      rm -v sdcard/boot/kernel8.img
      rm -v sdcard/boot/{bcm2711-rpi-4-b.dtb,bcm2711-rpi-cm4.dtb}
      echo "And /lib/modules/${KERNEL}-v8+"
      rm -rf sdcard/lib/modules/${KERNEL}-v8+
    else
      rm -v sdcard/boot/{kernel.img,kernel7.img,kernel7l.img}
      rm -v sdcard/boot/{bcm2708-rpi-cm.dtb,bcm2708-rpi-b.dtb,bcm2708-rpi-b-rev1.dtb,bcm2708-rpi-b-plus.dtb}
      rm -v sdcard/boot/{bcm2708-rpi-zero.dtb,bcm2708-rpi-zero-w.dtb,bcm2709-rpi-2-b.dtb}
      rm -v sdcard/boot/{bcm2710-rpi-2-b.dtb,bcm2710-rpi-cm3.dtb,bcm2710-rpi-3-b.dtb,bcm2710-rpi-3-b-plus.dtb}
      echo "And /lib/modules/{${KERNEL}+,${KERNEL}-v7+,${KERNEL}-v7l+}"
      rm -rf sdcard/lib/modules/{${KERNEL}+,${KERNEL}-v7+,${KERNEL}-v7l+}
    fi
  echo -en "${STEP}\n    Modules left are  ${DONE}"; ls sdcard/lib/modules; echo -e "${NO}"
  fi

  echo -e "${STEP}\n    Copy $BITS boot files ${NO}"
  cp -v files/boot_files/${BOARD}/${ARCH}/* sdcard/boot

  echo -e "${STEP}\n\n    Copy wifi_extras ${NO}"
  mkdir -vp sdcard/lib/firmware/brcm
  cp -v files/$BOARD/wifi_extras/brcmfmac43455-sdio.bin sdcard/lib/firmware/brcm/brcmfmac43455-sdio.bin
  cp -v files/$BOARD/wifi_extras/brcmfmac43455-sdio.clm_blob sdcard/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob
  cp -v files/$BOARD/wifi_extras/brcmfmac43455-sdio.txt sdcard/lib/firmware/brcm/brcmfmac43455-sdio.txt

  echo -e "${STEP}\n  Creating cmdline.txt ${NO}"
  tee sdcard/boot/cmdline.txt <<EOF
console=serial0,115200 console=tty1 root=PARTUUID=${P2_UUID} rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet
EOF

  echo -e "${STEP}\n  Copy config.txt ${NO}"
  cp -v files/boot_files/${BOARD}/${ARCH}/config.txt sdcard/boot/config.txt

echo -e "${STEP}\n  Adding Raspberry Pi tweaks to sysctl.conf ${NO}"
echo "" >> sdcard/etc/sysctl.conf
echo "# http://www.raspberrypi.org/forums/viewtopic.php?p=104096" >> sdcard/etc/sysctl.conf
echo "# rpi tweaks" >> sdcard/etc/sysctl.conf
echo "vm.swappiness = 1" >> sdcard/etc/sysctl.conf
echo "vm.min_free_kbytes = 8192" >> sdcard/etc/sysctl.conf
echo "vm.vfs_cache_pressure = 50" >> sdcard/etc/sysctl.conf
echo "vm.dirty_writeback_centisecs = 1500" >> sdcard/etc/sysctl.conf
echo "vm.dirty_ratio = 20" >> sdcard/etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" >> sdcard/etc/sysctl.conf

# https://haydenjames.io/raspberry-pi-performance-add-zram-kernel-parameters/
#vm.vfs_cache_pressure=500
#vm.swappiness=100
#vm.dirty_background_ratio=1
#vm.dirty_ratio=50


#	####################################  End Foundation's stuff  ###################################
	##################################  Add more boards via elif  ###################################
elif [ "$BOARD" = "rock64" ]; then
  echo "Nuffin yet dum dum !!"

else
    echo "So, So, Sorry ,, ;(~"
    echo "Unsupported BOARD"
    fail
fi


#	##########################  Enter chroot and run Gentoo-install.sh  #############################
echo -e "${STEP}\n  Mounting new chroot system\n ${NO}"
mkdir -vp sdcard/dev/pts
mount -v proc sdcard/proc -t proc
mount -v sysfs sdcard/sys -t sysfs
mount -v --bind /dev/pts sdcard/dev/pts

echo -e "${STEP}\n  Running /root/Gentoo-imager/Gentoo-install.sh \n ${NO}"
chroot sdcard /root/Gentoo-imager/Gentoo-install.sh || fail

#	#########################  Save files, Clean and Create image  ##################################
echo -e "${STEP}\n  Returned from /root/Gentoo-imager/Gentoo-install.sh \n ${NO}"

if [ "$save_files" = "yes" ];then
  if [ ! -d distfiles ]; then
    mkdir -v distfiles
  fi
  echo -e "${STEP}\n  Coping distfiles \n ${NO}"
  rsync -a sdcard/var/cache/distfiles/ distfiles
fi

if [ "$USE_BINS" = "--usepkg" ] || [ "$USE_BINHOST" = "--getbinpkg" ] || [ "$CREATE_BINS" = "yes" ]; then
  if [ ! -d binpkgs ]; then
    mkdir -v binpkgs
  fi
  echo -e "${STEP}\n  Coping binpkgs \n ${NO}"
  rsync -a sdcard/var/cache/binpkgs/ binpkgs
fi

echo -e "${STEP}\n  emerge --depclean \n ${NO}"
chroot sdcard emerge --depclean

echo -e "${STEP}\n  eclean distfiles \n ${NO}"
chroot sdcard eclean distfiles

echo -e "${STEP}\n  eclean packages \n ${NO}"
chroot sdcard eclean packages

echo -e "${STEP}\n  Checking Install size \n ${NO}"
chroot sdcard df -h

sync
echo -e "${STEP}\n  Total sdcard used ${NO}"; echo
du -ch sdcard | grep total

echo -e "${STEP}\n  Unmounting mount points ${NO}"
umount -v sdcard/proc
umount -v sdcard/sys
umount -v sdcard/dev/pts
umount -v sdcard/boot
umount -v sdcard
rm -rvf sdcard

echo -e "${STEP}\n  Sanity check on ${rootpart} ${NO}"
file -s ${rootpart}

echo -e "${STEP}\n  Listing superblocks of ${rootpart} ${NO}"
dumpe2fs ${rootpart} | grep -i superblock

echo -e "${STEP}\n  Forced file system check of ${rootpart} ${NO}"
e2fsck -f ${rootpart}

echo -e "${STEP}\n  Resizing filesystem to the minimum size of ${rootpart} ${NO}"
echo -e "${STEP}    This can take awhile... ${NO}"
resize2fs -pM ${rootpart}

echo -e "${STEP}\n  Checking ${bootpart} ${NO}"
fsck.fat -traw ${bootpart}

echo -e "${STEP}\n  Create  ${Image_Name}.gz Image ${NO}"
dd if=Image conv=sync,noerror bs=1M status=progress | gzip -c > Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz
#dd if=Image conv=sync,noerror bs=1M status=progress | xz -k Image_Name

echo -e "${STEP}\n  Create  sha512sum ${NO}"
sha512sum --tag ${Image_Name}.gz > Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz.sha512sum
cat ${Image_Name}.gz.sha512sum

echo -e "${STEP}\n  losetup -d ${loop_device} ${NO}"
losetup -d ${loop_device}

echo -e "${STEP}\n\n  Okie Dokie, We Done\n ${NO}"
echo -e "${DONE}  Y'all Have A Great Day now   ${NO}"
echo $start_time
echo $(date)
echo

exit 0
