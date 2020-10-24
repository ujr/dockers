MIRROR="/mirror"
BANK="/backup"

SSHKEY="$BANK/dirvish/identity" # private key
LOGFILE="$BANK/dirvish/latest.log"
MASTERCONF="$BANK/dirvish/master.conf"

RSYNCOPTS="-rltH --delete -pgo -D --numeric-ids" # --stats
RSYNCRSH="ssh -i '$SSHKEY'"
RSYNCRSH="$RSYNCRSH -o StrictHostKeyChecking=no"
RSYNCRSH="$RSYNCRSH -o UserKnownHostsFile='$BANK/dirvish/known_hosts'"
