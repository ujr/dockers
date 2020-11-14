#!/bin/sh
# Usage: log-disk-usage.sh <dir>
# To be called regularly (daily) by cron: log disk usage
# for all directories DIR in BASEDIR $1 by appending a
# line of the form "YYYY mm dd n MB" to the file $1/DIR.du.
# ujr/2010-04-05 (based on the 2008-02-05 quick hack)

die() { echo "Fatal: $*"; exit 127; }
test -z "$1" && die "Usage: $0 <directory>"

BASEDIR="$1"
TODAY=`date '+%Y %m %d'` || exit 1

find "$BASEDIR" -mindepth 1 -maxdepth 1 -type d | while read DIR
do
  set -- `du -s --block-size=1M "$DIR"` && SIZE=$1
  echo $TODAY $SIZE MB >> "$DIR.du" # append
done

#target="$1" || exit 127
#log="${target%/}.du"
#today=`date '+%Y %m %d'` || exit 1
#set -- `du -s "$target"` && blocks=$1 || exit 1
#echo $today $(((blocks+512)/1024)) >> "$log"
