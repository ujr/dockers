# Docker image for ShowMyIP service

Building on [Alpine Linux][alpine] and [Lighttpd][lighttpd]
a minimal web service that returns on each HTTP request
the remote IP address.

## Creating the image

Pull the alpine image from the official docker repo:

```sh
docker pull alpine
```

Create a *Dockerfile* that starts from Alpine, uses its
`apk` package manager to install the Lighttpd web server,
copies some files to the image, exposes the standard ports,
and specifies an entrypoint that launches Lighttpd running
in the foreground.

- [Dockerfile](Dockerfile)

Use `CMD` instead of `ENTRYPOINT` so we can easily override
from the `docker run` command, e.g. with /bin/sh to get a shell.

Create a *lighttpd.conf* file that does just about the bare
minimum required to run Lighttpd and echo the remote IP
upon all HTTP requests.
The idea for using Lua with Lighttpd is from a 2010 article
at <https://jasonstitt.com/ip-reporting-script-lua-lighttpd>.
Recent versions of Lighttpd have no `mod_lua` but provide
the `mod_magnet` instead.

- [content/lighttpd.conf](content/lighttpd.conf)

Create the Lua file references from Lighttpd's configuration,
and also create a small HTML file so we have something to play
with while fiddling with Lighttpd's config (not needed in the
final setup).

- [content/showmyip.lua](content/showmyip.lua)
- [content/index.html](content/index.html)

TODO SSL <https://redmine.lighttpd.net/projects/lighttpd/wiki/Docs_SSL>

Having all prepared, build the Docker image:

```sh
docker build -t showmyip .
```

This creates an image from the current directory (`.`)
and tags (names) it "showmyip" (`-t`). Note that tags
must be all lowercase. The resulting image  should be
no more than 10 MB in size.

## Using the image

Once the image has been created, run it in a container:

```sh
docker run -p 8080:80 --rm showmyip
```

This runs the container, exposes its internal port 80
externally as 8080, will log to stderr, and removes
the container upon exit (`--rm`).

For an **interactive session** with a container,
use `-i` (keep stdin open) and `-t` (allocate a pseudo tty).
The `--rm` option automatically removes the container upon exit.
Here are a few examples. (The command arguments to `docker run`
will replace the `CMD` from the *Dockerfile*, that is, run the
given command instead of lighttpd. If we used `ENTRYPOINT` in
the *Dockerfile*, these arguments would be appended.)

```sh
$ docker run showmyip ifconfig          # check IP addrs
$ docker run -it --rm showmyip /bin/sh  # interactive shell session
/ # exit                                # terminates container
```

Type `Ctrl+P Ctrl+Q` to detach from a container;
this leaves the container running.
Run `docker ps` to see a listing of running containers.
To attach again: `docker attach NAME` where NAME is
the container's name as shown in the `docker ps` output.

And a few commands for administering images and containers:

```sh
docker image ls             # list images
docker container ls -a      # list containers (also those not running)
docker container rm NAME    # remove container NAME
docker image rm REPO:TAG    # remove image REPO:TAG
```

Notice that **command completion** might work with these commands.

## Notes about Lighttpd

- `server.errorlog` defaults to STDERR (or syslog)
- `server.errorlog-use-syslog` defaults to `"disable"`
- `server.document-root` **must** be defined
- `server.upload-dirs` defaults to */var/tmp*, which is fine
  for our purposes; note that this is not only used for uploads
  (i.e., request bodies), but also to compose response data.
- `server.username` and `server.groupname` are the identity
  that Lighttpd assumes after dropping root priviledges;
  on Alpine both are `lighttpd`, while on Debian/Ubuntu
  both are `www-data` (by default)

## Notes about Alpine

- Alpine Linux uses [BusyBox][busybox], which comes with
the Almquist shell [ash][ash] (no bash by default).

- Alpine has its own package manager, called `apk`.
When adding packages to an image, use the `--no-cache`
option to prevent creation of a package index (save space).

- A pristine Alpine comes with no init system. We could
install the `openrc` package to get the OpenRC init system.
However, for such a single-purpse container it suffices to
run `lighttpd` "manually".

## Notes about Docker

- Tag names must be lowercase (`showmyip`, not `ShowMyIP`)
- Prefer `COPY` over `ADD` in Dockerfiles,
  unless you need the extra features of `ADD`
- `ENTRYPOINT` is the executable (and arguments) to run in the container.
- `CMD` is the default executable (and arguments) to run in the container.
  It will be replaced by arguments to the `docker run` command.
- Prefer “exec from“ over “shell form” for `ENTRYPOINT` and `CMD`.
- If both `ENTRYPOINT` and `CMD` are specified, the entrypoint is
  the constant prefix and cmd the overridable suffix of the command
  to run in the container.

[alpine]: https://alpinelinux.org/
[lighttpd]: https://www.lighttpd.net/
[busybox]: https://busybox.net/
[ash]: https://en.wikipedia.org/wiki/Almquist_shell
