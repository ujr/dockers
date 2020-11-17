#!/bin/sh
# You may want a script like this one to simplify invocation
# of the container. Call it with argument 'runall' from cron
# for nightly backups. Review the variables.

MIRRORDIR=/path/to/mirror
BACKUPDIR=/path/to/backup

# For shell access keep stdin open and alloc a tty;
# do NOT alloc a tty for commands running under cron:
OPTS=""
test "$1" = "shell" && OPTS="$OPTS -it"

docker run --rm $OPTS -h "$HOSTNAME" \
  --mount "type=bind,source=$MIRRORDIR,target=/mirror" \
  --mount "type=bind,source=$BACKUPDIR,target=/backup" \
  dirvish $*
