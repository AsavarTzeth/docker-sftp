#!/bin/bash

# Copyright (c) 2014, Patrik Nilsson
# All rights reserved.

# This script is licensed under the BSD 2-Clause License.
# See LICENSE file for full legal information.

set -e

echo -e >&2 '\nRunning helper script ...\n'

: ${SFTP_USER:=sftp1}
: ${SFTP_UID:=1000}

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

#TODO Add more robust way of detecting a volume, compared to a simple directory.

if [ ! -d $SFTP_DATA_DIR ]; then
	SFTP_DATA_DIR="/"
	SFTP_CHROOT="/chroot"
	if [ ! -f /firstrun ]; then
		echo >&2 'Notice: data volume not found! - skipping ...'
		echo >&2 '  Data is important. Make sure you have read & understood "Managing Data in Containers",'
		echo >&2 '  in the official docker documentation. Examples tailored to this container may be found in the README.'
	fi
else
	# Set chroot to data volume container
	SFTP_CHROOT="$SFTP_DATA_DIR/chroot"
	set_config 'ChrootDirectory' "$SFTP_CHROOT"
	# If no old data exist on volume, transfer persistant data
	if [ -e ${SFTP_DATA_DIR}${CONF_SSH} ]; then
		echo >&2 'Notice: data volume found, but data is already present! - linking ...'
	else
		echo >&2 'Data volume found! - copying now ...'
		mkdir -p ${SFTP_DATA_DIR}${CONF_SSH}
		cp -ax $CONF_SSH/* ${SFTP_DATA_DIR}${CONF_SSH}/
		echo >&2 "Success! Persistant data transfered to $SFTP_DATA_DIR."
	fi
	# Symlink ssh config and keys to data volume
	rm $CONF_SSH/*
	ln -s ${SFTP_DATA_DIR}${CONF_SSH}/* ${CONF_SSH}/
	#TODO More robust checking that data is truly copied and all links have been made.
fi

#TODO Check for existance of $SFTP_PUB_KEY in %h/.ssh and add to %h/.ssh/authorized_keys.
# Only alternative, is adding more files to sshd_config AuthorizedKeysFile, but this does not scale well.

# Create the chroot directory
mkdir -p $SFTP_CHROOT && chmod 555 $SFTP_CHROOT

# Separate the user input syntax into arrays
IFS=';' read -a users <<< "$SFTP_USER"
IFS=';' read -a passwords <<< "$SFTP_PASS"
IFS=';' read -a uids <<< "$SFTP_UID"
IFS=';' read -a gids <<< "$SFTP_GID"

# Run user setup loop
n=0
for i in "${users[@]}"; do
	user="${users[n]}"
	pass="${passwords[n]}"
	uid="${uids[n]}"
	gid="${gids[n]}"

	useraddParams="-M -N -d /$user -s /usr/sbin/nologin"

	if [ -z "$pass" -o "$pass" == "random" ]; then
		pass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1 | grep -i '[a-zA-Z0-9]'`
	fi

	if [ -n "$uid" ]; then
		useraddParams="$useraddParams -o -u $uid"
	fi

	if [ -n "$gid" ]; then
		useraddParams="$useraddParams -g $gid"
		groupaddParams="-g $gid"
	fi

	groupCheck=$(getent group $gid > /dev/null; echo $?)
	if [ $groupCheck -ne 0 ]; then
		groupadd $groupaddParams "$gid"
	fi

	userCheck=$(getent passwd $uid > /dev/null; echo $?)
	if [ $userCheck -ne 0 ]; then
		useradd $useraddParams "$user"
		mkdir -p $SFTP_CHROOT/$user
	fi

	chown root:root $SFTP_CHROOT/$user
	chmod 755 $SFTP_CHROOT/$user

	# Checks if passwords have been set, using
	if [ ! -f /sftp_pass ]; then
		echo "$user:$pass" | chpasswd $chpasswdParams
		echo "$user:$pass" >> sftp_pass; chmod 600 sftp_pass
	fi

	n=$(($n+1))
done

if [ ! -f /firstrun ]; then
	# Echo quickstart guide to logs
	echo
	echo '================================================================================='
	echo 'Your sftp container is now ready to use!'
	echo
	echo 'For security reasons the user credentials are not listed here.'
	echo 'To get the passwords run this:'
	echo "docker cp some-container:/sftp_pass ."
	echo
	echo 'For more information, see the official README.md'
	echo 'Link: http://registry.hub.docker.com/u/asavartzeth/sftp/'
	echo 'Link: http://github.com/AsavarTzeth/docker-sftp/'
	echo '================================================================================='
	echo
fi

echo -e 'Runtime helper script finished!'
echo -e 'Running /usr/sbin/sshd ...\n'

# Used as identifier for first-run-only stuff
touch /firstrun

exec "$@"
