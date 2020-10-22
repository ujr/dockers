FROM alpine:latest
RUN apk add --no-cache perl perl-utils make \
 rsync openssh-client openssh-keygen \
 && cpan install POSIX Getopt::Long Time::ParseDate Time::Period \
 && mkdir -p /backup /mirror /xilab

# Drop for final!
RUN apk add --no-cache mandoc man-pages

COPY xilab /xilab

RUN cd /xilab && ./setup.sh

VOLUME ["/mirror", "/backup"]

ENTRYPOINT ["/xilab/entry.sh"]
CMD ["help"]
