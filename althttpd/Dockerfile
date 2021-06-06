FROM alpine:latest as builder
ARG FOSSILURL=https://www.fossil-scm.org/index.html/tarball/fossil-src.tar.gz?name=fossil-src&uuid=trunk
ARG ALTHTTPDURL=https://sqlite.org/althttpd/raw?filename=althttpd.c&ci=trunk
RUN apk update && apk upgrade \
 && apk add --no-cache build-base \
  zlib-dev openssl-dev zlib-static openssl-libs-static \
 && mkdir -p /build
RUN cd /build \
 && wget -O fossil-src.tar.gz "$FOSSILURL" \
 && tar xzf fossil-src.tar.gz \
 && cd fossil-src \
 && ./configure --static --disable-fusefs \
 && make && strip -s fossil \
 && ./fossil version \
 && mv ./fossil ..
RUN cd /build \
 && wget -O althttpd.c "$ALTHTTPDURL" \
 && gcc -o static -Os -o althttpd althttpd.c


FROM alpine:latest
RUN apk add --no-cache openssl stunnel
COPY --from=builder /build/fossil /usr/local/bin
COPY --from=builder /build/althttpd /usr/local/bin
COPY xilab /xilab

#RUN apk add --no-cache mandoc man-pages

VOLUME ["/home/www"]
EXPOSE 80 443

#ENTRYPOINT ["/bin/sh", "-c"]
ENTRYPOINT ["/xilab/entry.sh"]
#CMD ["run"]
