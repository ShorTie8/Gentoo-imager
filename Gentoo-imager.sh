#!/bin/bash
# A simple script to make your own Gentoo pi images
#
# BeerWare By ShorTie	<idiot@dot.com> 
#
# This work is too trival to have any copyright, I hereby wave any copyright
# and release it into the public domain.
#
# root_password is set in Gentoo-install.sh, defualt is root/rtyu

# Set BITS to 32 for armhf or 64 for arm64, or not
if [ "$1" = "armhf" ] || [ `uname -m` = "armhf" ]; then
    echo "32 bit"
    BITS=32
else
    echo "64 bit"
    BITS=64
fi

hostname=Gentoo
save_files=yes

DATE=$(date +"%Y%m%d")
Image_Name=Gentoo-pi-${BITS}bit.${DATE}.img

timezone=America/New_York
locales="en_US.UTF-8 UTF-8"
default_locale=en_US.UTF-8

number_of_keys=104		# You can define this here or remark out or leave blank to use current systems
keyboard_layout=us		# must be defined if number_of_keys is defined
keyboard_variant=		# blank is normal
keyboard_options=		# blank is normal
backspace=guess			# guess is normal

#************************************************************************

# Define message colors
OOPS="\033[1;31m"    # red
DONE="\033[1;32m"    # green
INFO="\033[1;33m"    # yellow
STEP="\033[1;34m"    # blue
WARN="\033[1;35m"    # hot pink
BOUL="\033[1;36m"	 # light blue
NO="\033[0m"         # normal/light

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
    echo -e "${INFO}  Yuppers,${BOUL} root it tis ..${DONE} :)~${NO}"
fi

if [ ! -e files/Dependencies-ok ]; then
  echo -e "${STEP}\n  Installing dependencies ..  ${NO}"
    if [ -f /etc/gentoo-release ]; then
      emerge sys-fs/dosfstools sys-fs/multipath-tools sys-apps/pv sys-block/parted --quiet-build || fail
    else
      apt install binutils dosfstools file kpartx libc6-dev parted psmisc pv xz-utils || fail
    fi
  touch files/Dependencies-ok
fi

echo -e "${INFO}  Making sure of a kleen enviroment .. ${BOUL}:/~ ${NO}"
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
  echo -e "${STEP}\n  Making files directory ${NO}"
  mkdir -p files
fi

echo -e "${STEP}\n  Checkin downloads  ${NO}"

if [ "$BITS" = "32" ] && [ ! -f files/stage3-armv7a_hardfp-20200509T210605Z.tar.xz ]; then
  echo -e "${STEP}\n    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/arm/autobuilds/20200509T210605Z/stage3-armv7a_hardfp-20200509T210605Z.tar.xz || fail
fi

if [ "$BITS" = "64" ] && [ ! -f files/stage3-arm64-20201004T190540Z.tar.xz ]; then
  echo -e "${STEP}\n    Downloadin Stage 3 tarball ${NO}"
  wget -P files http://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64/stage3-arm64-20201004T190540Z.tar.xz || fail
fi

#if [ ! -f files/portage-latest.tar.xz ]; then
#  echo -e "${STEP}\n    Downloadin portage-latest tarball ${NO}"
#  wget -P files http://gentoo.mirrors.easynews.com/linux/gentoo/snapshots/portage-latest.tar.xz || fail
#fi

if [ ! -f files/raspberrypi-kernel_1.20201022-1_arm64.deb ]; then
  echo -e "${STEP}\n    Downloadin Raspiberry pi kernel tarball ${NO}"
  wget -P files http://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware/raspberrypi-kernel_1.20201022-1_arm64.deb || fail
fi

if [ "$BITS" = "32" ] && [ ! -d files/boot_files_32 ]; then
  echo -e "${STEP}\n\n    Getting boot_files ${NO}"
  mkdir -vp files/boot_files_32
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/LICENCE.broadcom  -O files/boot_files_32/LICENCE.broadcom || fail
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/bootcode.bin  -O files/boot_files_32/bootcode.bin || fail
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/fixup.dat  -O files/boot_files_32/fixup.dat || fail
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/start.elf  -O files/boot_files_32/start.elf || fail
fi

if [ "$BITS" = "64" ] && [ ! -d files/boot_files_64 ]; then
  echo -e "${STEP}\n\n    Getting boot_files ${NO}"
  mkdir -vp files/boot_files_64
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/LICENCE.broadcom  -O files/boot_files_64/LICENCE.broadcom || fail
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/fixup4.dat  -O files/boot_files_64/fixup4.dat || fail
  wget https://raw.githubusercontent.com/RPi-Distro/firmware/debian/boot/start4.elf  -O files/boot_files_64/start4.elf || fail
fi

