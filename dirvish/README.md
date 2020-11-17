# Docker image for Dirvish

[Dirvish][dirvish] is a simple Unix backup solution,
written in Perl, using **rsync** and **ssh**, and
exploiting the hardlink feature of Unix file systems
for simple deduplication.

We have successfully used Dirvish for years to backup
Linux servers. However, we have found it more reliable
to do the backup in two stages:

1. mirror the remote server data to the backup server
2. archive the now local mirror into the dirvish vault

To support this scheme, our container has two volumes,
one for the mirror and one for the vault. Use of this
mirror-before-archive scheme is configurable per vault.

> **Note:** I really should read up on [BackupPC][backuppc],
which seems to be a more modern and more full-featured
backup system for Unix, Mac, Windows.

## Volume Layout

```text
/mirror/                        (where the client mirrors live)
/backup/dirvish/identity               (priv key for rsync/ssh)
/backup/dirvish/master.conf           (copied to /etc/dirvish/)
/backup/dirvish/mirror.sh     (pre-server script for mirroring)
/backup/dirvish/ssmtp.conf              (copied to /etc/ssmtp/)
/backup/VAULT/                         (snapshots for a client)
/backup/VAULT/IMAGE/                 (archived client snapshot)
/backup/VAULT/dirvish/default.conf              (client config)
/backup/VAULT/dirvish/exclude                  (rsync excludes)
```

## Configuration

The only build-time configuration is the `TIMEZONE` build argument
that defaults to `Europe/Zurich` but can be changed like this:
`docker build --build-arg TIMEZONE=Europe/London -t dirvish .`

Container configuration is through files in a mapped volume
and through environment variables and arguments.

Global config:

```text
BACKUP/dirvish/identity               private key for rsync/ssh
BACKUP/dirvish/master.conf                dirvish master config
BACKUP/dirvish/ssmtp.conf         config for ssmtp(8), optional
BACKUP/dirvish/mirror.sh              script to mirror a client
```

Clients are accessed through ssh using a key pair.
Place the private key in *BACKUP/dirvish/identity* and
append the corresponding public key, *identity.pub*, to
to the client's */root/.ssh/authorized_keys* file.

For *master.conf* and *ssmtp.conf* consult the dirvish
and ssmtp(8) man pages. These two files will be copied
to their standard places whenever the container is called
with the `runall` argument.

The container, when invoked with the `setup` argument,
will generate a key pair if the private key is not found.
It will also provide default *master.conf* and *ssmtp.conf*
files if they do not yet exist.

The *mirror.sh* script may be changed if need be.
It is invoked as a pre-server script by Dirvish.

Mail notifications are only sent if the `MAILTO` env var
is set and if the *ssmtp.conf* file is found. To set env
vars in the container, add `-e NAME=VALUE` arguments to
`docker run`.

Docker generates host names for its containers. To override,
use the `-h hostname` argument to `docker run`, for example,
`docker run -h $(hostname) ...`.

Per vault config:

```text
BACKUP/VAULT/dirvish/default.conf      generated if missing
BACKUP/VAULT/dirvish/exclude        excludes for this vault
```

For mirror-before-archive backups, the *default.conf* should
look like the example below. Note that in this case the
`client:` entry must be present but its value will be
overwritten each time with the container's hostname, and
note that the `tree:` property points to the mirrored data.

```conf
client: dummy
tree: /mirror/VAULT
index: gzip
log: gzip
pre-server: /backup/dirvish/mirror.sh my.example.com:/data
```

An equivalent *default.conf* for direct backups looks like this:

```conf
client: my.example.com
tree: /data
index: gzip
log: gzip
file-exclude: exclude         # optional: point to exclude file
```

Note that there is no `pre-server:` setting, the
`client:` setting is the client's hostname, and the
`tree:` is a path to the data to backup.

The per-vault *exclude* file contains backup exclusions
for *rsync*.

## Usage

It is easiest to use the container through the provided
*dirvish.sh* shell script. Be sure to update the variables
to match your setup! Then usage is as follows:

```sh
dirvish.sh help    # show quick help and quit
dirvish.sh setup   # generate ssh key and default config files
dirvish.sh init    # create initial images for new vaults
dirvish.sh runall  # backup all clients, expire old images
dirvish.sh shell   # drop into an interactive shell
```

Run `setup` to help get started, and run `init` once after
adding a new vault. You may invoke `runall` from *cron* for
regular (nightly) backups.

This script also shows how to invoke Docker to run the
container. The `--rm` argument deletes the container after
it exits. Volumes are mapped with `--mount` but could also
be mapped with the older `-v outer:inner` option. To use
the container's shell, pass the `-it` options, but if you
run the container from *cron* do *not* pass `-t`.

For mail notification, pass the environment variable
`MAILTO=root` (choose recipient) into the container
(and make sure mail is configured -- see above).

