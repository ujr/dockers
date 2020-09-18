FROM alpine:latest
RUN apk add --no-cache perl perl-utils make rsync \
 && cpan install POSIX Getopt::Long Time::ParseDate Time::Period \
 && mkdir -p /backup /mirror /xilab

# Drop for final!
RUN apk add --no-cache mandoc man-pages

COPY content /xilab

RUN cd /xilab && ./setup.sh

VOLUME ["/mirror"]
VOLUME ["/backup"]

# For now, give me a shell (by default):
CMD ["/bin/sh"]
