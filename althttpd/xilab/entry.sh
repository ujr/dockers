#!/bin/sh
# Entrypoint script for althttpd+fossil container

WEBROOT=/home/www
SERVERCERT="$WEBROOT/ssl/server.pem"
STUNNELCONF="$WEBROOT/ssl/stunnel.conf"
DEFAULTSITE="$WEBROOT/default.website"
SAMPLEREPO="$WEBROOT/fossils/myrepo.fossil"
LOGDIRECTORY="$WEBROOT/logs"

test -d "$WEBROOT" || { echo "Web root $WEBROOT missing, giving up"; exit 1; }

# Get user:group from /home/www/.owner or /home/www directory
if test -f /home/www/.owner
then OWNER=$(ls -l "$WEBROOT/.owner" | awk '{print $3 ":" $4}')
else OWNER=$(ls -ld "$WEBROOT" | awk '{print $3 ":" $4}')
fi

export OWNER WEBROOT
export SERVERCERT STUNNELCONF
export DEFAULTSITE LOGDIRECTORY

test "$1" = "shell" && exec /bin/sh

USER=${OWNER%:*}
GROUP=${OWNER#*:}

echo "Assuming $USER:$GROUP for default files and httpd"

STUNNELBIN=/usr/bin/stunnel
ALTHTTPDBIN=/usr/local/bin/althttpd
FOSSILBIN=/usr/local/bin/fossil

test -x "$STUNNELBIN" || echo "$STUNNELBIN executable missing"
test -x "$ALTHTTPDBIN" || echo "$ALTHTTPDBIN executable missing"
test -x "$FOSSILBIN" || echo "$FOSSILBIN executable missing"

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

  mkdir -p -m 755 "$WEBROOT/bin"
  cp "$FOSSILBIN" "$WEBROOT/bin"
  cp "$ALTHTTPDBIN" "$WEBROOT/bin"

  mkdir -p -m 775 "$LOGDIRECTORY"
  chgrp $GROUP "$LOGDIRECTORY"

  echo "Creating stunnel config in $STUNNELCONF"
  mkdir -p -m 755 "${STUNNELCONF%/*}"
  sed -e "s/XUSER/$USER/g" -e "s/XGROUP/$GROUP/g" /xilab/stunnel.conf > "$STUNNELCONF"
  chmod 444 "$STUNNELCONF"  # make it read-only
}

showhelp() {
  echo "Usage: $0 setup|run|shell|help"
  echo "  setup: create default site and cert (if missing)"
  echo "  run:   start https server (implies setup)"
  echo "  shell: drop into an interactive shell"
  echo "See the stunnel conf in $STUNNELCONF"
  echo "See the accompanying README file"
}

CMD=$1
test -z "$CMD" && CMD=run || shift
case $CMD in
  setup)
    setup
  ;;
  shell)
    exec /bin/sh
  ;;
  help|info)
    showhelp
  ;;
  run|start)
    setup
    exec stunnel "$STUNNELCONF"
  ;;
  *)
    echo "$0: invalid command: $CMD"
    showhelp
    exit 1
esac
