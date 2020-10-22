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
/mirror/
/backup/dirvish/identity     (priv key for rsync/ssh)
/backup/dirvish/master.conf  (copied to /etc/dirvish)
/backup/VAULT/
/backup/VAULT/IMAGE/
/backup/VAULT/dirvish/default.conf
/backup/VAULT/dirvish/client   (rsync host:/tree)
/backup/VAULT/dirvish/exclude    (rsync excludes)
```

- Append corresponding pub key (identity.pub) to client's
  /root/.ssh/authorized_keys
- /etc/dirvish/master.conf overwritten each time with
  /backup/dirvish/master.conf
- /backup/VAULT/dirvish/{client,exclude} are used to
  create the rsync mirror command

## Installing Dirvish

Dirvish comes as a tarball. Once unpacked, it still needs
to be installed. This is done by an interactive script,
*install.sh*, which asks a few parameters (like where
to find perl and where to install), and then concatenates
the final executable scripts from a few pieces.

We want this fully automated and thus provide our own
*setup.sh* script that has our parameter choices hardcoded.

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
