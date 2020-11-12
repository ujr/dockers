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

# BusyBox's find has no -ls option: substitute using exec ls:
sed -i -e '/\bfind\b/s/-ls/-exec ls -dils {} \\\\;/' dirvish.pl
# While at it, fix a minor bug in dirvish-locate:
sed -i -e '/"$imdir\/index\.gz"/s:/index|";:/index.gz|";:' dirvish-locate.pl

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

echo "*** Configuration"
mv profile /root/.profile
source config.sh
echo "rsh: $RSYNCRSH" >> /xilab/master.conf

# embed config.sh into scripts instead of sourcing:
SED="/source.*xilab.*config.sh/ {#r config.sh#d#}"
echo "$SED" | tr '#' '\n' | sed -i -f - mirror.sh
echo "$SED" | tr '#' '\n' | sed -i -f - entry.sh
# Install ssmtp(8) config:
install -m 644 -D -t /etc/ssmtp /xilab/ssmtp.conf
