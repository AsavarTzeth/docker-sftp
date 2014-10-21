#!/bin/bash

# Copyright (c) 2014, Patrik Nilsson
# All rights reserved.

# This script is licensed under the BSD 2-Clause License.
# See LICENSE file for full legal information.

set -e

: ${SFTP_USER:=sftp1}
: ${SFTP_UID:=2001}
: ${SFTP_CHROOT:=/data/volume/chroot}
: ${SFTP_LOG_LEVEL:=INFO}

set_config() {
    key="$1"
    value="$2"
    if [ "$config_file" = "$CONF_SSH/sshd_config" ]; then
        sed -ri "s|($key).*|\1 $value|g" $config_file
    fi
}

config_file="$CONF_SSH/sshd_config"
set_config 'LogLevel' "$SFTP_LOG_LEVEL"
set_config 'ChrootDirectory' "$SFTP_CHROOT"

: ${DATA_VOLUME:=/data/volume}

# Check for existance of default data volume.
echo >&2 'Searching for mounted data volumes...'
if ! [ -e $DATA_VOLUME ]; then
	echo >&2 'Warning: Data volume not found!'
	echo >&2 ' Did you forget to do --volumes-from data-container ?'
	echo >&2 ' If you choose to store your important data in another way, be safe & ignore this warning.'
	# Reset chroot
	SFTP_CHROOT="/chroot"
else
	# If no old data exist on volume, transfer persistant data.
	if [ -e $DATA_VOLUME/etc/ssh ]; then
		echo >&2 'Data volume found! But data already exists - skipping...'
	else
		echo >&2 'Data volume found! - copying now...'
		mkdir -p ${DATA_VOLUME}${CONF_SSH}
		cp -ax $CONF_SSH/* ${DATA_VOLUME}${CONF_SSH}/
		echo >&2 "Complete! Persistant data has successfully been copied to $DATA_VOLUME."
	fi
	# Symlink ssh config and keys to data volume
	rm $CONF_SSH/*
	ln -s ${DATA_VOLUME}${CONF_SSH}/* ${CONF_SSH}/
fi

# Check for conflicts, then do user setup.
if [ -e $SFTP_CHROOT/files ]; then
	echo >&2 'warning: conflict in user setup occured! - skipping...'
else
	useradd -Ud /files -u $SFTP_UID -s /usr/sbin/nologin -G sftpusers $SFTP_USER
	mkdir -p $SFTP_CHROOT/files; chmod 111 $SFTP_CHROOT
	chgrp sftpusers $SFTP_CHROOT/files; chmod 770 $SFTP_CHROOT/files
	if [ -z $SFTP_PASS ]; then SFTP_PASS=`pwgen -scnB1 12`; fi
	echo $SFTP_PASS > sftp_pass; chmod 600 sftp_pass
	echo "$SFTP_USER:$SFTP_PASS" | chpasswd
fi

# Echo quickstart guide to logs
echo
echo '================================================================================='
echo 'Your sftp container is now ready to use!'
echo
echo 'Login to your new sftp container with these credentials:'
echo "Username: $SFTP_USER"
echo
echo 'For security reasons passwords are not listed here.'
echo 'To get the password run this:'
echo "docker cp some-container:/sftp_pass"
echo
echo 'For more information, see the official README.md'
echo 'Link: http://registry.hub.docker.com/u/asavartzeth/sftp/'
echo 'Link: http://github.com/AsavarTzeth/docker-sftp/'
echo '================================================================================='

exec "$@"
