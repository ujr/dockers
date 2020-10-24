#!/bin/sh
# Mirror client locally; used as pre-server script for dirvish

source /xilab/config.sh

# Dirvish invokes its {pre,post}-{client,server} scripts with env vars:
# DIRVISH_SERVER, DIRVISH_CLIENT, DIRVISH_SRC, DIRVISH_DEST, DIRVISH_IMAGE
echo "server=$DIRVISH_SERVER client=$DIRVISH_CLIENT src=$DIRVISH_SRC dest=$DIRVISH_DEST image=$DIRVISH_IMAGE"

IMAGEPATH=${DIRVISH_DEST%/tree}
IMAGE=$(basename "$IMAGEPATH")
VAULTPATH=${IMAGEPATH%/$IMAGE}
VAULT=$(basename "$VAULTPATH")
BANK=$(dirname "$VAULTPATH")

mirror() {
  local VAULT="$1"
  local TARGET="$MIRROR/$VAULT"
  local CLIENT=$(head -1 $BANK/$VAULT/dirvish/client)
  local EXCLUDEFILE="$BANK/$VAULT/dirvish/exclude"
  local OPTS="$RSYNCOPTS"
  test -f "$EXCLUDEFILE" && OPTS="$OPTS --exclude-from=$EXCLUDEFILE"
  mkdir -p "$TARGET"
  echo "Mirroring $CLIENT to $TARGET"
  rsync $OPTS -e "$RSYNCRSH" "$CLIENT" "$TARGET"
}

echo "BANK=$BANK, VAULT=$VAULT, IMAGE=$IMAGE"

mirror "$VAULT"
