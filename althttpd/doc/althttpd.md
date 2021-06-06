# The althttpd web server

Althttpd is a webserver by Richard Hipp (author of SQLite
and Fossil). It runs the sqlite.org website since 2004.
It is maximally simple, yet supports virtual hosts, CGI,
SCGI, basic authentication, and some redirects.

See the althttpd documentation at <https://sqlite.org/althttpd>
for details.

Althttpd ships as a single source file, *althttpd.c*
([local copy](./althttpd.c)), and depends on Unix and
the Standard C Library only. To build:

```sh
gcc -static -Os -o /usr/bin/althttpd althttpd.c
```

Althttpd has no config file. It is controlled through command line
options. Note that `--root` must be an absolute path (empirical),
and always use `--https 1` when invoking althttpd from stunnel.

```text
--root DIR     The directory that contains the various $HOST.website/
               subdirectories, each containing web content for a single
               virtual host.  If launched as root with "--user USER"
               specified but "--jail 0" omitted, then the process
               chroot()s to DIR and runs under USER's userid.  Required
               for xinetd launch; defaults to "." in standalone mode.

--port N       Run in standalone mode listening on TCP port N

--user USER    The user under which to run if launched as root.
               Althttpd will refuse to run as root (for security).

--logfile FILE Append a single-line, CSV-format, log entry to FILE
               for each HTTP request.  FILE should be a full pathname.
               FILE is interpreted inside the chroot jail. FILE is
               is expanded using strftime() if it contains at least
               one '%' and is not too long.

--https        Indicates that input is coming over SSL and is being
               decoded upstream, perhaps by stunnel.

--family ipv4  Only accept input from IPV4 or IPV6, respectively. Only
--family ipv6  meaningful if althttpd is run as a stand-alone server.

--jail 0       Prevent formation of a chroot jail if launched as root.
               (By default, althttpd chroot()s to DIR if run as root.)

--max-age SEC  Value for "Cache-Control: max-age=%d". Default is 120.

--max-cpu SEC  Maximum number of seconds of CPU time allowed per
               HTTP connection; 0 means no limit.  Default is 30.

--debug        Disables input timeouts; useful for debugging when
               input is being typed manually.
```

The log file is in CSV format, with these fields:

 1. date and time
 2. remote IP address
 3. requested URL
 4. referer
 5. status: 200 OK, 500 Internal server error, etc.
 6. bytes received
 7. bytes sent
 8. self user time
 9. self system time
10. children user time
11. children system time
12. total wall-clock time
13. request number for same TCP/IP connection
14. user agent
15. remote user
16. bytes of URL that correspond to the SCRIPT_NAME
17. line number in source file
