#!/bin/sh
# Entrypoint script for Dirvish container

. "$(dirname $0)/config.sh"

showhelp() {
  cat << EOT
This is the entrypoint script for our dirvish container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  setup     Generate an ssh key and default config files
  init [V]  Create initial image for new vaults (or named vault)
  backup V  Do backup for vault V only (not all vaults)
  runall    Mirror and archive all vaults, expire old images
  expire    Remove expired images (run dirvish-expire)
  shell     Drop into an interactive shell
EOT
}

usage() {
  echo "$0: $*"; showhelp; exit 1;
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

  if test -f "$MIRRORSCRIPT"
  then echo "Keeping $MIRRORSCRIPT"
  else mkdir -p "${MIRRORSCRIPT%/*}" && cp /xilab/mirror.sh "$MIRRORSCRIPT"
  fi

  test -x "$MIRRORSCRIPT" || chmod a+x "$MIRRORSCRIPT"

  eachvault setupvault
}

setupvault() {
  local VAULT="$1"
  local VAULTCONF="$BANK/$VAULT/dirvish/default.conf"
  mkdir -p "$BANK/$VAULT/dirvish"
  # Create vault config file (if missing):
  test -f "$VAULTCONF" || cp -f /xilab/default.conf "$VAULTCONF"
  # Vault with mirroring: update client & tree settings:
  grep -q "^pre-server:.*/mirror\.sh[ \t]" "$VAULTCONF" && {
    sed -i -e "/^[ \t]*client:.*/s//client: $HOSTNAME/" "$VAULTCONF"
    sed -i -e "/^[ \t]*tree:.*/s!!tree: $MIRROR/$VAULT!" "$VAULTCONF"
  } || true # avoid error return
  # Add VAULT to Runall in master.conf (if missing):
#  sed -n -e "/^[ \t]*Runall:/,/^[ \t]*$/p" "$MASTERCONF" | \
#    grep -q "\b$VAULT\b" || \
#      sed -i -e "/^[ \t]*Runall:/a\    $VAULT" "$MASTERCONF"
}

init() {
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  if test -n "$1"; then
    test -n "$2" && usage "Too many arguments"
    test -f "$BANK/$1/dirvish/default.conf" || usage "No such vault: $1"
    setupvault "$1"
    dirvish --init --vault "$1"
  else
    eachvault setupvault
    eachvault initvault
  fi
}

initvault() {
  local VAULT="$1"
  hasimage "$VAULT" || dirvish --init --vault "$VAULT"
}

runall() {
  echo "Dirvish at $HOSTNAME"
  echo "on $(date -R)"
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  eachvault setupvault
  dirvish-runall
  dirvish-expire
  echo "Disk usage at $(hostname):"
  df -h "$BANK"  # -h is not POSIX but works with BusyBox
  eachvault dumplog
}

dumplog() {
  local VAULT="$1"
  local IMAGE=$(latestimage "$VAULT")
  local LOGFILE="$BANK/$VAULT/$IMAGE/log"
  echo "" # blank line
  echo "## Log for $VAULT:$IMAGE"
  test -f "$LOGFILE" && { cat "$LOGFILE" | heil 9 15; }
  test -f "$LOGFILE.gz" && { zcat "$LOGFILE.gz" | heil 9 15; }
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

backup() {
  test -z "$1" && usage "Must specify the vault to backup"
  test -z "$2" || usage "Too many arguments"
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  test -f "$BANK/$1/dirvish/default.conf" || usage "No such vault: $1"
  setupvault "$1"
  dirvish --vault "$1"
}

expire() {
  test -f "$MASTERCONF" && cp -f "$MASTERCONF" /etc/dirvish
  dirvish-expire
}

# return 0 iff vault $1 has at least one image
hasimage() {
  local VAULT="$1"
  (cd "$BANK/$VAULT" && ls */summary) > /dev/null 2>&1
}

# print name of latest image in vault $1
latestimage() {
  local VAULT="$1"
  local IMAGE=$(ls -t -F "$BANK/$VAULT" | grep -v '^dirvish' | grep '/$' | head -1)
  echo ${IMAGE%/}
}

keygen() {
  echo "Creating SSH key pair in $SSHKEY"
  mkdir -p "${SSHKEY%/*}" # create parent directory
  ssh-keygen -t rsa -C root@$(hostname) -N "" -f "$SSHKEY"
}

# print he(ad and ta)il of stdin to stdout
heil() {
  awk -v "M=$1" -v "N=$2" 'BEGIN { if(!M)M=9;if(!N)N=9; }
  { if (NR <= M) print; else if (N > 0) tail[tp++ % N] = $0; }
  END { if (NR > M+N && M+N > 0) print "[...]";
  if (tp <= N) for(i = 0; i < tp; i++) print tail[i];
  else for (i = tp%N; i < tp%N+N; i++) print tail[i%N]; }'
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
      usage "Invalid option: $1"
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

case $CMD in
  setup)
    setup
  ;;
  init)
    init $*
  ;;
  backup)
    backup $*
  ;;
  runall)
    logged runall
  ;;
  expire)
    expire
  ;;
  shell)
    exec /bin/sh
  ;;
  help)
    showhelp
  ;;
  *)
    usage "Invalid command: $CMD"
esac
