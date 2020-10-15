FROM alpine:latest as builder
ARG FOSSILURL=https://www.fossil-scm.org/index.html/tarball/fossil-src.tar.gz?name=fossil-src&uuid=trunk
RUN apk update && apk upgrade \
 && apk add --no-cache build-base \
  zlib-dev openssl-dev zlib-static openssl-libs-static \
 && wget -O fossil-src.tar.gz "$FOSSILURL" \
 && tar xzf fossil-src.tar.gz \
 && cd fossil-src \
 && ./configure --static --disable-fusefs --with-th1-docs --with-th1-hooks \
 && make \
 && strip -s fossil \
 && ./fossil version

FROM alpine:latest
RUN apk add --no-cache lighttpd openssl
COPY --from=builder /fossil-src/fossil /usr/local/bin/
COPY xilab /xilab

RUN apk add --no-cache mandoc man-pages

VOLUME ["/fossil"]
EXPOSE 80 443

ENTRYPOINT ["/xilab/entry.sh"]
CMD ["help"]
