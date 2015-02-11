#Supported tags and respective `Dockerfile` links#

- [`6`, `6.6`, `latest` *(Dockerfile)*](https://github.com/AsavarTzeth/docker-sftp/blob/master/Dockerfile)

#What is OpenSSH?#

OpenSSH (OpenBSD Secure Shell) is a set of computer programs that provides encrypted communication sessions over a computer network using the SSH protocol. It was created as an open source alternative to the proprietary Secure Shell software suite offered by SSH Communications Security.

> [wikipedia.org/wiki/OpenSSH](https://en.wikipedia.org/wiki/OpenSSH)

![openssh](http://openssh.com/images/openssh.gif)

#Instructions#

##Usage##

* UID
* By default the contaier helper script will add a user (sftp1) and generate a random 12 character password. For security reasons this password will not be put in the log (like some containers). You may access your random password using:


    docker cp

##Examples##

###Single volume###

    docker run --name sftp \
		-v /host/dir:/chroot/share/dir \
		-p 30022:22 -d asavartzeth/sftp

Simple deployment for accessing a single directory.

###Multiple volumes###

    docker run --name sftp \
		-v /host/dir1:/chroot/share/dir1 \
		-v /host/dir2:/chroot/share/dir2 \
		-v /host/dir3:/chroot/share/dir3 \
		-p 30022:22 -d asavartzeth/sftp

To access more than one directory you simply add more volumes.

###Using data volumes (Recommended)###

    docker run --name sftp \
		-v /chroot/.ssh \
		-v /etc/ssh \
		-v /host/dir:/chroot/share/dir \
		-p 30022:22 -d asavartzeth/sftp

This adds volumes that will preserve ssh keys & config files.

No volumes are enabled by default in the Dockerfile, so please do consider your preferred method of data storage. Other methods include data volume containers & storing data in a host directory (see bellow).

###Using a data volume container###

    docker run --name sftp-data -v /data/sftp tianon/true

This will pull down the tiny [tianon/true](https://registry.hub.docker.com/u/tianon/true/) container (unless you have it already) and set it to share **/data/sftp** (customizable via `$SFTP_DATA_DIR`).

    docker run --name sftp \
		--volumes-from sftp-data \
		-v /host/dir:/data/sftp/chroot/share/dir \
		-p 30022:22 -d asavartzeth/sftp

At runtime the included helper script will check for the presence of `$SFTP_DATA_DIR`. If found, it will automatically rsync all important data to this data volume. This makes using dedicated data containers very simple.

See **Configuration Options** bellow, for more details. `$SFTP_DATA_DIR` defaults to **/data/sftp**.

###Storing data in a host directory###

    docker run --name sftp \
		-v /host/data-dir:/data/sftp \
        -v /host/dir:/data/sftp/chroot/share/dir \
		-p 30022:22 -d asavartzeth/sftp

This uses the same functionallity in the helper script as when using data volume containers (see previous). This makes it very simple to store data anywhere on the host.

See **Configuration Options** bellow, for more details. `$SFTP_DATA_DIR` defaults to **/data/sftp**.

###Using configuration options###

    docker run --name sftp \
		-e SFTP_USER=username \
		-e SFTP_PASS=password \
		-e SFTP_UID=1001 \
		-v /host/dir:chroot/share/dir \
		-p 30022:22 -d asavartzeth/sftp

The environment variables listed under **Configuration Options** allows you to set a username, UID, password, generate a ssh key and more.

You will have to always have to set custom UID to make changes in your mou

See **Configuration Options** bellow, for more details.

###Adding a ssh-key###
(coming soon)

###Generate a new ssh key###
(coming soon)

##Configuration Options##

This is a full list of environment variables that is honored by the included helper script.

- `SFTP_USER=...` (defaults to sftp1)
- `SFTP_UID=...` (defaults to 2001)
- `SFTP_PASS=...` (defaults to randomly generated password)  
- `SFTP_KEYPASS=...` (no default, sets a passphrase and generates a ssh key)
- `SFTP_DATA_DIR=...` (defaults to /data/sftp) (If no volume is found, it reverts to /)  
*This will set the absolute path of a data volume. It is used by the helper script, to enable the transfer of application data to an empty location. The supplied volume could be a data volume container, such as [tianon/true](https://registry.hub.docker.com/u/tianon/true/), or mapped to a location on your host.*

##Advanced configuration##

For information on the syntax of the openssh configuration files, see the official [documentation](http://openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/sshd_config.5?query=sshd_config&sec=5).

If you wish to adapt the default configuration, use something like the following to copy it from a running container:  
  
    docker cp some-sftp:/etc/ssh/sshd_config /some/path  

You can use the modified configuration with:

    docker run --name some-sftp -v /some/path:/etc/ssh/sshd_config:ro -P -d asavartzeth/sftp

#User Feedback#

##Issues##

If you have any problems with or questions about this image, please contact me through a [GitHub](https://github.com/asavartzeth/docker-sftp/issues) issue.  

##Contributing##
  
You are welcome to contribute new features, fixes, or updates, large or small; I always welcome pull requests, and I will do my best to process them without delay.

Before you start to code, I recommend discussing your plans through a GitHub issue, especially for more ambitious contributions. This gives myself, as well as other potential contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
