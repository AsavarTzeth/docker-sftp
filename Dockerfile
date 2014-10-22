FROM debian:wheezy
MAINTAINER Patrik Nilsson <asavar@tzeth.com>

ENV OPENSSH_VERSION 1:6.6p1-4~bpo70+1

RUN echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list \
	&& apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	expect \
	openssh-client=$OPENSSH_VERSION \
	openssh-server=$OPENSSH_VERSION \
	openssh-sftp-server=$OPENSSH_VERSION \
	pwgen \
	&& rm -rf /var/lib/apt/lists/*

ENV CONF_SSH /etc/ssh

RUN mkdir -p /var/run/sshd && sed -ri \
	-e "s|\S?(AuthorizedKeysFile).*|\1 %h/.ssh/authorized_keys|g" \
	-e "s|\S?(Banner).*|\1 /etc/banner|g" \
	-e "s|\S?(PermitRootLogin).*|\1 no|g" \
	-e "s|\S?(X11Forwarding).*|\1 no|g" \
	-e "s|\S?(Subsystem sftp).*|\1 internal-sftp|g" \
	-e "\$a\ \n# Added security settings, by Dockerfile (asavartzeth/sftp)" \
	-e "\$aAllowGroups sftpusers" \
	-e "\$aAllowTcpForwarding no" \
	-e "\$aClientAliveInterval 300" \
	-e "\$a\ \nMatch Group sftpusers" \
	-e "\$aChrootDirectory" \
	-e "\$aAllowTCPForwarding no" \
	-e "\$aForceCommand internal-sftp -d %u" $CONF_SSH/sshd_config \
	&& groupadd -g 5001 sftpusers

ADD banner /etc/banner
ADD entrypoint.sh /entrypoint.sh

RUN chmod 744 /entrypoint.sh

# For those that prefer volumes only, over data volume containers.
# Note, if you use the recommended setup these serve no direct purpose.
VOLUME ["/etc/ssh", "/chroot"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
