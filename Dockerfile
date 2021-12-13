FROM nginx:alpine as origin

ADD harden /harden

RUN mkdir /tmp/harden

RUN ./harden -d /usr/sbin/nginx \
             -f /etc/nginx  /var/log/nginx/ /var/run/nginx.pid /var/cache/nginx  /etc/passwd /etc/group \
                /usr/share/nginx /usr/share/licenses/ /var/run \
             -c /var/log/nginx/ /var/cache/nginx /var/run

FROM scratch

COPY --from=origin /tmp/harden/ /

ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]

