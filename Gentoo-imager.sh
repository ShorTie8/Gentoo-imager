#!/bin/bash
# A simple script to make your own Gentoo Images
#
# BeerWare By ShorTie	<idiot@dot.com> 
#
# This work is too trival to have any copyrights.
# So, I hereby wave any copyrights,
#	and there for release it into the Public Domain.

# Included is a growpart init, So / is expanded on 1st boot.
# Also included is a dphys-swapfile ebuild, so a dynamic swap file can be used.
#	It is sized in meg's, so a gig swap file be like swap_size=1024
# The github repository is also included in /root/Gentoo-imager.
#   It is copied "as-is", so any changes carry on.
#   And or a 'git diff > my_Gentoo_Imager.diff' can be used for saving your work.
# If you include a wpa_supplicant.conf here, It will be copied to /etc/wpa_supplicant/wpa_supplicant.conf.
# Defualt is to create binpkgs and save those and distfiles files here.

hostname=tux
root_password=root
swap_size=100

#	# Makes a compressed image file.
	# rem'd out it leaves Image/sdcard still alive, so you can dd Image to something easily.
MAKE_COMPRESSED_IMAGE=yes

#	# This speeds things up, otherwize it uses emerge-webrsync
USE_PORTAGE_LATEST=yes

#	# Set your profile to use, so the symlink is made correctly.
PROFILE=17.0

#	# Define your USE flags
	# Note: For a Pesonal Image you may want to change the root_password and re-enable pam.
#USE=""
USE="-pam"

#	# To add the ACCEPT_KEYWORDS ~$ARCH  setting to /etc/portage/make.conf.
	# This will require a rebuild of gcc automagically.
#ACCEPT_KEYWORDS=yes

#	# This proforms a emerge @system && @world, can take days if ~ is inabled.
	# So if you want to optimize gcc for your board to the below settings.
	# Just rem out if you do not wish to do this.
	# Pleaze still select your board below, so special board stuff is included/used.
	# Note: We do check 'gcc -v' against portage's version to see if rebuild is required.
#REBUILD_GCC=yes

BOARD=""
#	# Set your board, cpu and common flags
#BOARD=defualt
ARCH=`uname -m`
CPU="-march=native"
COMMON_FLAGS="-O2 -pipe"

#BOARD=pi
#ARCH=armv6j_hardfp
#CPU="-march=armv6j_hardfp -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=pi2
#ARCH=armv7a_hardfp
#CPU="-march=armv7a_hardfp -mtune=cortex-a53 -mfpu=vfp -mfloat-abi=hard"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=pi3
#ARCH=armv7a_hardfp
#CPU="-march=armv7a_hardfp -mtune=cortex-a72 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=pi4
#ARCH=armv7a_hardfp
#CPU="-march=armv7a_hardfp -mtune=cortex-a72 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=pi3-64
#ARCH=arm64
#CPU="-march=armv8-a+crc -mtune=cortex-a72"
#COMMON_FLAGS="-O2 -pipe"

BOARD=pi4-64
#ARCH=arm64
#CPU="-march=armv8-a+crc -mtune=cortex-a72"
#COMMON_FLAGS="-O3 -pipe -fPIC"

#BOARD=rock64
#ARCH=arm64
#CPU="-march=armv8-a+crc -mtune=cortex-a72"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=rockpro64
#ARCH=arm64
#CPU="-march=armv8-a+crc -mtune=cortex-a72"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=i686
#ARCH=i686
#CPU="-march=i686"
#COMMON_FLAGS="-O2 -pipe"

#BOARD=amd64
#ARCH=amd64
#CPU="-march=x86_64"
#COMMON_FLAGS="-O2 -pipe"


#	# Set this for a vfat /boot, for pi's and things, otherwize it uses ext4.
	# Note: We only use 2 or 3 (efi) partitions.
	# Swap is handled by a file, dphys-swapfile, size is changable in /etc/dphys-swapfile
	# Defualt is 100meg, To change size, Adjust and either /etc/init.d/dphys-swapfile {stop & start} or reboot.
