# AsavarTzeth/docker-sftp

## Supported tags and respective `Dockerfile` links

- [`6`, `6.6`, `latest` *(Dockerfile)*](https://github.com/AsavarTzeth/docker-sftp/blob/master/Dockerfile)

## What is OpenSSH?

OpenSSH (OpenBSD Secure Shell) is a set of computer programs that provides encrypted communication sessions over a computer network using the SSH protocol. It was created as an open source alternative to the proprietary Secure Shell software suite offered by SSH Communications Security.

> [wikipedia.org/wiki/OpenSSH](https://en.wikipedia.org/wiki/OpenSSH)

![openssh](http://openssh.com/images/openssh.gif)

## How to use this image

### Deploying a simple sftp instance

    docker run --name some-sftp -P -d asavartzeth/sftp

The port will be randomly chosen by the docker daemon. You may of course specify any port you wish.

    docker run --name some-sftp -p xxxx:22 -d asavartzeth/sftp

By default your data is shared as standard Docker volumes. If you are unsure of what this means or simply have other needs I recommend you read the next section: **"Storing your data"**.

### Storing your data

#### Storing data in a data volume container

    docker run --name sftp-data -v /data/sftp tianon/true
    docker run --name some-sftp --volumes-from sftp-data -P -d asavartzeth/sftp

This will pull down the tiny [tianon/true](https://registry.hub.docker.com/u/tianon/true/) container (unless you have it already) and set it to share /data/sftp. The second command does the deployment as normal, with the addition of mounting the shared volume at /data/sftp.

At runtime the included entrypoint script will check for the presence of $SFTP_DATA_DIR. If found, it will automatically transfer all important data to this location. This will keep it safe between upgrades & could simplify backups.

If you change $SFTP_DATA_DIR, do not forget to change the first command as well.

_See **Configuration Options** bellow, regarding $SFTP_DATA_DIR details (defaults to /data/sftp)_

#### Storing data in a host directory

    docker run --name some-sftp -v /path/container-data/sftp:/data/sftp -P -d asavartzeth/sftp

This is using the same principle as above. But instead of mounting the volume of another container you will mount a host directory.

This is useful in the sense that it could minimize filesystem overhead and would allow you to safekeep your data in a more traditional way. Another thing to note is, if you wish to use zfs, or another filesystem with no Docker backend, this enables a good compromise.

A possible downside to this approach might be lesser portability of your data.

### Exposing files & directories to the instance

    docker run --name some-sftp -v /path/dir:$SFTP_DATA_DIR/chroot/share/dir -P -d asavartzeth/sftp

Preferably you would do this when you first deploy the container. However, you could certainly do the deployment as instructed under **"Deploying a simple sftp instance"**, commit and then re-deploy.

### Complex configuration

For information on the syntax of the openssh configuration files, see the official [documentation](http://openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man5/sshd_config.5?query=sshd_config&sec=5).

If you wish to adapt the default configuration, use something like the following to copy it from a running container:

    docker cp some-sftp:/etc/ssh/sshd_config /some/path

You can use the modified configuration with:

    docker run --name some-sftp -v /some/path:/etc/ssh:ro -P -d asavartzeth/sftp

## Configuration Options

This is a full list of environment variables that will be used in the configuration of your instance.

- -e `SFTP_USER=...` (defaults to sftp1)
- -e `SFTP_UID=...` (defaults to 2001)
- -e `SFTP_PASS=...` (defaults to randomly generated password)
- -e `SFTP_LOG_LEVEL=...` (defaults to INFO)  
The possible values are: QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, and DEBUG3.
- -e `SFTP_DATA_DIR=...` (defaults to /data/sftp)  
*This will set the location of a data volume. It is used by the runtime script, to enable the transfer of application data to an empty location. This location could be a data volume container, such as [tianon/true](https://registry.hub.docker.com/u/tianon/true/), or a location on your host.*

## User Feedback

This image is not supported anymore. It is provided for archival and academic purposes only and should never be used in a production environment.

Therefore if you have any techincal problems with this image, you are unfortunately on your own.
