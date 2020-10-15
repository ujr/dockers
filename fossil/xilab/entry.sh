#!/bin/sh

showhelp() {
  cat << EOT
This is the entrypoint script for our fossil container.
Usage: $0 command
Commands:
  help      Show this help text and quit
  init      Create self-signed cert and index.html (if not exist)
  run       Run fossil server behind Lighttpd
  makecert  Create (or overwrite) a self-signed cert for HTTPS
  makeindex Create index.html from /fossil/*.fossil
  shell     Drop into an interactive shell
EOT
}

INDEXFILE="/fossil/index.html"
SERVERCERT="/fossil/ssl/server.pem"
LOGPIPE="/xilab/logpipe"

setup() {
  test -f $SERVERCERT || makecert
  test -f $INDEXFILE || cp /xilab/index.html $INDEXFILE
  alias ll="ls -l"
}

runall() {
  test -p $LOGPIPE || mkfifo -m 660 $LOGPIPE
  chmod 660 $LOGPIPE
  chown root:lighttpd $LOGPIPE
  trap "killall lighttpd cat" INT TERM QUIT
  cat <> $LOGPIPE 1>&2 &
  lighttpd -f /xilab/lighttpd.conf
  fossil server /fossil --scgi --port 8080 --files '*.html,*.css,*.js' --notfound index.html
  killall lighttpd cat
}

makecert() {
  TEMP=$(mktemp)
  cat > $TEMP << EOT
[dn]
CN=localhost
[req]
distinguished_name=dn
[EXT]
subjectAltName=DNS:localhost
keyUsage=digitalSignature
extendedKeyUsage=serverAuth
EOT
  mkdir -p ${SERVERCERT%/*.pem}
  openssl req -new -x509 -keyout $SERVERCERT -out $SERVERCERT \
    -newkey rsa:2048 -nodes -days 365 -subj '/CN=localhost' \
    -extensions EXT -config $TEMP
  chmod 400 $SERVERCERT
  rm -f $TEMP
}

makeindex() {
  cat > $INDEXFILE << EOT
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
    NAME=${NAME#/fossil/}
    NAME=${NAME%.fossil}
    echo "<li><a href=\"/fossil/$NAME\">$NAME.fossil</a></li>" >> $INDEXFILE
  done
  cat >> $INDEXFILE << EOT
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
      echo "$0: Invalid option: $1"
      showhelp
      exit 1
    ;;
    *)
      break
  esac
  shift
done

CMD=$1
test -z "$CMD" && CMD=help
shift

if [ -n "$1" ]; then
  echo "$0: Too many arguments"
  showhelp
  exit 1
fi

case $CMD in
  init)
    test -f "$INDEXFILE" || makeindex
    test -f "$SERVERCERT" || makecert
  ;;
  makecert)
    makecert
  ;;
  makeindex)
    makeindex
  ;;
  run|launch|start)
    setup
    runall
  ;;
  shell)
    setup
    /bin/sh
  ;;
  help)
    showhelp
  ;;
  *)
    echo "$0: Invalid command: $CMD"
    showhelp
    exit 1
esac
