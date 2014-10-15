FROM ubuntu:14.04
MAINTAINER Patrik Nilsson <asavar@tzeth.com> 

ENV OPENSSH_VERSION 6.6

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	openssh-server \
	pwgen \
	rssh \
	rsync

ENV CONF_SSH /etc/ssh

RUN mkdir -p /var/run/sshd /home/sftp /home/ssh && sed -ri \
	-e "s|\S?(Banner).*|\1 /etc/banner|g" \
	-e "s|\S?(PermitRootLogin).*|\1 no|g" \
	-e "s|\S?(X11Forwarding).*|\1 no|g" \
	-e "s|\S?(Subsystem sftp).*|\1 internal-sftp|g" \
	-e "\$a\ \n# Added security settings, by Dockerfile (asavartzeth/ssh-sftp)" \
	-e "\$aAllowGroups sftpusers" \
	-e "\$aAllowGroups sshusers" \
	-e "\$aAllowTcpForwarding no" \
	-e "\$aClientAliveInterval 300" \
	-e "\$a\ \n Match Group sftpusers" \
	-e "\$aChrootDirectory /home/sftp" \
	-e "\$aAllowTCPForwarding no" \
	-e "\$aForceCommand internal-sftp -d %u" \
	-e "\$a\ \n Match Group sshusers" \
	-e "\$aChrootDirectory /home/ssh" \
	-e "\$aAllowTCPForwarding no" \
	-e "\$aForceCommand internal-sftp -d %u" $CONF_SSH/sshd_config \
	&& groupadd -g 3000 sftpusers \
	&& groupadd -g 4000 sshusers

# Workaround docker volume limitations
# We want volumes for some config files, but not /etc/*
RUN mkdir -p /etc/rssh /etc/auth \
	&& mv /etc/rssh.conf /etc/rssh/ \
	&& ln -s /etc/rssh/* /etc/

ADD banner /etc/banner
ADD entrypoint.sh /entrypoint.sh

RUN chmod 744 /entrypoint.sh \
	&& chmod 111 /home/sftp /home/ssh

# Put low, so changes do not require rebuild.
ENV CONF_RSSH /etc/rssh

# For those that prefer volumes only, over data volume containers.
VOLUME ["/etc/ssh"]
VOLUME ["/etc/rssh"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
