#!/bin/sh

source /xilab/config.sh

MIRRORSCRIPT="/backup/dirvish/mirror.sh"

showhelp() {
  cat << EOT
This is the entrypoint script for our dirvish container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  setup     Generate an ssh key and default config files
  init      Create initial images for new vaults
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
  else mkdir -p "${MASTERCONF%/*}" && cp /xilab/master.conf "$MASTERCONF"
  fi

  if test -f "$SSMTPCONF"
  then echo "Keeping $SSMTPCONF"
  else mkdir -p "${SSMTPCONF%/*}" && cp /xilab/ssmtp.conf "$SSMTPCONF"
  fi

  if test -f "$MIRRORSCRIPT"
  then echo "Keeping $MIRRORSCRIPT"
  else mkdir -p "${MIRRORSCRIPT%/*}" && cp /xilab/mirror.sh "$MIRRORSCRIPT"
  fi

  test -x "$MIRRORSCRIPT" || chmod a+x "$MIRRORSCRIPT"

  eachvault setupvault
}

runall() {
  date
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  eachvault setupvault
  dirvish-runall
  dirvish-expire
  echo "Disk usage at $(hostname):"
  df -h "$BANK"  # -h is not POSIX but works with BusyBox
  eachvault dumplog
}

init() {
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  eachvault initvault
}

initvault() {
  local VAULT="$1"
  hasimage "$VAULT" || dirvish --init --vault "$VAULT"
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
}

dumplog() {
  local VAULT="$1"
  local IMAGE=$(latestimage "$VAULT")
  local LOGFILE="$BANK/$VAULT/$IMAGE/log"
  echo "" # blank line
  echo "## $VAULT log"
  test -f "$LOGFILE" && cat "$LOGFILE"
  test -f "$LOGFILE.gz" && zcat "$LOGFILE.gz"
}

keygen() {
  echo "Creating SSH key pair in $SSHKEY"
  mkdir -p "${SSHKEY%/*}" # create parent directory
  ssh-keygen -t rsa -C root@$(hostname) -N "" -f "$SSHKEY"
}

# return 0 iff vault $1 has at least one image
hasimage() {
  local VAULT="$1"
  (cd "$BANK/$VAULT" && ls */summary) > /dev/null 2>&1
}

# invoke `$1 VAULT` for each VAULT in BANK
eachvault() {
  local OPTS="-mindepth 2 -maxdepth 2 -type d"
  find "$BANK" $OPTS -path "$BANK/*/dirvish" | while read P
  do
    VAULT=$(basename ${P%/dirvish})
    $1 "$VAULT"
  done
}

# print name of latest image in vault $1
latestimage() {
  local VAULT="$1"
  local IMAGE=$(ls -t -F "$BANK/$VAULT" | grep -v '^dirvish' | grep '/$' | head -1)
  echo ${IMAGE%/}
}

# Run $* in a group and tee all stdout/stderr to $LOGFILE
logged() {
  { $*; echo "MAILTO=$MAILTO, MAILHUB=$MAILHUB"; } 2>&1 | tee "$LOGFILE"

  test -n "$MAILTO" && {
    echo "From: root@$HOSTNAME"
    echo "Date: $(date -R)"
    echo "Subject: Dirvish at $HOSTNAME"
    echo "" # empty line
    cat "$LOGFILE"
  } | mailto "$MAILTO" || true # avoid non-zero return
}

mailto() {
  if test -f "$SSMTPCONF"
  then cp -f "$SSMTPCONF" /etc/ssmtp/ssmtp.conf
  else sed -i -f - /etc/ssmtp/ssmtp.conf << EOT
/^[ \t]*mailhub[ \t]*=.*$/s//mailhub=${MAILHUB:-mail.example.com}/
/^[ \t]*rewriteDomain[ \t]*=.*$/s//rewriteDomain=${MAILDOMAIN}/
/^[ \t]*hostname[ \t]*=.*$/s//hostname=$(hostname)/
EOT
  fi
  ssmtp "$1"
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
