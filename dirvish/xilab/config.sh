MIRROR="/mirror"
BANK="/backup"

SSHKEY="$BANK/dirvish/identity"        # private key for SSH
LOGFILE="$BANK/dirvish/latest.log"     # log from latest runall
MASTERCONF="$BANK/dirvish/master.conf" # overrides /etc/dirvish/master.conf
MIRRORSCRIPT="$BANK/dirvish/mirror.sh" # Dirvish pre-server script

RSYNCOPTS="-rltH --delete -pgo -D --numeric-ids --partial -v" # --stats
RSYNCRSH="ssh -i '$SSHKEY'"
RSYNCRSH="$RSYNCRSH -o StrictHostKeyChecking=no"
RSYNCRSH="$RSYNCRSH -o UserKnownHostsFile='$BANK/dirvish/known_hosts'"
