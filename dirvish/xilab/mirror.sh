#!/bin/sh
# Mirror client locally before archiving. Use as pre-server
# script from the Dirvish per vault default.conf files.

. "$(dirname $0)/config.sh"

# Dirvish invokes its {pre,post}-{client,server} scripts with env vars:
# DIRVISH_SERVER, DIRVISH_CLIENT, DIRVISH_SRC, DIRVISH_DEST, DIRVISH_IMAGE
#echo "server=$DIRVISH_SERVER"
#echo "client=$DIRVISH_CLIENT"
#echo "src=$DIRVISH_SRC"
#echo "dest=$DIRVISH_DEST"
#echo "image=$DIRVISH_IMAGE"

IMAGEPATH=${DIRVISH_DEST%/tree}
IMAGE=$(basename "$IMAGEPATH")
VAULTPATH=${IMAGEPATH%/$IMAGE}
VAULT=$(basename "$VAULTPATH")
BANK=$(dirname "$VAULTPATH")
CLIENT="$1"

mirror() {
  local VAULT="$1"
  local CLIENT="$2"
  local TARGET="$MIRROR/$VAULT"
  local EXCLUDEFILE="$BANK/$VAULT/dirvish/exclude"
  local OPTS="$RSYNCOPTS"
  test -f "$EXCLUDEFILE" && OPTS="$OPTS --exclude-from=$EXCLUDEFILE"
  mkdir -p "$TARGET"
  echo "Mirroring $CLIENT to $TARGET"
  echo "ACTION: rsync $OPTS -e $RSYNCRSH $CLIENT $TARGET"
  rsync $OPTS -e "$RSYNCRSH" "$CLIENT" "$TARGET"
}

mirror "$VAULT" "$CLIENT"
