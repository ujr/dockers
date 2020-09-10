FROM alpine:latest
RUN apk add --no-cache lighttpd

COPY content /var/www

EXPOSE 80 443

CMD ["/usr/sbin/lighttpd", "-D", "-f", "/var/www/lighttpd.conf"]
