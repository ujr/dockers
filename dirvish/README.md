# Docker image for Dirvish

[Dirvish][dirvish] is a simple Unix backup solution,
written in Perl, using **rsync** and **ssh**, and
exploiting the hardlink feature of Unix file systems
for simple deduplication.

We have successfully used dirvish for years to backup
Linux servers. However, we have found it more reliable
to do the backup in two stages:

1. mirror the remote server data to the backup server
2. archive the now local mirror into the dirvish vault

To stick with this scheme, our container shall have
two volumes, one for the mirror and one for the vault.

**Note:** I really should read up on [BackupPC][backuppc],
which seems to be a more modern and more full-featured
backup system for Unix, Mac, Windows.

## Config

```text
/mirror/               (where the client mirrors live)
/backup/dirvish/identity      (priv key for rsync/ssh)
/backup/dirvish/master.conf   (copied to /etc/dirvish)
/backup/dirvish/mirror.sh          (pre-server script)
/backup/VAULT/                (snapshots for a client)
/backup/VAULT/IMAGE/        (archived client snapshot)
/backup/VAULT/dirvish/default.conf     (client config)
/backup/VAULT/dirvish/client        (rsync host:/tree)
/backup/VAULT/dirvish/exclude         (rsync excludes)
```

- Append corresponding pub key (identity.pub) to client's
  /root/.ssh/authorized_keys
- /etc/dirvish/master.conf overwritten each time with
  /backup/dirvish/master.conf
- /backup/VAULT/dirvish/{client,exclude} are used to
  create the rsync mirror command

## Usage

```sh
# Interactive shell (without mapping volumes):
docker run -it --rm dirvish shell

# Backup all vaults (must map volumes):
docker run --rm -v /outer/backup:/backup \
  -v /outer/mirror:/mirror dirvish runall

# To mail the log to root:
docker run --rm -e MAILTO=root -v ... dirvish runall
```

### Creating an SSH key pair

The container will generate an SSH key pair if none
is found. To provide your own, create the key pair,
place the private key in */backup/dirvish/identity*,
and append the public key to all clients's
*/root/.ssh/authorized_keys* file.

A key pair can be **ssh-keygen**. When called without
arguments, parameters will be queried interactively;
alternatively pass appropriate options. Be sure to
**not** use a passphrase, so that rsync/ssh can use
the key unsupervised.

### Adding a Client

Append the public key */backup/dirvish/identity.pub*
to the client's */root/.ssh/authorized_keys* file.

Within the container, do the following:

```sh
ssh -i /backup/dirvish/identity HOST # test ssh, then exit
mkdir -p /backup/VAULT/dirvish
echo "HOST:/PATH" > /backup/VAULT/dirvish/client
edit /backup/VAULT/dirvish/exclude         # any excludes
/xilab/entry.sh setup         # creates default.conf etc.
dirvish --init --vault VAULT       # create initial image
```

### Removing a Client

To disable backups (but keep config and data):

- remove VAULT's the Runall entry in */backup/dirvish/master.conf*

To delete VAULT's data and config:

- remove VAULT's Runall entry in */backup/dirvish/master.conf*
- delete */mirror/VAULT*
- delete */backup/VAULT*

Both can be done from within the container,
or from the host computer (adjust paths).

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

Note that when writing shell functions, the closing
brace must be on its own line or follow a control operator;
otherwise it is considered another command argument.
This is also true when writing brace groups.

```sh
f() { echo "Correct"; }
g() { echo "Wrong" }  # closing brace is arg to echo
```

An SSH key pair may be created without user interaction
as by the following example. The `-N ''` specifies an
empty passphrase.

```sh
ssh-keygen -t rsa -f /path/to/id_rsa -C root@$(hostname) -N ''
```

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