### Creating an SSH key pair

The container will generate an SSH key pair if none is found.
To provide your own, create the key pair, place the private key
in */backup/dirvish/identity*, and append the public key to all
clients's */root/.ssh/authorized_keys* file.

Use **ssh-keygen** to create key paris. Required parameters
will be queried interactively or can be passed as options.
Be sure to **not** use a passphrase, so that rsync/ssh can
use the key unsupervised. And keep the private key private!

### Adding a Client

First, append the public key *BACKUP/dirvish/identity.pub*
to the client's */root/.ssh/authorized_keys* file. Test the
connection: `ssh -i BACKUP/dirvish/identity HOST` and exit.

Next, create the the client's VAULT and config:

```sh
mkdir -p BACKUP/VAULT/dirvish            # create the vault
dirvish.sh setup          # generate a default vault config
edit BACKUP/VAULT/dirvish/default.conf  # edit vault config
edit BACKUP/VAULT/dirvish/exclude       # list any excludes
```

See the instructions in the generated *default.conf* file.

The very first backup of any vault must be done with a
special parameter. You can do it from within the container
or from the host, though commands are different:

```sh
dirvish --init --vault VAULT    # from within the container
dirvish.sh init                   # or from the host system
```

Finally, if you want backups for this client be run automatically,
add the vault to `Runall` in *BACKUP/dirvish/master.conf*.

### Removing a Client

To disable backups (but keep config and data):

- remove VAULT's Runall entry in */backup/dirvish/master.conf*

To delete VAULT's data and config:

- remove VAULT's Runall entry in */backup/dirvish/master.conf*
- delete */mirror/VAULT*
- delete */backup/VAULT*

Both can be done from within the container,
or from the host computer (adjust paths).

---

## Installing Dirvish

Dirvish comes as a tarball. Once unpacked, it still needs
to be installed. This is done by an interactive script,
*install.sh*, which asks a few parameters (like where
to find perl and where to install), and then concatenates
the final executable scripts from a few pieces.

We want this fully automated and thus provide our own
*setup.sh* script that has our parameter choices hardcoded.

A subtle problem: dirvish creates the index of an image
with `find $destree -ls` but busybox does not support the
`-ls` option. The aforementioned *setup.sh* script substitutes
`-exec ls -dils {} \;` for `-ls`, that is, we direct `find`
to invoke `ls` for each entry. Slow, but works. Alternatively,
we could simply remove the `-ls` option, but doing so would
probably break `dirvish-locate`.

While at it, fix a minor bug in `dirvish-locate`, where
`gzip` is instructed to uncompress file `index` if file
`index.gz` exists.

## Miscellaneous

When writing shell functions, the closing brace must be on
its own line or follow a control operator; otherwise it is
considered another command argument. This is equally true
when writing brace groups.

```sh
f() { echo "Correct"; }
g() { echo "Wrong" }  # closing brace is arg to echo
```

An SSH key pair may be created without user interaction as
by this example. The `-N ''` specifies an empty passphrase.

```sh
ssh-keygen -t rsa -f /path/to/id_rsa -C root@$(hostname) -N ''
```

The `-o StrictHostKeyChecking=no` and `-o UserKnownHostsFile=...`
options to **ssh** are useful in our context. By setting the
latter to */dev/null* we could do without a known hosts file,
but then the warning about an unknown host appears each time.

The old rsync-dirvish-all script looked similar to the one below:

```sh
LOGFILE="/root/cron/backup/latest.log"
OPTS="-rltH --delete -pgo --stats -D --numeric-ids"
HOST=`/bin/hostname`

# Rotate log files:
test -f "$LOGFILE.3" && rm "$LOGFILE.3"
test -f "$LOGFILE.2" && mv "$LOGFILE.2" "$LOGFILE.3"
test -f "$LOGFILE.1" && mv "$LOGFILE.1" "$LOGFILE.2"
test -f "$LOGFILE"   && mv "$LOGFILE"   "$LOGFILE.1"

# Run all commands in a subshell so we can redirect output easily:
{
echo "** Mirroring seven-partial ..."
rsync $OPTS --exclude-from=/backup/seven-partial/dirvish/exclude \
      seven.xilab.ch:/ /mirror/seven-partial/

echo "** Mirroring lm2 ..."
rsync $OPTS --exclude-from=/backup/lm2/dirvish/exclude \
      lm2.ddns.xilab.ch:/backup/remote/crypt/ /mirror/lm2/

echo "** Archiving mirror states ..."
/usr/sbin/dirvish-runall

echo "** Expiring old images ..."
/usr/sbin/dirvish-expire

echo "** Disk usage report"
df -h / /boot
} 2>&1 | tee "$LOGFILE" | /usr/bin/mail -s "cron@$HOST: $0" root
```

[dirvish]: http://www.dirvish.org/
[backuppc]: https://backuppc.github.io/backuppc/
