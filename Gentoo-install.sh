#!/usr/bin/env bash
# A simple script to setup Gentoo in your image
#
# BeerWare By ShorTie	<idiot@dot.com> 

root_password=root 	# Re-Define your own root password here

# Define message colors
OOPS="\033[1;31m"    # red
DONE="\033[1;32m"    # green
INFO="\033[1;33m"    # yellow
STEP="\033[1;34m"    # blue
WARN="\033[1;35m"    # hot pink
BOUL="\033[1;36m"	 # light blue
NO="\033[0m"         # normal/light

echo -e "${STEP}  Setting Trap ${NO}"
trap "echo; echo \"Unmounting /proc\"; fail" SIGINT SIGTERM

echo -e "${STEP}\n  source /etc/profile\n ${NO}"
source /etc/profile

start_time=$(date)
echo -e "${STEP}\n  emerge-webrsync \n ${NO}"
emerge-webrsync
echo; echo $start_time
echo $(date); echo

echo -e "${STEP}\n  Checking eselect profile list \n ${NO}"
eselect profile list

echo -e "${STEP}\n  Checking the USE variable \n ${NO}"
emerge --info | grep ^USE

echo -en "${STEP}\n  Changing timezone too...  \n ${NO}"
cat /etc/timezone

echo -en "${STEP}\n  Generating locals \n ${NO}"
echo -en "${STEP}\n    Checking /etc/locale.gen \n ${NO}"
grep -v '^#' /etc/locale.gen
locale-gen

echo -en "${STEP}\n  Adjusting default local too... \n  ${NO}"
eselect locale list

echo -e "${STEP}\n  Now reload the environment ${NO}"
env-update && source /etc/profile

echo -e "${STEP}\n  Automatically start networking at boot \n ${NO}"
cd /etc/init.d
ln -sv net.lo net.eth0
rc-update add net.eth0 default

echo -e "${STEP}\n  Setting up the root password... ${NO} $root_password "
echo root:$root_password | chpasswd

echo -e "${STEP}\n  emerge -vuDU @world \n ${NO}"
emerge -vuDU @world --quiet-build

echo -e "${STEP}\n  emerge --depclean \n ${NO}"
emerge --depclean
echo " checking /var/cache/distfiles"
ls /var/cache/distfiles

echo -e "${STEP}\n  emerge gentoolkit \n ${NO}"
emerge app-portage/gentoolkit --quiet-build

echo -e "${STEP}\n  System logger syslog-ng \n ${NO}"
emerge app-admin/syslog-ng app-admin/logrotate --quiet-build
sed -i 's/#rc_logger="NO"/rc_logger="YES"/' /etc/rc.conf
sed -i 's/#rc_log_path="/var/log/rc.log"/rc_log_path="/var/log/rc.log"/' /etc/rc.conf
rc-update add sshd default

echo -e "${STEP}\n  Cron daemon dcron \n ${NO}"
emerge sys-process/cronie --quiet-build
rc-update add cronie default

echo -e "${STEP}\n  File indexing \n ${NO}"
emerge sys-apps/mlocate --quiet-build

echo -e "${STEP}\n  Setting up ${DONE}ssh  ${NO}"
sed -i 's/.*PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo -e "${STEP}    generating keys \n ${NO}"
/usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ""
/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
/usr/bin/ssh-keygen -t ed25519 -a 100 -f /etc/ssh/ssh_host_ed25519_key -N ""
#/usr/bin/ssh-keygen -t rsa -b 4096 -o -a 100 -f /etc/ssh/ssh_host_rsa_key -N ""
rc-update add sshd default
cat /etc/ssh/sshd_config | grep PermitRootLogin

echo -e "${STEP}\n  Installing a DHCP client \n ${NO}"
emerge net-misc/dhcpcd --quiet-build

echo -e "${STEP}\n  Install wireless-regdb \n ${NO}"
emerge net-wireless/wireless-regdb --quiet-build

echo -e "${STEP}\n  Install wpa_supplicant \n ${NO}"
emerge net-wireless/wpa_supplicant --quiet-build

echo -e "${STEP}\n  Install wireless networking tools \n ${NO}"
emerge net-wireless/iw --quiet-build

echo -e "${STEP}\n  Adding growpart.init in  \n ${NO}"
rc-update add growpart boot

echo -e "${STEP}\n  Adding dphys-swapfile.init in  \n ${NO}"
emerge sys-devel/bc --quiet-build
rc-update add dphys-swapfile default

echo -e "${STEP}\n  Sync'n \n ${NO}"
sync

echo -e "${STEP}\n  Checking Install size \n ${NO}"
df -h

exit 0
