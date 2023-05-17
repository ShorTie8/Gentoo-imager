# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake flag-o-matic

CMAKE_MAKEFILE_GENERATOR="emake"
CMAKE_IN_SOURCE_BUILD=1

DESCRIPTION="Raspberry Pi Imager (WIP ebuild)"
HOMEPAGE="https://github.com/raspberrypi/rpi-imager"
SRC_URI="https://github.com/raspberrypi/rpi-imager/archive/v${PV}.tar.gz"

S="${WORKDIR}/rpi-imager-${PV}/src"

LICENSE="Apache"
SLOT="0"
KEYWORDS="arm arm64 amd64"
IUSE="+qt5"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="dev-util/cmake 
		 net-misc/curl 
		 app-arch/libarchive 
		 dev-libs/openssl 
		 dev-qt/qtcore 
		 dev-qt/qtsvg 
		 dev-qt/linguist 
		 dev-qt/linguist-tools 
		 dev-qt/qtconcurrent 
		 dev-qt/qtquickcontrols2"

src_prepare() {
    cmake_src_prepare
}

src_configure() {
    local mycmakeargs=(
    )
    cmake_src_configure
}
