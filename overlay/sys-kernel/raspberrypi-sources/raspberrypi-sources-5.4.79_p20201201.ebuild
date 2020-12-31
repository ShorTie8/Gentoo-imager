# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

ETYPE=sources

inherit kernel-2 eapi7-ver
detect_version
detect_arch

MY_PV=$(ver_cut 4-)
MY_PV=${MY_PV/p/}
DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_1.${MY_PV}-1.tar.gz"
S="${WORKDIR}/linux-raspberrypi-kernel_1.${MY_PV}-1"

KEYWORDS="arm ~arm arm64 ~arm64"

src_unpack() {
	default
	# Setup xmakeopts and cd into sourcetree.
	echo ">>> env_setup_xmakeopts"
	env_setup_xmakeopts
	cd "${S}"
}

src_prepare() {
	default
	echo ">>> make mrproper"
	make mrproper
}


src_configure() {
	default
	BOARD=$(cat /proc/cpuinfo | grep "Revision" | cut -d " " -f2 | awk '{print$1}')
	echo ">>>   board tis $BOARD"
#rpi
  if [ "$(cat /proc/cpuinfo | grep "Hardware" | cut -d " " -f2 | awk '{print$1}')" = "BCM2708" ]; then
    K_DEFCONFIG="bcmrpi_defconfig"
  else
	case ${BOARD} in
	  9000c1)
	    #pi0
	    K_DEFCONFIG="bcmrpi_defconfig"
	    ;;
	  a21041)
	    #pi2
	    K_DEFCONFIG="bcm2708_defconfig"
	    ;;
	  a22082|a020d3)
	    #pi3
	    arm?
	      K_DEFCONFIG="bcm2709_defconfig"
	    arm64?
	      K_DEFCONFIG="bcmrpi3_defconfig"
	    ;;
	  
	  a03111|b03111|c03111|d03114)
	    #pi4
	    K_DEFCONFIG="bcm2711_defconfig"
	    ;;
	  *)
	    echo "unknown pi"
	    exit 1
	    ;;
	  esac
  fi
  echo ">>> make $K_DEFCONFIG"
  make $K_DEFCONFIG
  echo ">>> make prepare"
  make prepare
  echo ">>> make oldconfig"
  make oldconfig
}

postinst_sources() {
	local K_SYMLINK=1

	# if we are to forcably symlink, delete it if it already exists first.
	echo ">>>  Checking for symlink"
	if [[ ${K_SYMLINK} -gt 0 ]]; then
		[[ -h ${EROOT}usr/src/linux ]] && { rm -v "${EROOT}"usr/src/linux || die; }
		echo ">>>    Removed old symlink"
		MAKELINK=1
	fi

	# if the link doesnt exist, lets create it
	[[ ! -h ${EROOT}usr/src/linux ]] && MAKELINK=1

	if [[ ${MAKELINK} == 1 ]]; then
		echo ">>>  Making symlink"
		ln -svf linux-raspberrypi-kernel_1.${MY_PV}-1 "${EROOT}"usr/src/linux || die
	fi
}