BOOT=vfat

#	# Set this if you need a efi partition.
	# Thus it uses a gpt partition table instead of msdos.
#EFI_PARTITION=yes  NOT fully intagrated yet

#	# This is for pi boards and the foudation kernel.
	# USE_FOUNDATION_SOURES will use thier sources, else sys-kernel/gentoo-sources will be used.
	# USE_FOUNDATION_PRE_COMPILE will use sys-kernel/raspberrypi-image, instead of compiling your own kernel.
USE_FOUNDATION_SOURES=yes
USE_FOUNDATION_PRE_COMPILE=yes

#	# This will use roy's binhost if you wish, or any other if added/changed
	# Many Thankz goes out to Mr.Roy
BIN_HOST_URL=""
#USE_BINHOST=--getbinpkg
#BIN_HOST_URL=http://bloodnoc.org/~roy/BINHOSTS/gcc-10.x/armv8a/

#	# These will create & use binary packages, for the next run or a binhost some where.
CREATE_BINS=yes
USE_BINS=--usepkg

#	# Set timezone and locals
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

if [ "$ARCH" = "aarch64" ]; then
  echo -en "${STEP}  Resetting  ${DONE}${ARCH} "
  ARCH=arm64
  echo -e "${STEP} to ${INFO}${ARCH} ${NO}"
fi

echo -e "${STEP}  Building for ${DONE}${BOARD} ${STEP}with arch ${DONE}${ARCH} ${NO}"

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
      emerge sys-fs/dosfstools sys-fs/multipath-tools sys-block/parted sys-apps/pv sys-fs/zerofree --quiet-build || fail
    else
      apt install binutils dosfstools file kpartx libc6-dev parted psmisc pv xz-utils zerofree || fail
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
RELEASE_DATE_64=20201206T214503Z
RELEASE_DATE_arm=20201130T214503Z
RELEASE_DATE_arm64=20201223T003511Z

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
  #wget -N -P files http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz.gpgsig || fail
  #wget -N -P files http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz.md5sum || fail
fi


#	#################################  Board specific Downloads  ####################################
echo -e "${STEP}   Checking for ${DONE}${BOARD} ${STEP}stuff ${NO}"
if [ ! -d files/${BOARD}/${ARCH} ]; then
  mkdir -vp files/${BOARD}/${ARCH}
fi

if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ] \
		 || [ "$BOARD" = "pi3-64" ] || [ "$BOARD" = "pi4-64" ]; then

  if [ ! -f files/${BOARD}/${ARCH}/config.txt ]; then
    echo -e "${STEP}      Downloading config.txt ${NO}"
    if [ "$ARCH" = "arm" ]; then
      wget https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage1/00-boot-files/files/config.txt -O files/${BOARD}/${ARCH}/config.txt || fail
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
      sed '/Some settings/G' config.txt.new.7 > files/${BOARD}/${ARCH}/config.txt
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
  if [ ! -d files/${BOARD}/${ARCH} ]; then
    mkdir -vp files/${BOARD}/${ARCH}
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
    dd if=/dev/zero of=Image  bs=1M  count=46420 iflag=fullblock
  else
    dd if=/dev/zero of=Image  bs=1M  count=10420 iflag=fullblock
  fi
fi

# Create partitions
echo -e "${STEP}    Creating partitions ${NO}"
if [ "$EFI_PARTITION" != "yes" ]; then
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

else
  echo "Yup, gonna get there"
  exit 1
fi


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
if [ "$BOOT" = "vfat" ]; then
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

#	#####################  Extracting Stage 3 tarball and portage-latest  ###########################
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

