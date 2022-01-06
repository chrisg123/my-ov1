# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

EGIT_REPO_URI="https://github.com/fwcd/${PN}"
EGIT_BRANCH="main"

DESCRIPTION="Intelligent Kotlin support for any editor/IDE using the Language Server Protocol."

HOMEPAGE="https://github.com/fwcd/${PN}"

LICENSE="MIT"

SLOT="0"

KEYWORDS="~amd64"

RDEPEND="
	>=virtual/jdk-1.8"

DEPEND="
	${RDEPEND}
	=dev-java/gradle-bin-7.1.1
	=dev-java/openjdk-11.0.12_p7"

src_unpack() {
	unpack "${FILESDIR}/${P}.gradle-caches-modules-2.tar"

	debug-print-function ${FUNCNAME} "$@"
	_git-r3_env_setup
	git-r3_src_fetch
	git-r3_checkout

}

src_compile() {
	export JAVA_HOME="/usr/lib64/openjdk-11"
	export JAVA_TOOL_OPTIONS="-Duser.home=${WORKDIR}"
	gradle --offline --console=verbose --info :server:installDist
}


src_install() {
	local kotlin_dir="${EPREFIX}/usr/share/${PN}-${SLOT}"
	insinto "${kotlin_dir}"

	doins -r server/build/install/server/
	fperms 755 "${kotlin_dir}/server/bin/${PN}"
	dosym "${kotlin_dir}/server/bin/${PN}" "/usr/bin/${PN}"
}
