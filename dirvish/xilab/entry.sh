#!/bin/sh

source /xilab/config.sh

MIRRORSCRIPT="/backup/dirvish/mirror.sh"

showhelp() {
  cat << EOT
This is the entrypoint script for our dirvish container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  setup     Generate an ssh key and a default master.conf
  runall    Mirror and archive all vaults, expire old images
  shell     Drop into an interactive shell
EOT
}

setup() {
  if test -f "$SSHKEY"
  then echo "Keeping $SSHKEY"
  else keygen
  fi

  if test -f "$MASTERCONF"
  then echo "Keeping $MASTERCONF"
  else cp /xilab/master.conf "$MASTERCONF"
  fi

  if test -f "$MIRRORSCRIPT"
  then echo "Keeping $MIRRORSCRIPT"
  else cp /xilab/mirror.sh "$MIRRORSCRIPT"
  fi

  test -x "$MIRRORSCRIPT" || chmod a+x "$MIRRORSCRIPT"

  eachvault setupvault
}

runall() {
  date
  eachvault setupvault
  cp "$MASTERCONF" /etc/dirvish
  dirvish-runall
  dirvish-expire
  df -h "$BANK"
}

setupvault() {
  local VAULT="$1"
  local VAULTCONF="$BANK/$VAULT/dirvish/default.conf"
  local CLIENT="/^[ \t]*client:.*/s//client: $HOSTNAME/"
  local TREE="/^[ \t]*tree:.*/s!!tree: $MIRROR/$VAULT!"
  mkdir -p "$BANK/$VAULT/dirvish"
  # Create vault config file (if missing):
  test -f "$VAULTCONF" || sed -e "$TREE" /xilab/default.conf > "$VAULTCONF"
  sed -i -e "$CLIENT" "$VAULTCONF"
  # Add VAULT to Runall in master.conf (if missing):
  sed -n -e "/^[ \t]*Runall:/,/^[ \t]*$/p" "$MASTERCONF" | \
    grep -q "\b$VAULT\b" || \
      sed -i -e "/^[ \t]*Runall:/a\    $VAULT" "$MASTERCONF"
  ## If no images yet, do the required --init now:
  #hasimage $VAULT || dirvish --init --vault $VAULT
}

keygen() {
  echo "Creating SSH key pair in $SSHKEY"
  ssh-keygen -t rsa -C root@$(hostname) -N "" -f "$SSHKEY"
}

# return 0 iff vault $1 has at least one image
hasimage() {
  local VAULT="$1"
  (cd "$BANK/$VAULT" && ls */summary) > /dev/null 2>&1
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

  test -n "$MAILTO" && {
    echo "From: root@$HOSTNAME"
    echo "Date: $(date -R)"
    echo "Subject: Dirvish at $HOSTNAME"
    echo "" # empty line
    cat "$LOGFILE"
    echo "" # empty line
    # TODO zcat each vault's latest log.gz?
  } | ssmtp "$MAILTO"
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
if test -z "$CMD"
then CMD=help
else shift
fi

if [ -n "$1" ]; then
  echo "$0: Too many arguments"
  showhelp
  exit 1
fi

case $CMD in
  setup)
    setup
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