if [ ! -d files/wifi_extras ]; then
  echo -e "${STEP}\n\n    Getting wifi files ${NO}"
  mkdir -vp files/wifi_extras
  wget  https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.bin -O files/wifi_extras/brcmfmac43455-sdio.bin || fail
  wget  https://github.com/RPi-Distro/firmware-nonfree/raw/master/brcm/brcmfmac43455-sdio.clm_blob -O files/wifi_extras/brcmfmac43455-sdio.clm_blob || fail
  wget  https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm/brcmfmac43455-sdio.txt -O files/wifi_extras/brcmfmac43455-sdio.txt || fail
fi

if [ ! -f files/config.txt.64 ]; then
    echo; echo; echo "downloading"; echo
    wget https://raw.githubusercontent.com/RPi-Distro/pi-gen/master/stage1/00-boot-files/files/config.txt || fail
    cp config.txt files/config.txt.32
    sed '4 i #dtoverlay=sdtweak,poll_once=on' config.txt > config.txt.new
    sed '4 i #dtoverlay=i2c-rtc,ds3231' config.txt.new > config.txt.new.1
    sed '4 i dtoverlay=i2c-rtc,ds1307' config.txt.new.1 > config.txt.new.2
    sed '4 i dtparam=random=on' config.txt.new.2 > config.txt.new.3
    sed '4 i arm_64bit=1' config.txt.new.3 > config.txt.new.4
    sed '/Some settings/G' config.txt.new.4 > config.txt.new.5
    sed '4 i #initramfs initrd-UNAME.gz' config.txt.new.5 > config.txt.new.6
    sed '4 i #kernel=vmlinux-UNAME.img' config.txt.new.6 > config.txt.new.7
    sed '/Some settings/G' config.txt.new.7 > files/config.txt.64
    rm -v config.txt config.txt.new config.txt.new.*
    #sed -i 's/#hdmi_safe=1/#hdmi_safe=1/' debs/config.arm64
    #sed -i 's/#hdmi_group=1/hdmi_group=1/' arm64/config.arm64
    #sed -i 's/#hdmi_mode=1/hdmi_mode=4/' arm64/config.arm64
    #sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' arm64/config.arm64
    # dtparam=sd_poll_once
fi

#	###############################################  End Downloads  ###################################################

if [ ! -f Image ]; then
  echo -e "${DONE}\n\n  Creating a zero-filled file ${NO}"
  if [ "$my_DESKTOP" = "yes" ]; then
    dd if=/dev/zero of=Image  bs=1M  count=3866 iflag=fullblock
  else
    dd if=/dev/zero of=Image  bs=1M  count=8420 iflag=fullblock
  fi
fi

# Create partitions
echo -e "${STEP}\n\n  Creating partitions ${NO}"
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
echo -e "${STEP}  Partprobing $loop_device ${NO}"
partprobe ${loop_device}
bootpart=${loop_device}p1
rootpart=${loop_device}p2
echo -e "${STEP}    Boot partition is ${DONE} $bootpart ${NO}"
echo -e "${STEP}    Root partition is ${DONE} $rootpart ${NO}"

# Format partitions
echo -e "${STEP}\n  Formating partitions ${NO}"
echo "mkfs.vfat -n boot $bootpart"
mkfs.vfat -n BOOT $bootpart
echo
echo "mkfs.ext4 -O ^huge_file  -L Gentoo $rootpart"; echo
echo y | mkfs.ext4 -O ^huge_file  -L Gentoo $rootpart && sync
echo

P1_UUID="$(lsblk -o PTUUID "${loop_device}" | sed -n 2p)-01"
P2_UUID="$(lsblk -o PTUUID "${loop_device}" | sed -n 2p)-02"
echo "P1_UUID = ${P1_UUID}"
echo "P2_UUID = ${P2_UUID}"

echo -e "${STEP}\n  Setting up for Stage 3 Install ${NO}"
mkdir -v sdcard
mount -v -t ext4 -o sync $rootpart sdcard

echo -e "${STEP}\n  Extracting Stage 3 tarball ${NO}"
if [ "$BITS" = "32" ]; then
  pv files/stage3-armv7a_hardfp-20200509T210605Z.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
else
  pv files/stage3-arm64-20201004T190540Z.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail
fi

#echo -e "${STEP}\n  Installing ${DONE}portage-latest\n ${NO}"
#pv files/portage-latest.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard/usr || fail

echo -e "${STEP}\n  Playing make.conf ${NO}"
#sed -i 's/COMMON_FLAGS="-O2 -pipe"/COMMON_FLAGS="-O2 -pipe -march=native"/' sdcard/etc/portage/make.conf
cat <<EOF >> sdcard/etc/portage/make.conf

