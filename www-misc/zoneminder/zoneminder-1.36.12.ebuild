# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit perl-functions readme.gentoo-r1 cmake depend.apache flag-o-matic systemd

MY_CRUD_VERSION="3.1.0-zm"

MY_PN="ZoneMinder"
MY_CRUD_V="14292374ccf1328f2d5db20897bd06f99ba4d938"
MY_CAKEPHP_V="ea90c0cd7f6e24333a90885e563b5d30b793db29"
MY_RTSP_V="cd7fd49becad6010a1b8466bfebbd93999a39878"

DESCRIPTION="full-featured, open source, state-of-the-art video surveillance software system"
HOMEPAGE="http://www.zoneminder.com/"
SRC_URI="
	https://github.com/${MY_PN}/${PN}/archive/refs/${PV}.tar.gz -> ${P}.tar.gz
	https://api.github.com/repos/FriendsOfCake/crud/tarball/${MY_CRUD_V} -> Crud-${MY_CRUD_V}.tar.gz
	https://api.github.com/repos/${PN}/RtspServer/tarball/${MY_RTSP_V} -> RtspServer-${MY_RTSP_V}.tar.gz
	https://api.github.com/repos/${PN}/CakePHP-Enum-Behavior/tarball/${MY_CAKEPHP_V} -> CakePHP-Enum-Behavior-${MY_CAKEPHP_V}.tar.gz
"

LICENSE="GPL-2"
KEYWORDS="~amd64"
IUSE="curl encode ffmpeg gcrypt gnutls +mmap +ssl libressl vlc"
SLOT="0"

REQUIRED_USE="
	|| ( ssl gnutls )
"

DEPEND="
	app-eselect/eselect-php[apache2]
	dev-lang/perl:=
	dev-lang/php:7.4[apache2,cgi,curl,gd,inifile,pdo,mysql,mysqli,sockets]
	dev-libs/libpcre
	dev-perl/Archive-Zip
	dev-perl/Class-Std-Fast
	dev-perl/Data-Dump
	dev-perl/Date-Manip
	dev-perl/Data-UUID
	dev-perl/DBD-mysql
	dev-perl/DBI
	dev-perl/IO-Socket-Multicast
	dev-perl/SOAP-WSDL
	dev-perl/Sys-CPU
	dev-perl/Sys-MemInfo
	dev-perl/URI-Encode
	dev-perl/libwww-perl
	dev-perl/Number-Bytes-Human
	dev-perl/JSON-MaybeXS
	dev-php/pecl-apcu:*
	dev-perl/Crypt-Eksblowfish
	dev-perl/Data-Entropy
	dev-perl/HTTP-Lite
	dev-perl/MIME-Lite
	dev-perl/DateTime
	sys-auth/polkit
	sys-libs/zlib
	dev-python/mysqlclient
	ffmpeg? ( virtual/ffmpeg )
	encode? ( media-libs/libmp4v2 )
	virtual/httpd-php:*
	virtual/jpeg:0
	virtual/mysql
	virtual/perl-ExtUtils-MakeMaker
	virtual/perl-Getopt-Long
	virtual/perl-Sys-Syslog
	virtual/perl-Time-HiRes
	www-servers/apache
	curl? ( net-misc/curl )
	gcrypt? ( dev-libs/libgcrypt:0= )
	gnutls? ( net-libs/gnutls )
	mmap? ( dev-perl/Sys-Mmap )
	ssl? ( dev-libs/openssl:0= )
	vlc? ( media-video/vlc[live] )
"
RDEPEND="${DEPEND}"

# we cannot use need_httpd_cgi here, since we need to setup permissions for the
# webserver in global scope (/etc/zm.conf etc), so we hardcode apache here.
need_apache

PATCHES=(
)

MY_ZM_WEBDIR=/usr/share/zoneminder/www

