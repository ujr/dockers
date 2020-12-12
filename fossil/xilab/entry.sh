#!/bin/sh
# Entrypoint script for Fossil container

INDEXFILE="/fossil/index.html"
SERVERCERT="/fossil/ssl/server.pem"
LOGPIPE="/xilab/logpipe"

showhelp() {
  cat << EOT
This is the entrypoint script for our fossil container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  setup     Create self-signed cert and index.html (if not exist)
  start     Run fossil server behind Lighttpd
  makecert  Create (or overwrite) a self-signed cert for HTTPS
  makeindex Create index.html from FOSSIL/*.fossil
  shell     Drop into an interactive shell
EOT
}

usage() {
  echo "$0: $*"; showhelp; exit 1;
}

setup() {
  if test -f "$SERVERCERT"
  then echo "Keeping $SERVERCERT"
  else makecert
  fi

  if test -f "$INDEXFILE"
  then echo "Keeping $INDEXFILE"
  else cp /xilab/index.html "$INDEXFILE"
  fi
}

#start() {
#  mkdir -p "${LOGPIPE%/*}" # create parent dirs
#  test -p "$LOGPIPE" || mkfifo -m 660 "$LOGPIPE"
#  chmod 660 "$LOGPIPE"
#  chown root:lighttpd "$LOGPIPE"
#  trap "killall lighttpd cat" INT TERM QUIT
#  cat <> "$LOGPIPE" 1>&2 &
#  lighttpd -f /xilab/lighttpd.conf
#  fossil server --port 8080 --repolist --notfound / --files '*favicon.ico' /fossil
#  killall lighttpd cat
#}

start() {
  echo "Starting stunnel"
  touch /var/log/stunnel.log
  chown root:stunnel /var/log/stunnel.log
  chmod 664 /var/log/stunnel.log
  # Setup chroot jail for fossil (requires root):
  mkdir -p /fossil/dev
  cp -af /dev/null /fossil/dev
  cp -af /dev/urandom /fossil/dev
  # TODO mount proc -- though it seems to work without?!?
  # A small httpd on port 80 to redirect to https: does not
  # work, because file must exists before -auth can redirect
  #trap "killall althttpd" INT TERM QUIT EXIT
  #althttpd --root /xilab/www --user nobody --port 80 &
  trap "killall -q fossil" INT TERM QUIT EXIT
  fossil server --port 80 --repolist --notfound / --files '*favicon.ico' /fossil &
  # Proxy to talk https and invoke Fossil:
  stunnel /xilab/stunnel.conf
}

server() {
  # Run fossil server directly, not behind a proxy; no https in this case!
  fossil server --port 80 --repolist --notfound / --files '/favicon.ico' /fossil
}

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

makeindex() {
  mkdir -p "${INDEXFILE%/*}"
  cat > "$INDEXFILE" << EOT
<!DOCTYPE html>
<html>
<meta charset="utf-8"/>
<title>Fossil Repository Server</title>
<h1>Fossil Repository Server</h1>
<p>For private network use; not secured for Internet.</p>
<ul>
EOT
  ls /fossil/*.fossil | while read NAME
  do
    NAME="${NAME#/fossil/}"
    NAME="${NAME%.fossil}"
    echo "<li><a href=\"/fossil/$NAME\">$NAME.fossil</a></li>" >> "$INDEXFILE"
  done
  cat >> "$INDEXFILE" << EOT
</ul>
</html>
EOT
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

test -n "$1" && usage "Too many arguments"

case $CMD in
  setup)
    setup
  ;;
  makecert)
    makecert
  ;;
  makeindex)
    makeindex
  ;;
  run|launch|start)
    setup
    start
  ;;
  server)
    server
  ;;
  shell)
    setup
    exec /bin/sh
  ;;
  help)
    showhelp
  ;;
  *)
    usage "Invalid command: $CMD"
esac
