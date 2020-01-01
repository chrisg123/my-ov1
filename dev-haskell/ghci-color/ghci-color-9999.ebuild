# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3

DESCRIPTION="A script to colorizes ghci output."
HOMEPAGE="https://github.com/rhysd/ghci-color"
EGIT_REPO_URI="https://github.com/rhysd/ghci-color"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

src_install() {
	dobin ghci-color
}
