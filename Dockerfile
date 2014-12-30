FROM debian:wheezy
MAINTAINER Patrik Nilsson <asavartzeth@gmail.com>

ENV CONTAINER_VERSION 2.0

# Runtime dependencies
RUN echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list && \
    echo "deb-src http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list && \
	apt-get update && DEBIAN_FRONTEND=noninteractive \
	apt-get install -y --no-install-recommends \
		adduser \
		libedit2 \
		libncursesw5 \
		libprocps0 \
		libssl1.0.0 \
		libwrap0 \
		procps \
		zlib1g && \
	rm -rf /var/lib/apt/lists/*

# Deb build test sometimes fails with make error "execvp: ./keygen-test: Text file busy"
ENV DEB_BUILD_OPTIONS nocheck

ENV DEB_VERSION 1:6.6p1-4~bpo70+1
ENV SSH_VERSION 6.6p1
ENV HPN_VERSION 14.5
ENV HPN_V 14v5

# Build dependencies (do not keep)
RUN buildDeps=" \
		autoconf \
		automake \
		autotools-dev \
		binutils \
		build-essential \
		cpp \
		cpp-4.7 \
		curl \
		debhelper \
		dh-autoreconf \
		dpkg-dev \
		fakeroot \
		file \
		g++ \
		g++-4.7 \
		gcc \
		gcc-4.7 \
		gettext \
		gettext-base \
		dpkg-dev \
		groff-base \
		html2text \
		intltool-debian \
		libasprintf0c2 \
		libbsd0 \
		libbsd-dev \
		libc-dev-bin \
		libc6-dev \
		libcroco3 \
		libcurl3 \
		libedit-dev \
		libdpkg-perl \
		libffi5 \
		libgettextpo0 \
		libglib2.0-0 \
		libgmp10 \
		libgomp1 \
		libgssapi-krb5-2 \
		libidn11 \
		libitm1 \
		libk5crypto3 \
		libkeyutils1 \
		libkrb5-3 \
		libkrb5support0 \
		libmagic1 \
		libmpc2 \
		libmpfr4 \
		libpipeline1 \
		libpopt0 \
		libquadmath0 \
		librtmp0 \
		libssh2-1 \
		libssl-dev \
		libstdc++6-4.7-dev \
		libtimedate-perl \
		libtinfo-dev \
		libtool \
		libunistring0 \
		libwrap0-dev \
		libxml2 \
		linux-libc-dev \
		m4 \
		man-db \
		patch \
		po-debconf \
		pkg-config \
		quilt \
		zlib1g-dev \
	"; \
	apt-get update && DEBIAN_FRONTEND=noninteractive \
	apt-get install -y --no-install-recommends $buildDeps && \
	mkdir -p /usr/src/hpn-ssh && \
	cd /usr/src/hpn-ssh && \
	patchFile="openssh-${SSH_VERSION}-hpnssh${HPN_V}.diff" && \
	patchURL="http://sourceforge.net/projects/hpnssh/files" && \
	curl -SL "$patchURL/HPN-SSH $HPN_VERSION $SSH_VERSION/${patchFile}.gz/download" -o ${patchFile}.gz && \
	gzip -d ${patchFile}.gz && \
	apt-get source openssh=$DEB_VERSION && \
	cd /usr/src/hpn-ssh/openssh-$SSH_VERSION && \
	quilt pop -qa && \
	quilt import ../$patchFile && \
	quilt push -q && \
	quilt refresh && \
	sed -i \
		-e '1a\openbsd-docs.patch' \
		-e '1a\sshfp_with_server_cert_upstr' \
		-e '2,$d' debian/patches/series \
	&& \
	quilt push -qa && \
	quilt refresh && \
	sed -ri \
		-e 's/(\s\|\s)*(,\s)*(lib|heimdal)(wrap|gtk2\.0|selinux1|krb5|ck-connector|pam(0g|-ssh)*)*-dev(\s\[.*\])*//g' \
		-e 's/(libpam|,\sdh-systemd|xauth|ssh-askpass|ufw)(-ssh|-runtime|-modules)*(\s\(.{6,10}\))*(,\s)*//g' \
		-e '/Package:\sssh/,$d' debian/control && \
	sed -ri \
		-e 's/-(pam|kerberos5|selinux|xauth).*/out-\1/g;s/,systemd//' \
		-e '/flags_udeb/d;/#\sAvoid\slibnsl/,+2d' \
		-e '/-C\s(build-udeb|contrib)|install\s-[po].*debian\//d' \
		-e 's/\s(ASKPASS_PROGRAM.*|build-udeb)//' \
		-e '/(init|pam|systemd_enable):/,+2d;/installdocs:/,+7d' debian/rules \
	&& \
	sed -ri '/authorized_keys\.5/d' debian/openssh-server.install && \
	sed -ri '/ChangeLog.gssapi/d' debian/openssh-client.docs && \
	dpkg-buildpackage -rfakeroot -us -uc -b && \
	dpkg -i /usr/src/hpn-ssh/*.deb && \
	cd /; rm -r /usr/src/hpn-ssh && \
	apt-get purge -y --auto-remove $buildDeps && \
	rm -rf /var/lib/apt/lists/*

COPY banner /etc/banner
COPY entrypoint.sh /entrypoint.sh                                     
COPY sshd_config /etc/ssh/sshd_config

RUN chmod 744 /entrypoint.sh && \
    chmod 644 /etc/ssh/sshd_config

EXPOSE 22/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