if [ "$USE_PORTAGE_LATEST" = "yes" ]; then
  echo -e "${STEP}    Installing ${DONE}portage-latest ${NO}"
  pv files/portage-latest.tar.xz | tar -Jxpf - --strip-components=1 -C sdcard/var/db/repos/gentoo || fail
  echo -e "${STEP}      Setting up profile ${NO}"
  pushd sdcard/etc/portage
  ln -svf ../../var/db/repos/gentoo/profiles/default/linux/${ARCH}/${PROFILE} make.profile
  popd
fi

#	#################################  Copying gentoo.conf  #########################################
echo -e "${STEP}\n  Copying gentoo.conf ${NO}"
mkdir -vp sdcard/etc/portage/repos.conf
#cp -v sdcard/usr/share/portage/config/repos.conf sdcard/etc/portage/repos.conf/gentoo.conf
mv -v sdcard/usr/share/portage/config/repos.conf sdcard/etc/portage/repos.conf/gentoo.conf

#	#################################  Creating make.conf   #########################################
echo $BOARD
echo $CPU
echo $COMMON_FLAGS

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
echo "USE=\"$USE\"" >> sdcard/etc/portage/make.conf
echo "PORTDIR_OVERLAY=\"/usr/local/portage/overlay/\"" >> sdcard/etc/portage/make.conf
echo "" >> sdcard/etc/portage/make.conf
if [ "$CREATE_BINS" = "yes" ]; then
  echo "FEATURES=\"buildpkg\"" >> sdcard/etc/portage/make.conf
fi
echo "PKGDIR=\"/var/cache/binpkgs/$ARCH/GCC_VERSION/\"" >> sdcard/etc/portage/make.conf
echo "" >> sdcard/etc/portage/make.conf
echo "PORTAGE_BINHOST=\"$BIN_HOST_URL\"" >> sdcard/etc/portage/make.conf
echo "" >> sdcard/etc/portage/make.conf
echo; cat sdcard/etc/portage/make.conf

#	#################################  Creating board.conf  #########################################
echo -e "${STEP}\n  Creating board.conf ${NO}"
tee sdcard/etc/portage/board.conf <<EOF
# This file automagically created by Gentoo-imager.sh for Gentoo-install.sh
hostname=$hostname
root_password=$root_password
swap_size=$swap_size

BOARD=$BOARD
REBUILD_GCC=$REBUILD_GCC
ACCEPT_KEYWORDS=$ACCEPT_KEYWORDS
USE_PORTAGE_LATEST=$USE_PORTAGE_LATEST
USE_BINS=$USE_BINS
USE_BINHOST=$USE_BINHOST
USE_FOUNDATION_SOURES=$USE_FOUNDATION_SOURES
USE_FOUNDATION_PRE_COMPILE=$USE_FOUNDATION_PRE_COMPILE


EOF

#	#######################  Copying, Adjust and Configure some stuff  ##############################
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
hostname="$hostname"

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

#	###############################  Copy Gentoo-imager  ############################################
echo -e "${STEP}\n  Copy Gentoo-imager.sh files \n ${NO}"
install -v -m 0755 -D Gentoo-imager.sh sdcard/root/Gentoo-imager/Gentoo-imager.sh
install -v -m 0755 Gentoo-install.sh sdcard/root/Gentoo-imager/Gentoo-install.sh
#install -v -m 0644 Makefile sdcard/root/Gentoo-imager
install -v -m 0644 READme sdcard/root/Gentoo-imager
cp -vR overlay sdcard/root/Gentoo-imager
echo "And .git"
cp -aR .git sdcard/root/Gentoo-imager/.git

