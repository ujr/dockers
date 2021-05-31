# Docker image: althttpd & fossil

This container runs [stunnel][stunnel] such that it launches
**althttpd** for each incoming connnection, which may in turn
run **fossil** through CGI to serve fossil repositories.

[Althttpd][althttpd] is a webserver by Richard Hipp (author
of SQLite and Fossil). It runs the sqlite.org website since
2004, is minimally simple, and ships as a single C source file
([local copy](./althttpd.c)).

[Fossil][fossil] is a distributed software configuration
management software similar to Git, but ships as a single
executable, and includes a wiki and a ticket system.

[Alpine Linux][alpine] serves as the base system.

This container is intended for private networks and not
secured in any way. For public fossil hosting consider
using [Chisel Fossil SCM Hosting][chisel].

## Using the container

A *Makefile* comes with the container that helps with
invoking the container. You want to adjust the path to
your websites, which defaults to the *./www* folder.

Invoke `make setup` to create a default web site and
a self-signed server certificate, invoke `make run`
to start the HTTPS server (hit Ctrl-C to stop), and
`make shell` to drop into an interactive shell.

The https server runs as the user who owns the mapped
*www* directory. To change that, create the file
*www/.owner* and the https server will run as this file's
owner and group. For reference, the stunnel config file
can be found in *./www/ssl/stunnel.conf* (read-only).

The https server (stunnel) expects a server certificate
in the file *./www/ssl/server.pem*. If this file is missing,
`setup` creates a self-signed certificate in this place.

Refer to the althttpd documentation about virtual hosts,
basic authentication, and other features.

The complete directory structure in the mapped *www* folder
looks like this:

```text
.owner               run althttps as uid:gid of this file, if present
default.website/     the default site (if no other .website matches)
  index.html         created by setup, if mising
  test.txt           files are served as static content
  test.cgi           executable files are run as CGI scripts
other.website/       althttps supports virtual hosts
logs/                the althttps access log goes here
  althttpd.log       see althttps documentation for structure
  fossilerr.log      your fossil cgi scripts may log errors here
ssl/                 stunnel stuff goes here
  stunnel.conf       the stunnel configuration (generated)
  server.pem         the server certificate and key (permissions!)
fossils/             your fossil repos (just a suggestion)
  myrepo.fossil      created by setup as an example
```

Within the container is the script */xilab/entry.sh*,
which serves as the entry point into the container.
Invoke it with argument `shell` to drop into an
interactive shell, with `setup` to create a default
web site and a self-signed certificate (only those
things that do not yet exist), and with `run` to start
the HTTPS server (this also invokes `setup` implicitly).

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
