#!/bin/sh
# A small script to simplify invocation of the container.
# Adjust the variables to your needs.

#WWWROOT=/path/to/www
#WWWROOT=$PWD/www
WWWROOT=/home/ujr/www
RUNOPTS=-it

# For shell access keep stdin open and alloc a tty;
# the other commands can do without stdin nor tty.
test "$1" = "shell" && RUNOPTS="$RUNOPTS -it"

docker run --rm $RUNOPTS --name althttpd
  --publish=443:443 \
  --volume="/etc/group:/etc/group:ro" \
  --volume="/etc/passwd:/etc/passwd:ro" \
  --volume="/etc/shadow:/etc/shadow:ro" \
  --volume="$WWWROOT:/home/www:rw" \
  althttpd "$@"