#CFLAGS="-march=armv8-a+crc -mtune=cortex-a72 -ftree-vectorize -O2 -pipe"

# <josef64> the default (without added MAKEOPTS) is already nproc
#MAKEOPTS="-j5"

#PORTAGE_BINHOST="http://bloodnoc.org/~roy/BINHOSTS/"
#PORTAGE_BINHOST="http://bloodnoc.org/~roy/BINHOSTS/gcc-10.x"
#PORTAGE_BINHOST="http://bloodnoc.org/~roy/BINHOSTS/gcc-10.x/armv8a/"

EOF
cat sdcard/etc/portage/make.conf

echo -e "${STEP}\n  Creating gentoo.conf ${NO}"
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
hostname="tux"

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
cp -aR .git sdcard/root/Gentoo-imager/.git


echo -e "${STEP}\n  Mounting the boot partition\n ${NO}"
mount -v -t vfat -o sync $bootpart sdcard/boot

if [ -f wpa_supplicant.conf ]; then
  echo -e "${STEP}\n  Coping wpa_supplicant.conf over to sdcard \n ${NO}"
  cp -v wpa_supplicant.conf sdcard/boot/wpa_supplicant.conf
fi


#	#########################################  Foundation's stuff  ################################# 

if [ ! -d Linux ]; then
  echo -e "${STEP}\n  Making Linux directory ${NO}"
  mkdir -vp Linux
  cd Linux
  ar x ../files/raspberrypi-kernel_1.20201022-1_arm64.deb
  cd ..
fi

echo -e "${STEP}\n  Extracting Raspiberry pi kernel tarball ${NO}"
pv Linux/data.tar.xz | tar -Jxpf - --xattrs-include='*.*' --numeric-owner -C sdcard || fail

KERNEL=$(ls sdcard/lib/modules | grep v8+ | cut -d"-" -f1 | awk '{print$1}')
echo -e "${STEP}\n    Crud Removal for kernel  ${DONE} ${KERNEL}  ${NO}"
if [ "$BITS" = "32" ]; then
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

echo -e "${STEP}\n    Copy $BITS boot files ${NO}"
cp -v files/boot_files_$BITS/* sdcard/boot

echo -e "${STEP}\n\n    Copy wifi_extras ${NO}"
mkdir -vp sdcard/lib/firmware/brcm
cp -v files/wifi_extras/brcmfmac43455-sdio.bin sdcard/lib/firmware/brcm/brcmfmac43455-sdio.bin
cp -v files/wifi_extras/brcmfmac43455-sdio.clm_blob sdcard/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob
cp -v files/wifi_extras/brcmfmac43455-sdio.txt sdcard/lib/firmware/brcm/brcmfmac43455-sdio.txt

echo -e "${STEP}\n  Creating cmdline.txt ${NO}"
tee sdcard/boot/cmdline.txt <<EOF
console=serial0,115200 console=tty1 root=PARTUUID=${P2_UUID} rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet
EOF

echo -e "${STEP}\n  Copy config.txt ${NO}"
cp -v files/config.txt.$BITS sdcard/boot/config.txt

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


#	####################################  End Foundation's stuff  ################################## 


echo -e "${STEP}\n  Mounting new chroot system\n ${NO}"
mkdir -vp sdcard/dev/pts
mount -v proc sdcard/proc -t proc
mount -v sysfs sdcard/sys -t sysfs
mount -v --bind /dev/pts sdcard/dev/pts

echo -e "${STEP}\n  Running /root/Gentoo-imager/Gentoo-install.sh \n ${NO}"
chroot sdcard /root/Gentoo-imager/Gentoo-install.sh || fail

echo -e "${STEP}\n  Returned from /root/Gentoo-imager/Gentoo-install.sh \n ${NO}"

if [ "$save_files" = "yes" ];then
  if [ ! -d distfiles ]; then
    mkdir -v distfiles
  fi
  echo -e "${STEP}\n  Copy distfiles \n ${NO}"
  rsync -av sdcard/var/cache/distfiles/ distfiles
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
dd if=Image conv=sync,noerror bs=1M status=progress | gzip -c > ${Image_Name}.gz
#dd if=Image conv=sync,noerror bs=1M status=progress | xz -k Image_Name

echo -e "${STEP}\n  Create  sha512sum ${NO}"
sha512sum --tag ${Image_Name}.gz > ${Image_Name}.gz.sha512sum
cat ${Image_Name}.gz.sha512sum

echo -e "${STEP}\n  losetup -d ${loop_device} ${NO}"
losetup -d ${loop_device}

echo -e "${STEP}\n\n  Okie Dokie, We Done\n ${NO}"
echo -e "${DONE}  Y'all Have A Great Day now   ${NO}"
echo $start_time
echo $(date)
echo

exit 0
