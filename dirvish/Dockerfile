FROM alpine:latest
RUN apk add --no-cache perl perl-utils make \
 rsync openssh-client openssh-keygen ssmtp \
 && cpan install POSIX Getopt::Long Time::ParseDate Time::Period \
 && mkdir -p /backup /mirror /xilab

ARG TIMEZONE=Europe/Zurich
RUN apk add --no-cache tzdata \
 && cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime \
 && echo "$TIMEZONE" > /etc/timezone \
 && apk del --no-cache tzdata

#RUN apk add --no-cache mandoc man-pages

COPY xilab /xilab

RUN cd /xilab && ./setup.sh

ENV MAILTO=""

VOLUME ["/mirror", "/backup"]

ENTRYPOINT ["/xilab/entry.sh"]
CMD ["help"]
