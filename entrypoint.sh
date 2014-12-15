#!/bin/bash

# Copyright (c) 2014, Patrik Nilsson
# All rights reserved.

# This script is licensed under the BSD 2-Clause License.
# See LICENSE file for full legal information.

set -e

: ${SFTP_USER:=sftp1}
: ${SFTP_UID:=2001}

# Edit settings in relevant config files
set_config() {
    key="$1"
    value="$2"
    if [ "$config_file" = "$CONF_SSH/sshd_config" ]; then
        sed -ri "s|($key).*|\1 $value|g" $config_file
    fi
}
config_file="$CONF_SSH/sshd_config"

: ${SFTP_DATA_DIR:=/data/sftp}

# Check for the existance of $SFTP_DATA_DIR, default (/data/sftp).
echo -e >&2 "\nRunning search for data volume at $SFTP_DATA_DIR..."
#TODO Add more robust way of detecting a volume, compared to a simple directory.
if ! [ -e $SFTP_DATA_DIR ]; then
	SFTP_DATA_DIR="/"
	SFTP_CHROOT="/chroot"
	echo >&2 'Notice: data volume not found! -  deployment...'
	echo >&2 '  Data is important. Make sure you have read & understood "Managing Data in Containers",'
	echo >&2 '  in the official docker documentation. Examples for this container can be found in the README.'
else
	# Set chroot to data volume container
	SFTP_CHROOT="$SFTP_DATA_DIR/chroot"
	set_config 'ChrootDirectory' "$SFTP_CHROOT"
	# If no old data exist on volume, transfer persistant data.
	if [ -e ${SFTP_DATA_DIR}${CONF_SSH} ]; then
		echo >&2 'Notice: data volume found, but data is already present! - skipping...'
	else
		echo >&2 'Data volume found! - copying now...'
		mkdir -p ${SFTP_DATA_DIR}${CONF_SSH}
		cp -ax $CONF_SSH/* ${SFTP_DATA_DIR}${CONF_SSH}/
	fi
	# Symlink ssh config and keys to data volume
	rm $CONF_SSH/*
	ln -s ${SFTP_DATA_DIR}${CONF_SSH}/* ${CONF_SSH}/
	#TODO More robust checking that data is truly copied and all links have been made.
	echo >&2 "Success! Persistant data transfered to $SFTP_DATA_DIR."
fi

#TODO Check for existance of $SFTP_PUB_KEY in %h/.ssh and add to %h/.ssh/authorized_keys.
# Only alternative, is adding more files to sshd_config AuthorizedKeysFile, but this does not scale well.

: ${SFTP_HOME:=$SFTP_CHROOT/share}

# Create and setup chroot and sftp home
mkdir -p $SFTP_HOME && chmod 555 $SFTP_CHROOT && chmod 775 $SFTP_HOME && chmod g+s $SFTP_HOME
chgrp sftpusers $SFTP_HOME

# Check not only for existance of user, but if either username or uid is in use.
echo >&2 "Running id check for user:$SFTP_USER and uid:$SFTP_UID..."
CHECK1=$(getent passwd $SFTP_USER > /dev/null; echo $?)
CHECK2=$(getent passwd $SFTP_UID > /dev/null; echo $?)

# Check for conflicts, then do user setup.
if [ $CHECK1 -eq 0 -o $CHECK2 -eq 0 ]; then
	echo >&2 'Notice: user id conflict - skipping...'
	echo >&2 "  The user $SFTP_USER and/or uid $SFTP_UID is already in use."
	echo >&2 '  In all cases except first run, this is normal and can safely be ignored. '
else
	useradd -Ud /share -u $SFTP_UID -s /usr/sbin/nologin -G sftpusers $SFTP_USER
	if [ -z $SFTP_PASS ]; then
		SFTP_PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1 | grep -i '[a-zA-Z0-9]'`
	fi
	echo $SFTP_PASS > sftp_pass; chmod 600 sftp_pass
	echo "$SFTP_USER:$SFTP_PASS" | chpasswd && unset SFTP_PASS
	echo "Success! User setup completed without conflict."

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
	echo "docker cp some-container:/sftp_pass ."
	echo
	echo 'For more information, see the official README.md'
	echo 'Link: http://registry.hub.docker.com/u/asavartzeth/sftp/'
	echo 'Link: http://github.com/AsavarTzeth/docker-sftp/'
	echo '================================================================================='
fi

echo -e '\nRuntime helper script finished!'
echo -e 'Running "/usr/sbin/sshd"...\n'

exec "$@"
