#!/bin/sh
# Entrypoint script for althttpd container

SERVERCERT=/home/www/ssl/server.pem
STUNNELCONF=/home/www/ssl/stunnel.conf
DEFAULTSITE=/home/www/default.website
SAMPLEREPO=/home/www/fossils/myrepo.fossil
LOGDIRECTORY=/home/www/logs

# Get user:group from /home/www/.owner or /home/www directory
if test -f /home/www/.owner
then OWNER=$(ls -l /home/www/.owner | awk '{print $3 ":" $4}')
else OWNER=$(ls -ld /home/www | awk '{print $3 ":" $4}')
fi

export OWNER
export SERVERCERT STUNNELCONF
export DEFAULTSITE LOGDIRECTORY

test "$1" = "shell" && exec /bin/sh

USER=${OWNER%:*}
GROUP=${OWNER#*:}

STUNNEL=`which stunnel` && echo "Found $STUNNEL" || echo "stunnel not found"
ALTHTTPD=`which althttpd` && echo "Found $ALTHTTPD" || echo "althttpd not found"
FOSSIL=`which fossil` && echo "Found $FOSSIL" || echo "fossil not found"
echo "Assuming $USER:$GROUP for default files and httpd"

makecert() {
  TEMP="$(mktemp)"
  cat > "$TEMP" << EOT
[dn]
CN=localhost
[req]
distinguished_name=dn
[EXT]
subjectAltName=DNS:localhost
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
EOT
  mkdir -p "${SERVERCERT%/*}" # create parent directories
  openssl req -new -x509 -keyout "$SERVERCERT" -out "$SERVERCERT" \
    -newkey rsa:2048 -nodes -days 365 -subj '/CN=localhost' \
    -extensions EXT -config $TEMP
  chmod 400 "$SERVERCERT"
  rm -f "$TEMP"
}

makesite() {
  mkdir -p "$DEFAULTSITE"
  cp /xilab/index.html "$DEFAULTSITE"
  test -f "$DEFAULTSITE/test.txt" || cp /xilab/test.txt "$DEFAULTSITE"
  test -f "$DEFAULTSITE/test.cgi" || cp /xilab/test.cgi "$DEFAULTSITE"
  test -f "$DEFAULTSITE/fossils.cgi" || cp /xilab/fossils.cgi "$DEFAULTSITE"
  test -f "$DEFAULTSITE/myrepo.cgi" || cp /xilab/myrepo.cgi "$DEFAULTSITE"
  chmod 644 "$DEFAULTSITE/index.html" "$DEFAULTSITE/test.txt"
  chmod 755 "$DEFAULTSITE/test.cgi" "$DEFAULTSITE/fossils.cgi"
  for fn in index.html test.txt test.cgi fossils.cgi myrepo.cgi
  do
    chown $USER:$GROUP "$DEFAULTSITE/$fn"
  done
  chown $USER:$GROUP "$DEFAULTSITE"
}

setup() {
  if test ! -f "$SERVERCERT"
  then
    echo "Creating self-signed cert in $SERVERCERT"
    makecert
  fi

  if test ! -f "$DEFAULTSITE/index.html"
  then
    echo "Creating default website"
    makesite
  fi

  mkdir -p -m 775 "${SAMPLEREPO%/*}"
  chgrp $GROUP "${SAMPLEREPO%/*}"

  if test ! -f "$SAMPLEREPO"
  then
    echo "Creating test repository $SAMPLEREPO"
    fossil init --admin-user $USER "$SAMPLEREPO"
    chown $USER:$GROUP "$SAMPLEREPO"
    chmod 664 "$SAMPLEREPO"
  fi

  mkdir -p -m 775 "$LOGDIRECTORY"
  chgrp $GROUP "$LOGDIRECTORY"
}

## Generate stunnel config
mkdir -p -m 755 "${STUNNELCONF%/*}"
echo "Creating stunnel config in $STUNNELCONF"
sed -e "s/XUSER/$USER/g" -e "s/XGROUP/$GROUP/g" /xilab/stunnel.conf > "$STUNNELCONF"
chmod 444 "$STUNNELCONF"  # make it read-only

CMD=$1
test -z "$CMD" && CMD=help || shift
case $CMD in
  setup)
    setup
  ;;
  shell)
    exec /bin/sh
  ;;
  help|info)
    echo "Usage: $0 setup|run|shell|help"
    echo "  setup: create default site and cert (if missing)"
    echo "  run:   start https server (implies setup) (Ctrl+C to stop)"
    echo "  shell: drop into an interactive shell"
    echo "See the stunnel conf in $STUNNELCONF"
    echo "See the accompanying README file"
  ;;
  run|start)
    setup
    stunnel "$STUNNELCONF"
  ;;
  *)
    echo "Invalid command: $CMD"
    echo "Usage: $0 setup|run|shell|help"
    exit 1
esac