#	###############################  Copy overlays  #################################################
echo -e "${STEP}\n  Setup overlay   ${NO}"
mkdir -vp sdcard/usr/local/portage
cp -vR overlay sdcard/usr/local/portage/
chroot sdcard chown -vR portage:portage /usr/local/portage/overlay/*
#echo "$HOSTNAME" > /usr/portage/local/profiles/repo_name

#	###############################  Make wifi init  ################################################
tee sdcard/etc/init.d/wifi <<EOF
#!/sbin/openrc-run
# Brought to you by ShorTie  <idiot@dot.com>

description="Moving wpa_supplicant.conf"

start()
{
	if [ -f /boot/wpa_supplicant.conf ]; then
	  /etc/init.d/wpa_supplicant stop
	  if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
	    mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup
	  fi
	  elog "  Moving wpa_supplicant.conf"
	  mv -v /boot/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
	  chmod 600 /etc/wpa_supplicant/wpa_supplicant_wired.conf
	  sync
	  sleep 2
	  /etc/init.d/wpa_supplicant start
	fi
}

EOF
chmod -v +x sdcard/etc/init.d/wifi

#	###############################  Copy distfiles and binpkgs files  ##############################
if [ -d distfiles ]; then
  echo -en "${STEP}\n  Coping distfiles over to sdcard  ${NO}"
  du -sh distfiles
  cp distfiles/* sdcard/var/cache/distfiles
fi

if [ "$USE_BINS" = "--usepkg" ] || [ "$USE_BINHOST" = "--getbinpkg" ]; then
  echo -en "${STEP}    Coping bin files  ${NO}"
  du -sh binpkgs
  cp -R binpkgs/* sdcard/var/cache/binpkgs
fi

#	#####################  Mounting the boot partition and copy stuff  ##############################
echo -e "${STEP}\n  Mounting the boot partition\n ${NO}"
mount -v -t vfat -o sync $bootpart sdcard/boot

#	#########################################  Foundation's stuff  #################################
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ] \
		 || [ "$BOARD" = "pi3-64" ] || [ "$BOARD" = "pi4-64" ]; then
  echo -e "${STEP}\n  Doing a  Raspiberry ${DONE}$BOARD${STEP} install ${NO}"
	# We do this here so emerge can pull packages
  echo -e "${STEP}    Adding stuff to package.license ${NO}"
  echo "media-libs/raspberrypi-userland-bin raspberrypi-videocore-bin" >> sdcard/etc/portage/package.license
  echo "sys-boot/raspberrypi-firmware raspberrypi-videocore-bin" >> sdcard/etc/portage/package.license
  echo "sys-firmware/raspberrypi-wifi-ucode Broadcom" >> sdcard/etc/portage/package.license
  echo "sys-kernel/raspberrypi-image raspberrypi-videocore-bin" >> sdcard/etc/portage/package.license

  echo -e "${STEP}    Adding stuff to package.accept_keywords for ~${ARCH} ${NO}"
  mkdir -vp sdcard/etc/portage/package.accept_keywords
  echo "media-libs/raspberrypi-userland ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-libs
  echo "media-libs/raspberrypi-userland-bin ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-libs
  echo "media-video/raspberrypi-omxplayer ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/media-video
  echo "sys-boot/raspberrypi-firmware ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-boot
  echo "sys-firmware/raspberrypi-wifi-ucode ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-firmware
  echo "sys-kernel/raspberrypi-image ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-kernel
  echo "sys-kernel/raspberrypi-sources ~${ARCH}" >> sdcard/etc/portage/package.accept_keywords/sys-kernel

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

#  We gotta do this here so emerge sys-kernel/raspberrypi-image installs without conflices
if [ "$BOARD" = "pi" ] || [ "$BOARD" = "pi2" ] || [ "$BOARD" = "pi3" ] || [ "$BOARD" = "pi4" ] \
		 || [ "$BOARD" = "pi3-64" ] || [ "$BOARD" = "pi4-64" ]; then
  echo -e "${STEP}\n  Creating cmdline.txt ${NO}"
  mv -v sdcard/boot/cmdline.txt sdcard/boot/cmdline.txt.orig
  tee sdcard/boot/cmdline.txt <<EOF
console=serial0,115200 console=tty1 root=PARTUUID=${P2_UUID} rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet
EOF
  cp -v sdcard/boot/cmdline.txt sdcard/boot/cmdline.txt.my_backup

  echo -e "${STEP}\n  Copy config.txt ${NO}"
  mv -v sdcard/boot/config.txt sdcard/boot/config.txt.orig
  cp -v files/${BOARD}/${ARCH}/config.txt sdcard/boot/config.txt
  cp -v sdcard/boot/config.txt sdcard/boot/config.txt.my_backup
fi
#	#  End

echo -e "${STEP}\n  Saving build logs  ${NO}"
if [ -d build_logs ]; then
 rm -rf build_logs
fi
mkdir -v build_logs
cp sdcard/var/log/portage/*.log build_logs

echo -e "${STEP}\n  emerge --depclean \n ${NO}"
chroot sdcard emerge --depclean

echo -e "${STEP}\n  eclean distfiles \n ${NO}"
chroot sdcard eclean distfiles

if [ "$save_files" = "yes" ];then
  if [ ! -d distfiles ]; then
    mkdir -v distfiles
  fi
  echo -e "${STEP}\n  Coping distfiles  ${NO}"
  du -sh sdcard/var/cache/distfiles
  rm distfiles/*
  mv sdcard/var/cache/distfiles/* distfiles
fi
rm sdcard/var/cache/distfiles/*

echo -e "${STEP}\n  eclean packages \n ${NO}"
chroot sdcard eclean packages

if [ "$USE_BINS" = "--usepkg" ] || [ "$USE_BINHOST" = "--getbinpkg" ] || [ "$CREATE_BINS" = "yes" ]; then
  if [ ! -d binpkgs ]; then
    mkdir -v binpkgs
  fi
  echo -e "${STEP}\n  Coping binpkgs  ${NO}"
  du -sh sdcard/var/cache/binpkgs
  rm -rf binpkgs/*
  mv sdcard/var/cache/binpkgs/* binpkgs/
fi
rm -rf sdcard/var/cache/binpkgs/*

echo -e "${STEP}\n  Checking Install size \n ${NO}"
chroot sdcard df -h

#<Jannik2099> !note aggi most rk3399 platforms are supported by u-boot, just make the respective defconfig and flash it

sync
echo -e "${STEP}\n  Total sdcard used ${NO}"; echo
du -ch sdcard | grep total

echo -e "${STEP}\n  Unmounting mount points ${NO}"
umount -v sdcard/proc
umount -v sdcard/sys
umount -v sdcard/dev/pts

if [ "$MAKE_COMPRESSED_IMAGE" = "yes" ]; then
  echo -e "${STEP}\n  Making compressed image file ${NO}"
  echo -e "${STEP}    Unmounting mount points ${NO}"
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

  echo -e "${STEP}\n  zerofree ${rootpart} ${NO}"
  zerofree -v ${rootpart}

  echo -e "${STEP}\n  Checking ${bootpart} ${NO}"
  fsck.fat -traw ${bootpart}

  if [ "$ACCEPT_KEYWORDS" = "yes" ]; then
    ARCH=~$ARCH
  fi
  
  echo -e "${STEP}\n  Create  Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz Image ${NO}"
  dd if=Image conv=sync,noerror bs=1M status=progress | gzip -c > Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz

  echo -e "${STEP}\n  Create  sha512sum ${NO}"
  sha512sum --tag Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz > Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz.sha512sum
  cat Gentoo-${BOARD}-${ARCH}.${DATE}.img.gz.sha512sum

  echo -e "${STEP}\n  losetup -d ${loop_device} ${NO}"
  losetup -d ${loop_device}
else
  echo -e "${STEP}\n  Living Image live ${NO}"
  echo -e "${STEP}    Okie Dokie, We Done\n ${NO}"
  exit 1
fi

echo -e "${STEP}\n\n  Okie Dokie, We Done\n ${NO}"
echo -e "${DONE}  Y'all Have A Great Day now   ${NO}"
echo $start_time
echo $(date)
echo

exit 0
