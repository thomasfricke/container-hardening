```bash

```

# Example session for Hardening

Our example is the `nginx:alpine` image. [Alpine Linux](https://alpinelinux.org/) is the best way to create small and minimal images. However, there might always be room for improvement. The starting point is **not compliant with the [CIS benchmark for Docker](https://www.cisecurity.org/benchmark/docker/)**
because

- nginx is running as `root`:  not compliant with Kubernetes pod security policies with the `runAsNonRoot: true` directive
- contains lots of unnecessary parts of the operating system. This is nice for debugging, but effectively inviting attackers to download and install additional software
  -  this includes the shell, even the Bourne `sh` shell can be used to [open TCP connections](https://unix.stackexchange.com/questions/83926/how-to-download-a-file-using-just-bash-and-nothing-else-no-curl-wget-perl-et) if `/dev/tcp` is available in the container
  - `apk` the package manager
  - `curl` to download software
  - `chmod` to make the download executable
- size always matters, small is better than big

At the beginning, we need a **running** container based on the image we want to harden


```bash
docker run -d --name extract nginx:alpine
```

    3c91c58ca43446f6f0aa8b5efbeec5b570be42b78ec3922e14e9e41b40f3d485


contains **more than 1700 files** 


```bash
docker exec extract find /usr | wc
```

       1704    1704   64074


clone the latest version from github


```bash
git clone https://github.com/thomasfricke/container-hardening.git
```

    Klone nach 'container-hardening' ...
    remote: Enumerating objects: 7, done.[K
    remote: Counting objects: 100% (7/7), done.[K
    remote: Compressing objects: 100% (7/7), done.[K
    remote: Total 7 (delta 0), reused 4 (delta 0), pack-reused 0[K
    Entpacke Objekte: 100% (7/7), 2.11 KiB | 1.05 MiB/s, fertig.



```bash
cd container-hardening
```

    /home/thomas/notebooks/container-hardening


 The directory contains
```bash
├── Example-NGinx-Alpine-Hardening.md     # this file
├── extract_function.sh                   # a `sh` function run in the container          
├── harden                                # the script run outside, assumes a valid docker environment
├── License.md                            # the license
└── README.md                             # the readme  
```


```bash
ls -Fl 
```

    .rw-rw-r--  109 thomas  9 Dez 12:07 Dockerfile-extract-hard
    .rw-rw-r--  35k thomas  9 Dez 12:25 Example-NGinx-Alpine-Hardening.md
    .rw-rw-r-- 9,1M thomas  9 Dez 12:07 extract-hard.tar
    .rwxrwxr-x 1,5k thomas  8 Dez 19:30 extract_function.sh*
    .rwxrwxr-x 2,1k thomas  9 Dez 11:36 harden*
    .rw-rw-r-- 2,4k thomas  9 Dez 11:01 License.md
    .rw-rw-r--   61 thomas  8 Dez 19:23 README.md


less than **60 files** are nginx related, compared to more than **1700 files** in the entire image


```bash
docker exec -it extract find / | grep nginx 
```

    /usr/sbin/nginx
    /usr/sbin/nginx-debug
    /usr/share/man/man8/nginx.8.gz
    /usr/share/nginx
    /usr/share/nginx/html
    /usr/share/nginx/html/50x.html
    /usr/share/nginx/html/index.html
    /usr/share/doc/nginx-module-njs
    /usr/share/doc/nginx-module-njs/CHANGES
    /usr/share/licenses/nginx-module-image-filter
    /usr/share/licenses/nginx-module-image-filter/COPYRIGHT
    /usr/share/licenses/nginx
    /usr/share/licenses/nginx/COPYRIGHT
    /usr/share/licenses/nginx-module-xslt
    /usr/share/licenses/nginx-module-xslt/COPYRIGHT
    /usr/share/licenses/nginx-module-geoip
    /usr/share/licenses/nginx-module-geoip/COPYRIGHT
    /usr/share/licenses/nginx-module-njs
    /usr/share/licenses/nginx-module-njs/COPYRIGHT
    /usr/lib/nginx
    /usr/lib/nginx/modules
    /usr/lib/nginx/modules/ngx_stream_geoip_module.so
    /usr/lib/nginx/modules/ngx_stream_js_module-debug.so
    /usr/lib/nginx/modules/ngx_http_image_filter_module.so
    /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so
    /usr/lib/nginx/modules/ngx_http_js_module.so
    /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so
    /usr/lib/nginx/modules/ngx_http_xslt_filter_module.so
    /usr/lib/nginx/modules/ngx_http_geoip_module.so
    /usr/lib/nginx/modules/ngx_http_js_module-debug.so
    /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so
    /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so
    /usr/lib/nginx/modules/ngx_stream_js_module.so
    /etc/init.d/nginx
    /etc/init.d/nginx-debug
    /etc/logrotate.d/nginx
    /etc/nginx
    /etc/nginx/scgi_params
    /etc/nginx/conf.d
    /etc/nginx/conf.d/default.conf
    /etc/nginx/nginx.conf
    /etc/nginx/koi-win
    /etc/nginx/win-utf
    /etc/nginx/modules
    /etc/nginx/koi-utf
    /etc/nginx/uwsgi_params
    /etc/nginx/fastcgi_params
    /etc/nginx/fastcgi.conf
    /etc/nginx/mime.types
    /run/nginx.pid
    /var/cache/nginx
    /var/cache/nginx/client_temp
    /var/cache/nginx/uwsgi_temp
    /var/cache/nginx/fastcgi_temp
    /var/cache/nginx/scgi_temp
    /var/cache/nginx/proxy_temp
    /var/log/nginx
    /var/log/nginx/error.log
    /var/log/nginx/access.log


# the **`harden`** script




```bash
./harden -h
```

    
    ./harden <running container> [-x] -d <dynamically linked> -f <files and dirs> -r <files to remove> -u user <files to chown to user>" 
    
          -x Activates debugging
          -d Files are considered dynamically linked
             All library dependencies are resolved using ldd 
             and necessary file are included
          -f Files and directories to include. Don't forget the license files
          -r Files to be removed before taring, especially log files
          -u User:Group files should be chowned to, access right will be set to rw  
    
    The container needs a usable version of sh, tar, ldd, sed, rm and uniq
    



```bash
./harden extract -d /usr/sbin/nginx \
                 -f /etc/nginx  /var/log/nginx/ /var/run/nginx.pid /var/cache/nginx  /etc/passwd /etc/group \
                    /usr/share/nginx /usr/share/licenses/ \
                 -u 101:101 /var/log/nginx/ /var/cache/nginx /var/run/nginx.pid
```

    generating new Dockerfile-extract-hard
    Sending build context to Docker daemon  9.239MB
    Step 1/5 : FROM scratch
     ---> 
    Step 2/5 : ADD extract-hard.tar /
     ---> Using cache
     ---> 036cd0981939
    Step 3/5 : EXPOSE 3000
     ---> Using cache
     ---> e10c2a202854
    Step 4/5 : EXPOSE 80
     ---> Using cache
     ---> b763c5858911
    Step 5/5 : ENTRYPOINT ["/docker-entrypoint.sh"]
     ---> Using cache
     ---> 053fbeb8a916
    Successfully built 053fbeb8a916
    Successfully tagged extract-hard:latest


warning: this might not be what is wanted, if removing the `sh` shell it is not possible to use a shell script like `/docker-entrypoint.sh`


```bash
cat Dockerfile-extract-hard
```

    FROM scratch
    ADD extract-hard.tar /
    EXPOSE 3000
    EXPOSE 80
    
    ENTRYPOINT ["/docker-entrypoint.sh"]


editing using `sed`


```bash
sed s+^ENTRYPOINT.*$+ENTRYPOINT\ \[\"/usr/sbin/nginx\"\,\"-g\"\,\"daemon\ off\;\"\]+ -i Dockerfile-extract-hard
cat Dockerfile-extract-hard
```

    FROM scratch
    ADD extract-hard.tar /
    EXPOSE 3000
    EXPOSE 80
    
    ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]



```bash
docker build . -t extract-hard -f Dockerfile-extract-hard 
```

    Sending build context to Docker daemon  9.239MB
    Step 1/5 : FROM scratch
     ---> 
    Step 2/5 : ADD extract-hard.tar /
     ---> Using cache
     ---> 036cd0981939
    Step 3/5 : EXPOSE 3000
     ---> Using cache
     ---> e10c2a202854
    Step 4/5 : EXPOSE 80
     ---> Using cache
     ---> b763c5858911
    Step 5/5 : ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
     ---> Running in b072bf228088
    Removing intermediate container b072bf228088
     ---> d19cb6d84354
    Successfully built d19cb6d84354
    Successfully tagged extract-hard:latest



```bash
docker images | head -2
```

    REPOSITORY                                                TAG                                        IMAGE ID       CREATED          SIZE
    extract-hard                                              latest                                     d19cb6d84354   15 seconds ago   8.39MB



```bash
docker rm -f extract-hard
```

    extract-hard



```bash
docker run -d --name extract-hard -u 101:101 -p 10080:80 extract-hard 
```

    606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81



```bash
docker logs extract-hard
```

    2021/12/09 11:08:52 [warn] 1#1: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
    nginx: [warn] the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2



```bash
docker ps
```

    CONTAINER ID   IMAGE                                 COMMAND                  CREATED         STATUS         PORTS                                                                                                                                  NAMES
    606f1dc93b4a   extract-hard                          "/usr/sbin/nginx -g …"   4 seconds ago   Up 3 seconds   3000/tcp, 0.0.0.0:10080->80/tcp, :::10080->80/tcp                                                                                      extract-hard
    3c91c58ca434   nginx:alpine                          "/docker-entrypoint.…"   17 hours ago    Up 17 hours    80/tcp                                                                                                                                 extract
    53e05bb5b2d7   static-hard                           "/usr/sbin/nginx -g …"   20 hours ago    Up 20 hours    80/tcp, 0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                                                                      static-hard
    2dd9501edf6e   alpine                                "ash -c 'apk add soc…"   12 days ago     Up 12 days                                                                                                                                            socat
    214d5932f7e6   gcr.io/k8s-minikube/kicbase:v0.0.27   "/usr/local/bin/entr…"   3 weeks ago     Up 3 weeks     127.0.0.1:49207->22/tcp, 127.0.0.1:49206->2376/tcp, 127.0.0.1:49205->5000/tcp, 127.0.0.1:49204->8443/tcp, 127.0.0.1:49203->32443/tcp   minikube
    ac5efb4cac7a   quay.io/keycloak/keycloak:15.0.2      "/opt/jboss/tools/do…"   5 weeks ago     Up 5 weeks     0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 8443/tcp                                                                                    keycloak
    ad25cd956739   brave:latest                          "/bin/sh -c /run.sh"     7 weeks ago     Up 7 days                                                                                                                                             brave-denmark
    e1f809783d3e   openvpn:latest                        "/run.sh"                6 months ago    Up 4 weeks                                                                                                                                            openvpn-denmark



```bash
curl localhost:10080/ 
```

    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    
    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>
    
    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>



```bash
cat Dockerfile-extract-hard
```

    FROM scratch
    ADD extract-hard.tar /
    EXPOSE 3000
    EXPOSE 80
    
    ENTRYPOINT ["nginx","-g","daemon off;"]



```bash
tar tf extract-hard.tar | wc
```

        104     104    3185



```bash
tar tf extract-hard.tar | grep -E '(^|.*nginx.*)'
```

    lib/ld-musl-x86_64.so.1
    usr/lib/libpcre.so.1
    usr/lib/libpcre.so.1.2.12
    lib/libssl.so.1.1
    lib/libcrypto.so.1.1
    lib/libz.so.1
    lib/libz.so.1.2.11
    lib/ld-musl-x86_64.so.1
    usr/sbin/nginx
    etc/nginx/
    etc/nginx/scgi_params
    etc/nginx/conf.d/
    etc/nginx/conf.d/default.conf
    etc/nginx/nginx.conf
    etc/nginx/koi-win
    etc/nginx/win-utf
    etc/nginx/modules
    etc/nginx/koi-utf
    etc/nginx/uwsgi_params
    etc/nginx/fastcgi_params
    etc/nginx/fastcgi.conf
    etc/nginx/mime.types
    etc/nginx/scgi_params
    etc/nginx/conf.d/
    etc/nginx/conf.d/default.conf
    etc/nginx/conf.d/default.conf
    etc/nginx/nginx.conf
    etc/nginx/koi-win
    etc/nginx/win-utf
    etc/nginx/modules
    usr/lib/nginx/modules/
    usr/lib/nginx/modules/ngx_stream_geoip_module.so
    usr/lib/nginx/modules/ngx_stream_js_module-debug.so
    usr/lib/nginx/modules/ngx_http_image_filter_module.so
    usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so
    usr/lib/nginx/modules/ngx_http_js_module.so
    usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so
    usr/lib/nginx/modules/ngx_http_xslt_filter_module.so
    usr/lib/nginx/modules/ngx_http_geoip_module.so
    usr/lib/nginx/modules/ngx_http_js_module-debug.so
    usr/lib/nginx/modules/ngx_http_geoip_module-debug.so
    usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so
    usr/lib/nginx/modules/ngx_stream_js_module.so
    etc/nginx/koi-utf
    etc/nginx/uwsgi_params
    etc/nginx/fastcgi_params
    etc/nginx/fastcgi.conf
    etc/nginx/mime.types
    var/log/nginx/
    var/log/nginx/error.log
    var/log/nginx/access.log
    var/log/nginx/error.log
    dev/stderr
    var/log/nginx/access.log
    dev/stdout
    var/run/nginx.pid
    var/cache/nginx/
    var/cache/nginx/client_temp/
    var/cache/nginx/uwsgi_temp/
    var/cache/nginx/fastcgi_temp/
    var/cache/nginx/scgi_temp/
    var/cache/nginx/proxy_temp/
    var/cache/nginx/client_temp/
    var/cache/nginx/uwsgi_temp/
    var/cache/nginx/fastcgi_temp/
    var/cache/nginx/scgi_temp/
    var/cache/nginx/proxy_temp/
    etc/passwd
    etc/group
    usr/share/nginx/
    usr/share/nginx/html/
    usr/share/nginx/html/50x.html
    usr/share/nginx/html/index.html
    usr/share/nginx/html/
    usr/share/nginx/html/50x.html
    usr/share/nginx/html/index.html
    usr/share/nginx/html/50x.html
    usr/share/nginx/html/index.html
    usr/share/licenses/
    usr/share/licenses/nginx-module-image-filter/
    usr/share/licenses/nginx-module-image-filter/COPYRIGHT
    usr/share/licenses/nginx/
    usr/share/licenses/nginx/COPYRIGHT
    usr/share/licenses/nginx-module-xslt/
    usr/share/licenses/nginx-module-xslt/COPYRIGHT
    usr/share/licenses/nginx-module-geoip/
    usr/share/licenses/nginx-module-geoip/COPYRIGHT
    usr/share/licenses/nginx-module-njs/
    usr/share/licenses/nginx-module-njs/COPYRIGHT
    usr/share/licenses/nginx-module-image-filter/
    usr/share/licenses/nginx-module-image-filter/COPYRIGHT
    usr/share/licenses/nginx-module-image-filter/COPYRIGHT
    usr/share/licenses/nginx/
    usr/share/licenses/nginx/COPYRIGHT
    usr/share/licenses/nginx/COPYRIGHT
    usr/share/licenses/nginx-module-xslt/
    usr/share/licenses/nginx-module-xslt/COPYRIGHT
    usr/share/licenses/nginx-module-xslt/COPYRIGHT
    usr/share/licenses/nginx-module-geoip/
    usr/share/licenses/nginx-module-geoip/COPYRIGHT
    usr/share/licenses/nginx-module-geoip/COPYRIGHT
    usr/share/licenses/nginx-module-njs/
    usr/share/licenses/nginx-module-njs/COPYRIGHT
    usr/share/licenses/nginx-module-njs/COPYRIGHT



```bash
docker inspect extract-hard | jq
```

    [1;39m[
      [1;39m{
        [0m[34;1m"Id"[0m[1;39m: [0m[0;32m"606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81"[0m[1;39m,
        [0m[34;1m"Created"[0m[1;39m: [0m[0;32m"2021-12-09T11:08:52.432727723Z"[0m[1;39m,
        [0m[34;1m"Path"[0m[1;39m: [0m[0;32m"/usr/sbin/nginx"[0m[1;39m,
        [0m[34;1m"Args"[0m[1;39m: [0m[1;39m[
          [0;32m"-g"[0m[1;39m,
          [0;32m"daemon off;"[0m[1;39m
        [1;39m][0m[1;39m,
        [0m[34;1m"State"[0m[1;39m: [0m[1;39m{
          [0m[34;1m"Status"[0m[1;39m: [0m[0;32m"running"[0m[1;39m,
          [0m[34;1m"Running"[0m[1;39m: [0m[0;39mtrue[0m[1;39m,
          [0m[34;1m"Paused"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"Restarting"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"OOMKilled"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"Dead"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"Pid"[0m[1;39m: [0m[0;39m3029366[0m[1;39m,
          [0m[34;1m"ExitCode"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"Error"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"StartedAt"[0m[1;39m: [0m[0;32m"2021-12-09T11:08:52.814929369Z"[0m[1;39m,
          [0m[34;1m"FinishedAt"[0m[1;39m: [0m[0;32m"0001-01-01T00:00:00Z"[0m[1;39m
        [1;39m}[0m[1;39m,
        [0m[34;1m"Image"[0m[1;39m: [0m[0;32m"sha256:d19cb6d843546165a0b6a18bcf271c21ffb021ceb0bf25b1694568ae6c40f1a6"[0m[1;39m,
        [0m[34;1m"ResolvConfPath"[0m[1;39m: [0m[0;32m"/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/resolv.conf"[0m[1;39m,
        [0m[34;1m"HostnamePath"[0m[1;39m: [0m[0;32m"/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/hostname"[0m[1;39m,
        [0m[34;1m"HostsPath"[0m[1;39m: [0m[0;32m"/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/hosts"[0m[1;39m,
        [0m[34;1m"LogPath"[0m[1;39m: [0m[0;32m"/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81-json.log"[0m[1;39m,
        [0m[34;1m"Name"[0m[1;39m: [0m[0;32m"/extract-hard"[0m[1;39m,
        [0m[34;1m"RestartCount"[0m[1;39m: [0m[0;39m0[0m[1;39m,
        [0m[34;1m"Driver"[0m[1;39m: [0m[0;32m"overlay2"[0m[1;39m,
        [0m[34;1m"Platform"[0m[1;39m: [0m[0;32m"linux"[0m[1;39m,
        [0m[34;1m"MountLabel"[0m[1;39m: [0m[0;32m""[0m[1;39m,
        [0m[34;1m"ProcessLabel"[0m[1;39m: [0m[0;32m""[0m[1;39m,
        [0m[34;1m"AppArmorProfile"[0m[1;39m: [0m[0;32m"docker-default"[0m[1;39m,
        [0m[34;1m"ExecIDs"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
        [0m[34;1m"HostConfig"[0m[1;39m: [0m[1;39m{
          [0m[34;1m"Binds"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"ContainerIDFile"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"LogConfig"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"Type"[0m[1;39m: [0m[0;32m"json-file"[0m[1;39m,
            [0m[34;1m"Config"[0m[1;39m: [0m[1;39m{}[0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"NetworkMode"[0m[1;39m: [0m[0;32m"default"[0m[1;39m,
          [0m[34;1m"PortBindings"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"80/tcp"[0m[1;39m: [0m[1;39m[
              [1;39m{
                [0m[34;1m"HostIp"[0m[1;39m: [0m[0;32m""[0m[1;39m,
                [0m[34;1m"HostPort"[0m[1;39m: [0m[0;32m"10080"[0m[1;39m
              [1;39m}[0m[1;39m
            [1;39m][0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"RestartPolicy"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"Name"[0m[1;39m: [0m[0;32m"no"[0m[1;39m,
            [0m[34;1m"MaximumRetryCount"[0m[1;39m: [0m[0;39m0[0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"AutoRemove"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"VolumeDriver"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"VolumesFrom"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"CapAdd"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"CapDrop"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"CgroupnsMode"[0m[1;39m: [0m[0;32m"host"[0m[1;39m,
          [0m[34;1m"Dns"[0m[1;39m: [0m[1;39m[][0m[1;39m,
          [0m[34;1m"DnsOptions"[0m[1;39m: [0m[1;39m[][0m[1;39m,
          [0m[34;1m"DnsSearch"[0m[1;39m: [0m[1;39m[][0m[1;39m,
          [0m[34;1m"ExtraHosts"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"GroupAdd"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"IpcMode"[0m[1;39m: [0m[0;32m"private"[0m[1;39m,
          [0m[34;1m"Cgroup"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"Links"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"OomScoreAdj"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"PidMode"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"Privileged"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"PublishAllPorts"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"ReadonlyRootfs"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"SecurityOpt"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"UTSMode"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"UsernsMode"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"ShmSize"[0m[1;39m: [0m[0;39m67108864[0m[1;39m,
          [0m[34;1m"Runtime"[0m[1;39m: [0m[0;32m"runc"[0m[1;39m,
          [0m[34;1m"ConsoleSize"[0m[1;39m: [0m[1;39m[
            [0;39m0[0m[1;39m,
            [0;39m0[0m[1;39m
          [1;39m][0m[1;39m,
          [0m[34;1m"Isolation"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"CpuShares"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"Memory"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"NanoCpus"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CgroupParent"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"BlkioWeight"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"BlkioWeightDevice"[0m[1;39m: [0m[1;39m[][0m[1;39m,
          [0m[34;1m"BlkioDeviceReadBps"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"BlkioDeviceWriteBps"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"BlkioDeviceReadIOps"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"BlkioDeviceWriteIOps"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"CpuPeriod"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CpuQuota"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CpuRealtimePeriod"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CpuRealtimeRuntime"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CpusetCpus"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"CpusetMems"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"Devices"[0m[1;39m: [0m[1;39m[][0m[1;39m,
          [0m[34;1m"DeviceCgroupRules"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"DeviceRequests"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"KernelMemory"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"KernelMemoryTCP"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"MemoryReservation"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"MemorySwap"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"MemorySwappiness"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"OomKillDisable"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"PidsLimit"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"Ulimits"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"CpuCount"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"CpuPercent"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"IOMaximumIOps"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"IOMaximumBandwidth"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"MaskedPaths"[0m[1;39m: [0m[1;39m[
            [0;32m"/proc/asound"[0m[1;39m,
            [0;32m"/proc/acpi"[0m[1;39m,
            [0;32m"/proc/kcore"[0m[1;39m,
            [0;32m"/proc/keys"[0m[1;39m,
            [0;32m"/proc/latency_stats"[0m[1;39m,
            [0;32m"/proc/timer_list"[0m[1;39m,
            [0;32m"/proc/timer_stats"[0m[1;39m,
            [0;32m"/proc/sched_debug"[0m[1;39m,
            [0;32m"/proc/scsi"[0m[1;39m,
            [0;32m"/sys/firmware"[0m[1;39m
          [1;39m][0m[1;39m,
          [0m[34;1m"ReadonlyPaths"[0m[1;39m: [0m[1;39m[
            [0;32m"/proc/bus"[0m[1;39m,
            [0;32m"/proc/fs"[0m[1;39m,
            [0;32m"/proc/irq"[0m[1;39m,
            [0;32m"/proc/sys"[0m[1;39m,
            [0;32m"/proc/sysrq-trigger"[0m[1;39m
          [1;39m][0m[1;39m
        [1;39m}[0m[1;39m,
        [0m[34;1m"GraphDriver"[0m[1;39m: [0m[1;39m{
          [0m[34;1m"Data"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"LowerDir"[0m[1;39m: [0m[0;32m"/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b-init/diff:/var/lib/docker/overlay2/bb903b701c4288d1c9053dd63d69d59a3a4484230f1c7da9426f83ca60b47f13/diff"[0m[1;39m,
            [0m[34;1m"MergedDir"[0m[1;39m: [0m[0;32m"/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/merged"[0m[1;39m,
            [0m[34;1m"UpperDir"[0m[1;39m: [0m[0;32m"/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/diff"[0m[1;39m,
            [0m[34;1m"WorkDir"[0m[1;39m: [0m[0;32m"/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/work"[0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"Name"[0m[1;39m: [0m[0;32m"overlay2"[0m[1;39m
        [1;39m}[0m[1;39m,
        [0m[34;1m"Mounts"[0m[1;39m: [0m[1;39m[][0m[1;39m,
        [0m[34;1m"Config"[0m[1;39m: [0m[1;39m{
          [0m[34;1m"Hostname"[0m[1;39m: [0m[0;32m"606f1dc93b4a"[0m[1;39m,
          [0m[34;1m"Domainname"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"User"[0m[1;39m: [0m[0;32m"101:101"[0m[1;39m,
          [0m[34;1m"AttachStdin"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"AttachStdout"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"AttachStderr"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"ExposedPorts"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"3000/tcp"[0m[1;39m: [0m[1;39m{}[0m[1;39m,
            [0m[34;1m"80/tcp"[0m[1;39m: [0m[1;39m{}[0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"Tty"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"OpenStdin"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"StdinOnce"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"Env"[0m[1;39m: [0m[1;39m[
            [0;32m"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"[0m[1;39m
          [1;39m][0m[1;39m,
          [0m[34;1m"Cmd"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"Image"[0m[1;39m: [0m[0;32m"extract-hard"[0m[1;39m,
          [0m[34;1m"Volumes"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"WorkingDir"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"Entrypoint"[0m[1;39m: [0m[1;39m[
            [0;32m"/usr/sbin/nginx"[0m[1;39m,
            [0;32m"-g"[0m[1;39m,
            [0;32m"daemon off;"[0m[1;39m
          [1;39m][0m[1;39m,
          [0m[34;1m"OnBuild"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"Labels"[0m[1;39m: [0m[1;39m{}[0m[1;39m
        [1;39m}[0m[1;39m,
        [0m[34;1m"NetworkSettings"[0m[1;39m: [0m[1;39m{
          [0m[34;1m"Bridge"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"SandboxID"[0m[1;39m: [0m[0;32m"c3d53e2ac88856e88e26a021be1f0b4e15d2f36bbd3c8d0133ae4c8ac301960a"[0m[1;39m,
          [0m[34;1m"HairpinMode"[0m[1;39m: [0m[0;39mfalse[0m[1;39m,
          [0m[34;1m"LinkLocalIPv6Address"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"LinkLocalIPv6PrefixLen"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"Ports"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"3000/tcp"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
            [0m[34;1m"80/tcp"[0m[1;39m: [0m[1;39m[
              [1;39m{
                [0m[34;1m"HostIp"[0m[1;39m: [0m[0;32m"0.0.0.0"[0m[1;39m,
                [0m[34;1m"HostPort"[0m[1;39m: [0m[0;32m"10080"[0m[1;39m
              [1;39m}[0m[1;39m,
              [1;39m{
                [0m[34;1m"HostIp"[0m[1;39m: [0m[0;32m"::"[0m[1;39m,
                [0m[34;1m"HostPort"[0m[1;39m: [0m[0;32m"10080"[0m[1;39m
              [1;39m}[0m[1;39m
            [1;39m][0m[1;39m
          [1;39m}[0m[1;39m,
          [0m[34;1m"SandboxKey"[0m[1;39m: [0m[0;32m"/var/run/docker/netns/c3d53e2ac888"[0m[1;39m,
          [0m[34;1m"SecondaryIPAddresses"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"SecondaryIPv6Addresses"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
          [0m[34;1m"EndpointID"[0m[1;39m: [0m[0;32m"6a89e5eabed28d033b94fe6d7a4a0eb456df2c5147049b85a5287d8457626ca2"[0m[1;39m,
          [0m[34;1m"Gateway"[0m[1;39m: [0m[0;32m"172.26.0.1"[0m[1;39m,
          [0m[34;1m"GlobalIPv6Address"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"GlobalIPv6PrefixLen"[0m[1;39m: [0m[0;39m0[0m[1;39m,
          [0m[34;1m"IPAddress"[0m[1;39m: [0m[0;32m"172.26.0.5"[0m[1;39m,
          [0m[34;1m"IPPrefixLen"[0m[1;39m: [0m[0;39m16[0m[1;39m,
          [0m[34;1m"IPv6Gateway"[0m[1;39m: [0m[0;32m""[0m[1;39m,
          [0m[34;1m"MacAddress"[0m[1;39m: [0m[0;32m"02:42:ac:1a:00:05"[0m[1;39m,
          [0m[34;1m"Networks"[0m[1;39m: [0m[1;39m{
            [0m[34;1m"bridge"[0m[1;39m: [0m[1;39m{
              [0m[34;1m"IPAMConfig"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
              [0m[34;1m"Links"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
              [0m[34;1m"Aliases"[0m[1;39m: [0m[1;30mnull[0m[1;39m,
              [0m[34;1m"NetworkID"[0m[1;39m: [0m[0;32m"24dcbba0a149182d3afd11c92333571fb791302e1db9f8f109d5adabc7361a37"[0m[1;39m,
              [0m[34;1m"EndpointID"[0m[1;39m: [0m[0;32m"6a89e5eabed28d033b94fe6d7a4a0eb456df2c5147049b85a5287d8457626ca2"[0m[1;39m,
              [0m[34;1m"Gateway"[0m[1;39m: [0m[0;32m"172.26.0.1"[0m[1;39m,
              [0m[34;1m"IPAddress"[0m[1;39m: [0m[0;32m"172.26.0.5"[0m[1;39m,
              [0m[34;1m"IPPrefixLen"[0m[1;39m: [0m[0;39m16[0m[1;39m,
              [0m[34;1m"IPv6Gateway"[0m[1;39m: [0m[0;32m""[0m[1;39m,
              [0m[34;1m"GlobalIPv6Address"[0m[1;39m: [0m[0;32m""[0m[1;39m,
              [0m[34;1m"GlobalIPv6PrefixLen"[0m[1;39m: [0m[0;39m0[0m[1;39m,
              [0m[34;1m"MacAddress"[0m[1;39m: [0m[0;32m"02:42:ac:1a:00:05"[0m[1;39m,
              [0m[34;1m"DriverOpts"[0m[1;39m: [0m[1;30mnull[0m[1;39m
            [1;39m}[0m[1;39m
          [1;39m}[0m[1;39m
        [1;39m}[0m[1;39m
      [1;39m}[0m[1;39m
    [1;39m][0m



```bash

```
