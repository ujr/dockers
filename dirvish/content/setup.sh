#!/bin/sh

PERL=$(which perl)
HOSTNAME=$(hostname)

echo "*** Installing Dirvish"

tar xzf dirvish-1.2.1.tgz

BINDIR="/usr/sbin"
MANDIR="/usr/share/man"
CONFDIR="/etc/dirvish"

TOOLS="dirvish dirvish-runall dirvish-expire dirvish-locate"

HEADER="#!$PERL

\$CONFDIR = \"$CONFDIR\";

"

cd dirvish-1.2.1

for f in $TOOLS
do
    echo "$HEADER" > $f
    cat $f.pl >> $f
    cat loadconfig.pl >> $f
done

# Install the executables:
for f in $TOOLS
do
    install -m 755 -D -t "$BINDIR" $f
done

# Install manual pages:
install -m 644 -D -t "$MANDIR/man8" dirvish.8
install -m 644 -D -t "$MANDIR/man8" dirvish-runall.8
install -m 644 -D -t "$MANDIR/man8" dirvish-expire.8
install -m 644 -D -t "$MANDIR/man8" dirvish-locate.8
install -m 644 -D -t "$MANDIR/man5" dirvish.conf.5

# Create config directory:
test -d "$CONFDIR" || mkdir -p "$CONFDIR"

# Clean the source directory:
for f in $TOOLS; do rm $f; done

cd ..

echo "*** Creating default config"

# Copying our default master config file:
install -m 644 -D -t "$CONFDIR" master.conf

cat <<EOT > default.conf
# Vault default config for server1
client: $HOSTNAME
tree: /mirror/server1
index: gzip
log: gzip
EOT
install -m 644 -D -t /backup/server1/dirvish default.conf

cat <<EOT > default.conf
# Vault default config for server2
client: $HOSTNAME
tree: /mirror/server2
index: gzip
log: gzip
EOT
install -m 644 -D -t /backup/server2/dirvish default.conf
