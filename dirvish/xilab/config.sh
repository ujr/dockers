MIRROR="/mirror"
BANK="/backup"

SSHKEY="$BANK/dirvish/identity"        # private key for SSH
LOGFILE="$BANK/dirvish/latest.log"     # log from latest runall
MASTERCONF="$BANK/dirvish/master.conf" # overrides /etc/dirvish/master.conf
SSMTPCONF="$BANK/dirvish/ssmtp.conf"   # overrides /etc/ssmtp/ssmtp.conf

RSYNCOPTS="-rltH --delete -pgo -D --numeric-ids" # --stats
RSYNCRSH="ssh -i '$SSHKEY'"
RSYNCRSH="$RSYNCRSH -o StrictHostKeyChecking=no"
RSYNCRSH="$RSYNCRSH -o UserKnownHostsFile='$BANK/dirvish/known_hosts'"