src_prepare() {
	cmake_src_prepare

	rm "${WORKDIR}/${P}/conf.d/README" || die

	rmdir "${S}/web/api/app/Plugin/Crud" || die
	mv "${WORKDIR}/FriendsOfCake-crud-${MY_CRUD_V:0:7}" "${S}/web/api/app/Plugin/Crud" || die

	rmdir "${S}/web/api/app/Plugin/CakePHP-Enum-Behavior" || die
	mv "${WORKDIR}/${MY_PN}-CakePHP-Enum-Behavior-${MY_CAKEPHP_V:0:7}" "${S}/web/api/app/Plugin/CakePHP-Enum-Behavior" || die

	rmdir "${S}/dep/RtspServer" || die
	mv "${WORKDIR}/${MY_PN}-RtspServer-${MY_RTSP_V:0:7}" "${S}/dep/RtspServer" || die
}

src_configure() {
	append-cxxflags -D__STDC_CONSTANT_MACROS
	perl_set_version
	export TZ=UTC # bug 630470
	mycmakeargs=(
		-DZM_PERL_SUBPREFIX=${VENDOR_LIB#/usr}
		-DZM_TMPDIR=/var/tmp/zm
		-DZM_SOCKDIR=/var/run/zm
		-DZM_CACHEDIR=/var/cache/zoneminder
		-DZM_WEB_USER=apache
		-DZM_WEB_GROUP=apache
		-DZM_WEBDIR=${MY_ZM_WEBDIR}
		-DZM_NO_MMAP="$(usex mmap OFF ON)"
		-DZM_NO_X10=OFF
		-DZM_NO_FFMPEG="$(usex ffmpeg OFF ON)"
		-DZM_NO_CURL="$(usex curl OFF ON)"
		-DZM_NO_LIBVLC="$(usex vlc OFF ON)"
		-DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL="$(usex ssl OFF ON)"
		-DHAVE_LIBGNUTLS="$(usex gnutls ON OFF)"
		-DHAVE_LIBGCRYPT="$(usex gcrypt ON OFF)"
	)

	cmake_src_configure

}

src_install() {
	cmake_src_install

	# the log directory
	keepdir /var/log/zm
	fowners apache:apache /var/log/zm

	# the logrotate script
	insinto /etc/logrotate.d
	newins distros/ubuntu2004/zoneminder.logrotate zoneminder

	# now we duplicate the work of zmlinkcontent.sh
	keepdir /var/lib/zoneminder /var/lib/zoneminder/images /var/lib/zoneminder/events /var/lib/zoneminder/api_tmp
	fperms -R 0775 /var/lib/zoneminder
	fowners -R apache:apache /var/lib/zoneminder
	dosym /var/lib/zoneminder/images ${MY_ZM_WEBDIR}/images
	dosym /var/lib/zoneminder/events ${MY_ZM_WEBDIR}/events
	dosym /var/lib/zoneminder/api_tmp ${MY_ZM_WEBDIR}/api/app/tmp

	# the cache directory
	keepdir /var/cache/zoneminder
	fowners apache:apache /var/cache/zoneminder

	# bug 523058
	keepdir ${MY_ZM_WEBDIR}/temp
	fowners -R apache:apache ${MY_ZM_WEBDIR}/temp

	# the configuration file
	fperms 0640 /etc/zm.conf
	fowners root:apache /etc/zm.conf

	# init scripts etc
	newinitd "${FILESDIR}"/init.d zoneminder
	newconfd "${FILESDIR}"/conf.d zoneminder

	# systemd unit file
	systemd_dounit "${FILESDIR}"/zoneminder.service

	cp "${FILESDIR}"/10_zoneminder.conf "${T}"/10_zoneminder.conf || die
	sed -i "${T}"/10_zoneminder.conf -e "s:%ZM_WEBDIR%:${MY_ZM_WEBDIR}:g" || die

	if [[ ${PV} == 9999 ]]; then
		dodoc README.md "${T}"/10_zoneminder.conf
	else
		dodoc CHANGELOG.md CONTRIBUTING.md README.md "${T}"/10_zoneminder.conf
	fi

	perl_delete_packlist

	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog

	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		elog "Fresh installs of zoneminder require a few additional steps. Please read the README.gentoo"
	else
		local v
		for v in ${REPLACING_VERSIONS}; do
			if ! version_is_at_least ${PV} ${v}; then
				elog "You have upgraded zoneminder and may have to upgrade your database now using the 'zmupdate.pl' script."
			fi
		done
	fi
}
