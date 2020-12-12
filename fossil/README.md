# Docker image for Fossil SCM

[Fossil][fossil] is a distributed software configuration
management software similar to Git, but ships as a single
executable, and includes a wiki and a ticket system.

This container runs fossil in server mode so that
it can serve as a central location for repositories.
It is intended for private networks and not secured
in any way. For public fossil hosting consider using
[Chisel Fossil SCM Hosting][chisel].

You still want to use HTTPS so that passwords are not
transmitted in clear. Since Fossil itself only speaks
plain HTTP the container will employ a reverse proxy
to terminate HTTPS.

After experiments with [Lighttpd][lighttpd] in front
of Fossil's [SCGI][scgi] interface, I switched to
[stunnel][stunnel] and have it `fossil http` for each
incoming request. This is will not achieve the best
possible performance, but it is still more than enough
and very simple.

[Alpine Linux][alpine] serves as the base system.

## Using the container

```sh
docker run -it --rm -p 80:80 -p 443:443 -v /repos:/fossil fossil shell
docker run --rm -p 80:80 -p 443:443 -v /repos:/fossil fossil start
docker run --rm fossil help
```

The first invocation drops you into a shell session.
Use the `/xilab/entry.sh` script to get going.
The second invocation runs the fossil server.
The last one shows a short usage help.

## Installing Fossil

Alpine at present has no package for fossil. Instead
download the source tarball from the fossil site.
Use **wget** to download and **tar** to unpack (both
tools are part of Alpine via BusyBox).

Fossil's documentation in
[build.wiki](https://fossil-scm.org/home/doc/trunk/www/build.wiki)
contains info on building a static executable suitable
for running in a Docker container.

## Using stunnel

See the [stunnel(8) manual page][stunnel.8]

## Setting up Lighttpd

Lighttpd can check its config file:  
`lighttpd -t -f /path/to/lighttpd.conf` and  
`lighttpd -tt -f /path/to/lighttpd.conf`.

Logging to stdout (or stderr): the standard approach using
`/dev/stdout` fails with *Permission denied* when lighttpd
drops root permissions (`server.username = lighttpd`).
What does work is creating a named pipe, have `cat` copy
from the pipe to stdout (or stderr), and in the config
saying `server.errorlog = "/path/to/pipe"`.

[fossil]: https://fossil-scm.org/
[chisel]: https://chiselapp.com/
[lighttpd]: https://www.lighttpd.net/
[scgi]: https://en.wikipedia.org/wiki/Simple_Common_Gateway_Interface
[alpine]: https://alpinelinux.org/
[stunnel.8]: https://www.stunnel.org/static/stunnel.html
