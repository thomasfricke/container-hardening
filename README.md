# container-hardening

The `harden` scripts help to harden containers. It needs do be used inside the `Dockerfile`.

F.e. hardening `nginx:alpine`


```Dockerfile

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

The usage 

```bash
harden [-x] -d <dynamically linked> -f <files and dirs> -r <files to remove> -u user <files to chown to user> -c <chmod to be world writable>" 
      -x Activates debugging
      -d Files are considered dynamically linked
         All library dependencies are resolved using ldd and necessary file are included
      -f Files and directories to include. Don't forget the license files
      -r Files to be removed before copying, especially log files
      -u User:Group files should be chowned to, access right will be set to rw for the user
      -c chmod go+rw to all the files in this section

      The container needs a usable version of sh, ldd, sed, rm and uniq
```
