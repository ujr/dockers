FROM alpine:latest
RUN apk add --no-cache perl perl-utils make \
 rsync openssh-client openssh-keygen ssmtp \
 && cpan install POSIX Getopt::Long Time::ParseDate Time::Period \
 && mkdir -p /backup /mirror /xilab

#RUN apk add --no-cache mandoc man-pages

COPY xilab /xilab

RUN cd /xilab && ./setup.sh

ENV MAILTO=admin@example.com
ENV MAILHUB=mail.example.com
ENV MAILDOMAIN=example.com

VOLUME ["/mirror", "/backup"]

ENTRYPOINT ["/xilab/entry.sh"]
CMD ["help"]
