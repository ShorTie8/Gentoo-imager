# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A script that can grow your rootfs on first boot"
HOMEPAGE="https://github.com/canonical/cloud-utils/
          http://manpages.ubuntu.com/manpages/natty/man1/growpart.1.html"
SRC_URI="https://github.com/canonical/cloud-utils/archive/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/cloud-utils-${PV}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm arm64 ppc64 x86"
IUSE=""

DEPEND=""
RDEPEND=""

src_install() {
	dosbin ${WORKDIR}/cloud-utils-${PV}/bin/growpart
	dodoc ChangeLog README.md
	doinitd "${FILESDIR}"/growpart
}

pkg_postinst() {
	elog "Installation of growpart is complete"
	elog "  To start growpart on boot, please type:"
	elog "    rc-update -v add growpart boot"
}

