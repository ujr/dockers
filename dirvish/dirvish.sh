#!/bin/sh
# You may want a script like this one to simplify invocation
# of the container. Call it with argument 'runall' from cron
# for nightly backups. Review the variables and note that an
# ssmtp.conf in $BACKUPDIR/dirvish overrides the variables.

MAILTO=root
MAILHUB=mail.example.com
MAILDOMAIN=example.com

MIRRORDIR=/path/to/mirror
BACKUPDIR=/path/to/backup

# For shell access keep stdin open and alloc a tty;
# do NOT alloc a tty for commands running under cron:
OPTS=""
test "$1" = "shell" && OPTS="$OPTS -it"

/bin/docker run --rm $OPTS -h "$HOSTNAME" -e "MAILTO=$MAILTO" \
  -e "MAILHUB=$MAILHUB" -e "MAILDOMAIN=$MAILDOMAIN" \
  --mount "type=bind,source=$MIRRORDIR,target=/mirror" \
  --mount "type=bind,source=$BACKUPDIR,target=/backup" \
  dirvish $*
