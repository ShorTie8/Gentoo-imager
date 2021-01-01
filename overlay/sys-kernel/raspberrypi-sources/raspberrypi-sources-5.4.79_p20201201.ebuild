# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Note: BOARD variable can be passed by /etc/portage/make.conf,
#	like BOARD="pi4-64", otherwise `cat /proc/cpuinfo` will be used.

EAPI=6
ETYPE=sources

inherit kernel-2 eapi7-ver
detect_version
detect_arch

MY_PV=$(ver_cut 4-)
KV_FULL="raspberrypi-kernel_1.${MY_PV/p/}-1"
DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="https://github.com/raspberrypi/linux/archive/${KV_FULL}.tar.gz"
S="${WORKDIR}/linux-${KV_FULL}"

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
	if [[ ! -v BOARD ]]; then
	  BOARD=$(cat /proc/cpuinfo | grep "Revision" | cut -d " " -f2 | awk '{print$1}')
	fi
	echo ">>>   board tis $BOARD"
#rpi
  if [ "$(cat /proc/cpuinfo | grep "Hardware" | cut -d " " -f2 | awk '{print$1}')" = "BCM2708" ]; then
    K_DEFCONFIG="bcmrpi_defconfig"
  else
	case ${BOARD} in
	  900021|900032|900092|900093|900061|9000c1|pi)
	    K_DEFCONFIG="bcmrpi_defconfig"
	    ;;
	  a01040|a21041|p2)
	    K_DEFCONFIG="bcm2708_defconfig"
	    ;;
	  9020e0|a02042|a22042|a22082|a220a0|a020d3|a32082|a020d3|a22083|a02100|pi3|pi3-64)
	    arm?
	      K_DEFCONFIG="bcm2709_defconfig"
	    arm64?
	      K_DEFCONFIG="bcmrpi3_defconfig"
	    ;;
	  a03111|b03111|b03112|c03111|c03112|c03114|d03114|c03130|pi4|pi4-64)
	    K_DEFCONFIG="bcm2711_defconfig"
	    ;;
	  *)
	    echo "So, So, Sorry, Unknown pi"
	    exit 3
	    ;;
	  esac
  fi
}

src_compile() {
	echo ">>> make $K_DEFCONFIG"
	make $K_DEFCONFIG
	echo ">>> make prepare"
	make prepare
	echo ">>> make oldconfig"
	make oldconfig
}
