#Supported tags and respective `Dockerfile` links#

- [`6`, `6.6`, `latest` *(Dockerfile)*](https://github.com/AsavarTzeth/docker-sftp/blob/master/Dockerfile)

#What is OpenSSH?#

OpenSSH (OpenBSD Secure Shell) is a set of computer programs that provides encrypted communication sessions over a computer network using the SSH protocol. It was created as an open source alternative to the proprietary Secure Shell software suite offered by SSH Communications Security.

> [wikipedia.org/wiki/OpenSSH](https://en.wikipedia.org/wiki/OpenSSH)

![openssh](http://openssh.com/images/openssh.gif)

#How to use this image#

##Deploying a simple sftp instance##

    docker run --name some-sftp -P -d asavartzeth/sftp

The port will be randomly chosen by the docker daemon. You may of course specify any port you wish.

    docker run --name some-sftp -p xxxx:22 -d asavartzeth/sftp

##Deploying, using a data volume container##

    docker run --name sftp-data -v /data/volume tianon/true
    docker run --name some-sftp --volumes-from sftp-data -d -P asavartzeth/sftp

This will pull down the tiny tianon/true container (unless you have it already) and set it to share /data/volume. The SFTP instance will then bind mount this location.

The included entrypoint script will then check for this bind mount, it will then, if found, copy the data volume and move all persistent data to this location. This will keep it safe between upgrades & allows for easy backups.

##Exposing a file tree to the instance##

    docker run --name some-sftp -v /your/files:$SFTP_CHROOT/files -P -d asavartzeth/sftp

Preferably you would do this when you first deploy the container. However, you could certainly do the deployment as instructed above, commit and then re-deploy.

*See details of the $SFTP_CHROOT environment variable bellow.*

##Complex configuration##

For information on the syntax of the openssh configuration files, see the official [documentation](http://openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/sshd_config.5?query=sshd_config&sec=5).

If you wish to adapt the default configuration, use something like the following to copy it from a running container:

    docker cp some-sftp:/etc/ssh/sshd_config /some/path

You can use the modified configuration with:

    docker run --name some-sftp -v /some/path:/etc/ssh:ro -P -d asavartzeth/sftp

#Configuration Options#

This is a full list of environment variables that may be used to configure your container.

- -e `SFTP_USER=...` (defaults to sftp1)
- -e `SFTP_UID=...` (defaults to 2001)  
- -e `SFTP_CHROOT=...` (defaults to /chroot, or $DATA\_VOLUME/chroot if volume is detected)
- -e `SFTP_LOG_LEVEL=...` (defaults to /data/volume)  
The possible values are: QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, and DEBUG3.
- -e `DATA_VOLUME=...` (defaults to /data/volume)  
Unique to my setup script. It allows you to set a custom data volume (container) you may be using, ex. `docker run -v /data/volume data-image`. **Default is recommended.**

#User Feedback#

##Issues##

If you have any problems with or questions about this image, please contact me through a [GitHub](https://github.com/asavartzeth/docker-sftp/issues) issue.

##Contributing##

You are welcome to contribute new features, fixes, or updates, large or small; I always welcome pull requests, and I will do my best to process them without delay.

Before you start to code, I recommend discussing your plans through a GitHub issue, especially for more ambitious contributions. This gives myself, as well as other potential contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
