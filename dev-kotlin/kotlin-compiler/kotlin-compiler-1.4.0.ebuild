# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Kotlin Compiler"

HOMEPAGE="https://kotlinlang.org/"

SRC_URI="https://github.com/JetBrains/kotlin/releases/download/v${PV}/${P}.zip"

LICENSE="Apache-2.0"

SLOT="0"

KEYWORDS="~amd64"

RDEPEND="
	>=virtual/jdk-1.8"

DEPEND="
	${RDEPEND}
	app-arch/zip"

S="${WORKDIR}/${MY_P}/kotlinc"

src_install() {
	local kotlin_dir="${EPREFIX}/usr/share/${PN}-${SLOT}"

	insinto "${kotlin_dir}"

	doins -r bin/ lib/

	fperms 755 "${kotlin_dir}/bin/kotlin"
	fperms 755 "${kotlin_dir}/bin/kotlinc"
	fperms 755 "${kotlin_dir}/bin/kotlinc-jvm"

	dosym "${kotlin_dir}/bin/kotlin" "/usr/bin/kotlin"
	dosym "${kotlin_dir}/bin/kotlinc" "/usr/bin/kotlinc"
	dosym "${kotlin_dir}/bin/kotlinc-jvm" "/usr/bin/kotlinc-jvm"
}
