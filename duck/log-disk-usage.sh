#!/bin/sh
# Usage: log-disk-usage.sh <dir>
# To be called regularly by cron: log disk usage
# for the given directory by appending a line of
# form "YYYY mm dd mbytes" to the file <dir>.du.
# ujr/2008-02-05 quick hack

target="$1" || exit 127
log="${target%/}.du"
today=`date '+%Y %m %d'` || exit 1
set -- `du -s "$target"` && blocks=$1 || exit 1
echo $today $(((blocks+512)/1024)) >> "$log"
