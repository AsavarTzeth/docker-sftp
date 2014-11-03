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
    docker run --name some-sftp --volumes-from sftp-data -P -d asavartzeth/sftp

This will pull down the tiny [tianon/true](https://registry.hub.docker.com/u/tianon/true/) container (unless you have it already) and set it to share /data/volume. The second command does the deployment, using the shared volume.

The included entrypoint script will check for this volume. If found, it will move all persistent data to this location. This will keep it safe between upgrades & allows for easy backups.

*See **Configuration Options** bellow, regarding $DATA_VOLUME details (defaults to /data/volume)*

##Exposing a file tree to the instance##

    docker run --name some-sftp -v /path/dir:$SFTP_CHROOT/share/dir -P -d asavartzeth/sftp

Preferably you would do this when you first deploy the container. However, you could certainly do the deployment as instructed under **"Deploying a simple sftp instance"**, commit and then re-deploy.

*See **Configuration Options** bellow, regarding $SFTP_CHROOT (defaults to /chroot)*

##Complex configuration##

For information on the syntax of the openssh configuration files, see the official [documentation](http://openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/sshd_config.5?query=sshd_config&sec=5).

If you wish to adapt the default configuration, use something like the following to copy it from a running container:

    docker cp some-sftp:/etc/ssh/sshd_config /some/path

You can use the modified configuration with:

    docker run --name some-sftp -v /some/path:/etc/ssh:ro -P -d asavartzeth/sftp

#Configuration Options#

This is a full list of environment variables that will be used in the configuration of your instance.

- -e `SFTP_USER=...` (defaults to sftp1)
- -e `SFTP_UID=...` (defaults to 2001)
- -e `SFTP_PASS=...` (defaults to randomly generated password)
- -e `SFTP_LOG_LEVEL=...` (defaults to INFO)  
The possible values are: QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, and DEBUG3.

These options are unique to my images. They are here for the purposes of freedom and advanced use cases. If you have no use for them, they will be ignored. **Default is strongly recommended.**

- -e `DATA_VOLUME=...` (defaults to /data/volume)  
*This will set the path of a data volume container. With it you may use a container, such as [tianon/true](https://registry.hub.docker.com/u/tianon/true/), to store your data. Data will be copied and linked automatically.*
- -e `SFTP_CHROOT=...` (defaults to /chroot, or $DATA\_VOLUME/chroot)  
*This sets the chroot directory for the sftp instance. It's root will automatically be copied and linked if a data volume is detected (see above). There should rarely be a reason to touch this.*

#User Feedback#

##Issues##

If you have any problems with or questions about this image, please contact me through a [GitHub](https://github.com/asavartzeth/docker-sftp/issues) issue.

##Contributing##

You are welcome to contribute new features, fixes, or updates, large or small; I always welcome pull requests, and I will do my best to process them without delay.

Before you start to code, I recommend discussing your plans through a GitHub issue, especially for more ambitious contributions. This gives myself, as well as other potential contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
