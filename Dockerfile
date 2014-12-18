FROM debian:wheezy
MAINTAINER Patrik Nilsson <asavartzeth@gmail.com>

ENV OPENSSH_VERSION 1:6.6p1-4~bpo70+1

RUN echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -qqy --no-install-recommends \
	openssh-client=$OPENSSH_VERSION \
	openssh-server=$OPENSSH_VERSION \
	openssh-sftp-server=$OPENSSH_VERSION && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd

COPY banner /etc/banner
COPY entrypoint.sh /entrypoint.sh
COPY sshd_config /etc/ssh/sshd_config

RUN chmod 744 /entrypoint.sh && \
    chmod 644 /etc/ssh/sshd_config

ENV CONF_SSH /etc/ssh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
