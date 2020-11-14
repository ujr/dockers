#!/bin/sh
# You may want a script like this one to be invoked
# from cron for nightly backups. Review the variables!

MAILTO=root
MAILHUB=mail.example.com
MAILDOMAIN=example.com

MIRRORDIR=/path/to/mirror
BACKUPDIR=/path/to/backup

/bin/docker run -it --rm -e "MAILTO=$MAILTO" \
  -e "MAILHUB=$MAILHUB" -e "MAILDOMAIN=$MAILDOMAIN" \
  --mount "type=bind,source=$MIRRORDIR,target=/mirror" \
  --mount "type=bind,source=$BACKUPDIR,target=/backup"
  dirvish runall
