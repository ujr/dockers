#!/bin/sh
# Entrypoint script for althttpd container

SERVERCERT=/www/ssl/server.pem
STUNNELCONF=/www/ssl/stunnel.conf
DEFAULTSITE=/www/default.website

# Get user:group from /www/.owner or /www directory
if test -f /www/.owner
then OWNER=$(ls -l /www/.owner | awk '{print $3 ":" $4}')
else OWNER=$(ls -ld /www | awk '{print $3 ":" $4}')
fi

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

TESTREPO=/www/fossils/myrepo.fossil
mkdir -p -m 775 "${TESTREPO%/*}"
chgrp $GROUP "${TESTREPO%/*}"

if test ! -f "$TESTREPO"
then
  echo "Creating test repository $TESTREPO"
  fossil init --admin-user $USER "$TESTREPO"
  chown $USER:$GROUP "$TESTREPO"
  chmod 664 "$TESTREPO"
fi

mkdir -p -m 775 /www/logs
chgrp $GROUP /www/logs

## Generate stunnel config
mkdir -p -m 755 "${STUNNELCONF%/*}"
sed -e "s/XUSER/$USER/g" -e "s/XGROUP/$GROUP/g" /xilab/stunnel.conf > "$STUNNELCONF"

CMD=$1
test -z "$CMD" && CMD=help || shift
case $CMD in
  shell)
    exec /bin/sh
  ;;
  help|info)
    echo "Usage: $0 run|shell|help"
    echo "See the stunnel conf in $STUNNELCONF"
    echo "See the accompanying README file"
  ;;
  run|start)
    stunnel "$STUNNELCONF"
  ;;
  *)
    echo "Invalid command: $CMD"
    echo "Usage: $0 run|shell|help"
    exit 1
esac
