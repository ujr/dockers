#!/bin/sh

MIRROR="/mirror"
BANK="/backup"

PRIVKEY="$BANK/dirvish/identity"
MASTERCONF="$BANK/dirvish/master.conf"
LOGFILE="$BANK/dirvish/latest.log"

RSYNCOPTS="-rltH --delete -pgo -D --numeric-ids" # --stats
RSYNCRSH="ssh -i '$PRIVKEY' -o StrictHostKeyChecking=no" # -o UserKnownHostsFile=/dev/null

showhelp() {
  cat << EOT
This is the entrypoint script for our dirvish container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  init      Default ssh key and master.conf
  runall    Mirror and archive all vaults
  shell     Drop into an interactive shell
EOT
}

init() {
  test -f "$PRIVKEY" || keygen
  test -f "$MASTERCONF" || cp /xilab/master.conf "$MASTERCONF"
  eachvault initvault
}

runall() {
  eachvault initvault
  cp "$MASTERCONF" /etc/dirvish
  eachvault mirror
  # TODO look for no images and do dirvish --init
  dirvish-runall
  dirvish-expire
  df -h "$BANK"
}

initvault() {
  local VAULT="$1"
  local VAULTCONF="$BANK/$VAULT/dirvish/default.conf"
  local CLIENT="/^[ \t]*client:.*/s//client: $HOSTNAME/"
  local TREE="/^[ \t]*tree:.*/s!!tree: $MIRROR/$VAULT!"
  mkdir -p "$BANK/$VAULT/dirvish"
  mkdir -p "$MIRROR/$VAULT"
  # Create vault config file (if missing):
  test -f "$VAULTCONF" || sed -e "$TREE" /xilab/default.conf > "$VAULTCONF"
  sed -i -e "$CLIENT" "$VAULTCONF"
  # Add VAULT to Runall in master.conf (if missing):
  sed -n -e "/^[ \t]*Runall:/,/^[ \t]*$/p" "$MASTERCONF" | \
    grep -q "\b$VAULT\b" || \
      sed -i -e "/^[ \t]*Runall:/a\    $VAULT 00:00" "$MASTERCONF"
}

mirror() {
  local VAULT="$1"
  local TARGET="$MIRROR/$VAULT"
  local CLIENT=$(head -1 $BANK/$VAULT/dirvish/client)
  local EXCLUDEFILE=$BANK/$VAULT/dirvish/exclude
  local OPTS="$RSYNCOPTS"
  test -f "$EXCLUDEFILE" && OPTS="$OPTS --exclude-from=$EXCLUDEFILE"
  mkdir -p "$TARGET"
  rsync $OPTS -e "$RSYNCRSH" "$CLIENT" "$TARGET"
}

keygen() {
  echo "Creating SSH key pair in $PRIVKEY"
  ssh-keygen -t rsa -C root@$(hostname) -N "" -f "$PRIVKEY"
}

# invoke `$1 VAULT` for each VAULT in BANK
eachvault() {
  find "$BANK" -mindepth 2 -maxdepth 2 -type d -path "$BANK/*/dirvish" | while read P
  do
    VAULT=$(basename ${P%/dirvish})
    $1 "$VAULT"
  done
}

# Run $* in a group and tee all stdout/stderr to $LOGFILE
logged() {
  { $*; } 2>&1 | tee "$LOGFILE"
}

while :; do
  if [ -z "$1" ]; then break; fi
  case $1 in
    -h|--help)
      showhelp
      exit 0
    ;;
    --)
      shift
      break
    ;;
    --*)
      echo "$0: Invalid option: $1"
      showhelp
      exit 1
    ;;
    *)
      break
  esac
  shift
done

CMD=$1
test -z "$CMD" && CMD=help
shift

if [ -n "$1" ]; then
  echo "$0: Too many arguments"
  showhelp
  exit 1
fi

case $CMD in
  init)
    init
  ;;
  runall)
    logged runall
  ;;
  shell)
    exec /bin/sh
  ;;
  help)
    showhelp
  ;;
  *)
    echo "$0: Invalid command: $CMD"
    showhelp
    exit 1
esac
