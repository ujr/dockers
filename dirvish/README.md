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

## Notes

- want: neutral base image
- allow: derived images with config "burnt in"

## Installing Dirvish

Dirvish comes as a tarball. Once unpacked, it still needs
to be installed. This is done by an interactive script,
*install.sh*, which asks a few parameters (like where
to find perl and where to install), and then concatenates
the final executable scripts from a few pieces.

We want this fully automated and thus provide our own
*setup.sh* script that has our parameter choices hardcoded.

[dirvish]: http://www.dirvish.org/
[backuppc]: https://backuppc.github.io/backuppc/
