#!/bin/sh
# A small script to simplify invocation of the container.
# Adjust the variables to your needs.

FOSSILDIR=/path/to/fossils

# For shell access keep stdin open and alloc a tty;
# the other commands can do without stdin nor tty.
OPTS=""
test "$1" = "shell" && OPTS="$OPTS -it"

docker run --rm $OPTS -p 80:80 -p 443:443 \
  --mount "type=bind,source=$FOSSILDIR,target=/fossil" \
  fossil $*
