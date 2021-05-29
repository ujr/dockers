# Docker image: althttpd & fossil

This container runs [stunnel][stunnel] such that it launches
**althttpd** for each incoming connnection, which may in turn
run **fossil** through CGI to serve fossil repositories.

[Althttpd][althttpd] is a webserver by Richard Hipp (author
of SQLite and Fossil). It runs the sqlite.org website since
2004, is minimally simple, and ships as a single C source file.

[Fossil][fossil] is a distributed software configuration
management software similar to Git, but ships as a single
executable, and includes a wiki and a ticket system.

[Alpine Linux][alpine] serves as the base system.

This container is intended for private networks and not
secured in any way. For public fossil hosting consider
using [Chisel Fossil SCM Hosting][chisel].

## Using the container

TODO

- user/group from www/ (or www/.owner if exists)
- directory structure
- server certificate

## About althttpd

Althttpd comes as a single source file, *althttpd.c*,
and depends only on the Standard C Library. To build:

```sh
gcc -static -Os -o /usr/bin/althttpd althttpd.c
```

Althttpd has no config file. It is controlled through
command line options. Note that `--root` must be an
absolute path (empirical).

See the [althttpd documentation][althttpd] for details.

See the [stunnel(8) manual page][stunnel.8] for stunnel
configuration and operation.

## About fossil

Alpine has no package for fossil. Instead use **wget**
to download and **tar** to unpack the source (both tools
are part of Alpine via BusyBox). Fossil's documentation in
[build.wiki](https://fossil-scm.org/home/doc/trunk/www/build.wiki)
contains info on building a static executable suitable
for running in a Docker container.

[althttpd]: https://sqlite.org/althttpd
[fossil]: https://fossil-scm.org/
[chisel]: https://chiselapp.com/
[stunnel]: https://www.stunnel.org
[stunnel.8]: https://www.stunnel.org/static/stunnel.html
[alpine]: https://alpinelinux.org/
