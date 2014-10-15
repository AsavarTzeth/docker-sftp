#!/bin/bash
set -e

: ${SFTP_USER:=sftp1}
: ${SFTP_UID:=2001}
: ${SFTP_UMASK:=002}
: ${SSH_USER:=ssh1}
: ${SSH_UID:=3001}

# Check for conflicts, then do user setup.
if [ -e /home/sftp/$SFTP_USER -o -e /home/ssh/$SSH_USER ]; then
	echo >&2 'warning: conflict in user setup occured! - skipping...'
else
	useradd -Ud /$SFTP_USER -u $SFTP_UID -s /usr/bin/rssh -G sftpusers $SFTP_USER
	useradd -Ud /$SSH_USER -u $SSH_UID -s /usr/bin/bash -G sshusers $SSH_USER
	mkdir -p /home/sftp/$SFTP_USER /home/ssh/$SSH_USER
	chown $SFTP_USER:$SFTP_USER /home/sftp/$SFTP_USER
	chown $SSH_USER:$SSH_USER /home/ssh/$SSH_USER
	chmod 700 /home/sftp/$SFTP_USER && chmod 700 /home/ssh/$SSH_USER
	if [ -z $SFTP_PASS ]; then SFTP_PASS=`pwgen -scnB1 12`; fi
	if [ -z $SSH_PASS ]; then SSH_PASS=`pwgen -scnB1 12`; fi
	echo $SFTP_PASS > /home/sftp/$SFTP_USER/sftp_pass && echo $SSH_PASS > /home/ssh/$SSH_USER/ssh_pass
	sed -ri \
	-e "\$a\ \n# Added security settings, by Dockerfile (asavartzeth/ssh-sftp)" \
	-e "\$auser=$SFTP_USER:$SFTP_UMASK:10010" $CONF_RSSH/rssh.conf
fi

: ${SSH_LOG_LEVEL:=INFO}

set_config() {
    key="$1"
    value="$2"
    if [ "$config_file" = "$CONF_SSH/sshd_config" ]; then
        sed -ri "s|($key).*|\1 $value|g" $config_file
    fi
}

config_file="$CONF_SSH/sshd_config"
set_config 'LogLevel' "$SSH_LOG_LEVEL"

: ${DATA_VOLUME:=/data/volume}

# Check for existance of default data volume.
echo >&2 'Searching for mounted data volumes...'
if ! [ -e $DATA_VOLUME ]; then
	echo >&2 'Warning: Data volume not found!'
	echo >&2 ' Did you forget to do --volumes-from data-container ?'
	echo >&2 ' If you choose to store your important data in another way, be safe & ignore this warning.'
else
	# If no old data exist on volume, transfer persistant data.
	if [ -e $DATA_VOLUME/etc/ssh ]; then
		echo >&2 'Data volume found! But data already exists - skipping...'
	else
		echo >&2 'Data volume found! - copying now...'
		mkdir -p ${DATA_VOLUME}${CONF_SSH}
		rsync -arxq $CONF_SSH/ ${DATA_VOLUME}${CONF_SSH}/
		echo >&2 "Complete! Persistant data has successfully been copied to $DATA_VOLUME."
	fi
	# Symlink ssh config and keys to data volume
	rm $CONF_SSH/*
	ln -s ${DATA_VOLUME}${CONF_SSH}/* ${CONF_SSH}/
fi

# Echo quickstart guide to logs
echo '================================================================================='
echo 'Your ssh/sftp container is now ready to use!'
echo
echo 'To get started login to your ssh/sftp container with these credentials:'
echo "SFTP: Username: $SFTP_USER	SSH: Username: $SSH_USER"
echo
echo 'For security reasons passwords are not listed here.'
echo 'To get the password run this: (notice sftp|ssh)'
echo "docker cp some-container:/home/(sftp|ssh)/$SFTP_USER/(sftp|ssh)_pass"
echo 'When done, you should remove these files from both the container & the host.'
echo
echo 'For more information, see the official README.md'
echo 'Link: http://https://registry.hub.docker.com/u/asavartzeth/ssh-sftp/'
echo 'Link: http://github.com/AsavarTzeth/docker-ssh-sftp/'
echo '================================================================================='

exec "$@"
