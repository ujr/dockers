# Docker image: althttpd & fossil

This container runs [stunnel][stunnel] such that it launches
**althttpd** for each incoming connnection, which may in turn
run **fossil** through CGI to serve fossil repositories.

[Althttpd][althttpd] is a webserver by Richard Hipp (author
of SQLite and Fossil). It runs the sqlite.org website since
2004, is maximally simple, and ships as a single C source file.

[Fossil][fossil] is a distributed software configuration
management (SCM) tool similar to Git, but ships as a single
executable, and includes a wiki and a ticket system.

[Alpine Linux][alpine] serves as the base system.

This container is intended for private networks and not
secured in any way. For public fossil hosting consider
using [Chisel Fossil SCM Hosting][chisel].

## Using the container

Invoke the `setup` command to create a default web site
and a self-signed certificate (only those items that do
not yet exist). Invoke the `run` command to start the
HTTPS server (this always does an implied `setup`); hit
Ctrl-C to stop the server; `run` is the default command.
Invoke `shell` to drop into an interactive shell.

The provided *Makefile* shows how to invoke these commands.
It also provides `start` and `stop` targets that show how
the container can be started as a service in the background.
The provided unit file *althttpd.service* shows one way the
container can be used from systemd.

In each case **check and adjust** the path to your websites!
You may also want to adjust the TCP port, which defaults to 443.

The https server runs as the user who owns the mapped
*www* directory. To change that, create the file
*www/.owner* and the https server will run as this file's
owner and group. For reference, the stunnel config file
can be found in *www/ssl/stunnel.conf* (read-only).

The https server (stunnel) expects a server certificate and
key in the file *www/ssl/server.pem*. If this file is missing,
`setup` creates a self-signed certificate in this place.

Refer to the althttpd documentation about virtual hosts,
basic authentication, and other features.

The complete directory structure in the mapped *www* folder
looks like this:

```text
.owner               run althttps as uid:gid of this file, if present
bin/                 location of the althttpd and fossil executables
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

Within the container is the script */xilab/entry.sh*, which
serves as the entry point into the container. It accepts
the parameters `setup`, `run`, `shell` (as explained above)
and `help` (to print a short reminder to standard output).

## Use with systemd

An example sytemd unit file is provided with the project.

1. **check and fix** the paths in the unit file
2. copy it into the */etc/systemd/system/* directory
3. make systemd reload all unit files

The following commands may be useful:

- `sudo systemctl daemon-reload` — reload unit files
- `sudo systemctl start althttpd` — start the container
- `sudo systemctl stop althttpd` — stop the container
- `systemctl status althttpd` — see systemd status
- `docker ps` — see running docker containers
- `sudo systemctl enable althttpd` — enable boot time launch
- `sudo systemctl disable althttpd` — disable boot time launch

You may have to configure your firewall to allow connections.
For CentOS, the following commands should be useful:

```sh
sudo firewall-cmd --add-service http [--permanent]
sudo firewall-cmd --add-service https [--permanent]
sudo firewall-cmd --list-services
```

## Miscellaneous Notes

See the [stunnel(8) manual page][stunnel.8] for stunnel
configuration and operation.

See separate [notes on althttpd](doc/althttpd.md) for how
to compile and use this web server.

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
