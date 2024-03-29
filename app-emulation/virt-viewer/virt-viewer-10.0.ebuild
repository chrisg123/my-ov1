# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson xdg

DESCRIPTION="Graphical console client for connecting to virtual machines"
HOMEPAGE="https://virt-manager.org/"
SRC_URI="https://virt-manager.org/download/sources/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+libvirt sasl +spice +vnc"

RDEPEND=">=dev-libs/libxml2-2.6
	x11-libs/gtk+:3
	libvirt? (
		>=app-emulation/libvirt-0.10.0[sasl?]
		app-emulation/libvirt-glib
	)
	spice? ( >=net-misc/spice-gtk-0.35[sasl?,gtk3] )
	vnc? ( >=net-libs/gtk-vnc-0.5.0[sasl?,gtk3(+)] )"
DEPEND="${RDEPEND}
	dev-lang/perl
	>=dev-util/intltool-0.35.0
	virtual/pkgconfig
	spice? ( >=app-emulation/spice-protocol-0.12.10 )"

REQUIRED_USE="|| ( spice vnc )"

PATCHES=(
	"${FILESDIR}/${P}-hide-window-decoration.patch"
	"${FILESDIR}/${P}-dont-grab-keyboard.patch"
	"${FILESDIR}/${P}-disable-shift-fn-accel-keys.patch"
)

src_configure() {
	local emesonargs=(
		$(meson_feature libvirt libvirt)
		$(meson_feature vnc vnc)
		$(meson_feature spice spice)
	)
	meson_src_configure
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}
