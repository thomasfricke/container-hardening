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
    remote: Enumerating objects: 7, done.
    remote: Counting objects: 100% (7/7), done.
    remote: Compressing objects: 100% (7/7), done.
    remote: Total 7 (delta 0), reused 4 (delta 0), pack-reused 0
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

    [
      {
        "Id": "606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81",
        "Created": "2021-12-09T11:08:52.432727723Z",
        "Path": "/usr/sbin/nginx",
        "Args": [
          "-g",
          "daemon off;"
        ],
        "State": {
          "Status": "running",
          "Running": true,
          "Paused": false,
          "Restarting": false,
          "OOMKilled": false,
          "Dead": false,
          "Pid": 3029366,
          "ExitCode": 0,
          "Error": "",
          "StartedAt": "2021-12-09T11:08:52.814929369Z",
          "FinishedAt": "0001-01-01T00:00:00Z"
        },
        "Image": "sha256:d19cb6d843546165a0b6a18bcf271c21ffb021ceb0bf25b1694568ae6c40f1a6",
        "ResolvConfPath": "/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/hostname",
        "HostsPath": "/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/hosts",
        "LogPath": "/var/lib/docker/containers/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81/606f1dc93b4ac2f28eac7aafb780d5ce7c415849d2e85cd760c25a61cb6eed81-json.log",
        "Name": "/extract-hard",
        "RestartCount": 0,
        "Driver": "overlay2",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "docker-default",
        "ExecIDs": null,
        "HostConfig": {
          "Binds": null,
          "ContainerIDFile": "",
          "LogConfig": {
            "Type": "json-file",
            "Config": {}
          },
          "NetworkMode": "default",
          "PortBindings": {
            "80/tcp": [
              {
                "HostIp": "",
                "HostPort": "10080"
              }
            ]
          },
          "RestartPolicy": {
            "Name": "no",
            "MaximumRetryCount": 0
          },
          "AutoRemove": false,
          "VolumeDriver": "",
          "VolumesFrom": null,
          "CapAdd": null,
          "CapDrop": null,
          "CgroupnsMode": "host",
          "Dns": [],
          "DnsOptions": [],
          "DnsSearch": [],
          "ExtraHosts": null,
          "GroupAdd": null,
          "IpcMode": "private",
          "Cgroup": "",
          "Links": null,
          "OomScoreAdj": 0,
          "PidMode": "",
          "Privileged": false,
          "PublishAllPorts": false,
          "ReadonlyRootfs": false,
          "SecurityOpt": null,
          "UTSMode": "",
          "UsernsMode": "",
          "ShmSize": 67108864,
          "Runtime": "runc",
          "ConsoleSize": [
            0,
            0
          ],
          "Isolation": "",
          "CpuShares": 0,
          "Memory": 0,
          "NanoCpus": 0,
          "CgroupParent": "",
          "BlkioWeight": 0,
          "BlkioWeightDevice": [],
          "BlkioDeviceReadBps": null,
          "BlkioDeviceWriteBps": null,
          "BlkioDeviceReadIOps": null,
          "BlkioDeviceWriteIOps": null,
          "CpuPeriod": 0,
          "CpuQuota": 0,
          "CpuRealtimePeriod": 0,
          "CpuRealtimeRuntime": 0,
          "CpusetCpus": "",
          "CpusetMems": "",
          "Devices": [],
          "DeviceCgroupRules": null,
          "DeviceRequests": null,
          "KernelMemory": 0,
          "KernelMemoryTCP": 0,
          "MemoryReservation": 0,
          "MemorySwap": 0,
          "MemorySwappiness": null,
          "OomKillDisable": false,
          "PidsLimit": null,
          "Ulimits": null,
          "CpuCount": 0,
          "CpuPercent": 0,
          "IOMaximumIOps": 0,
          "IOMaximumBandwidth": 0,
          "MaskedPaths": [
            "/proc/asound",
            "/proc/acpi",
            "/proc/kcore",
            "/proc/keys",
            "/proc/latency_stats",
            "/proc/timer_list",
            "/proc/timer_stats",
            "/proc/sched_debug",
            "/proc/scsi",
            "/sys/firmware"
          ],
          "ReadonlyPaths": [
            "/proc/bus",
            "/proc/fs",
            "/proc/irq",
            "/proc/sys",
            "/proc/sysrq-trigger"
          ]
        },
        "GraphDriver": {
          "Data": {
            "LowerDir": "/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b-init/diff:/var/lib/docker/overlay2/bb903b701c4288d1c9053dd63d69d59a3a4484230f1c7da9426f83ca60b47f13/diff",
            "MergedDir": "/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/merged",
            "UpperDir": "/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/diff",
            "WorkDir": "/var/lib/docker/overlay2/dfa9ad23a46e4ed2b935892b8f0e3454d193b08f2cadecff21cd4326e4a5fa9b/work"
          },
          "Name": "overlay2"
        },
        "Mounts": [],
        "Config": {
          "Hostname": "606f1dc93b4a",
          "Domainname": "",
          "User": "101:101",
          "AttachStdin": false,
          "AttachStdout": false,
          "AttachStderr": false,
          "ExposedPorts": {
            "3000/tcp": {},
            "80/tcp": {}
          },
          "Tty": false,
          "OpenStdin": false,
          "StdinOnce": false,
          "Env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          ],
          "Cmd": null,
          "Image": "extract-hard",
          "Volumes": null,
          "WorkingDir": "",
          "Entrypoint": [
            "/usr/sbin/nginx",
            "-g",
            "daemon off;"
          ],
          "OnBuild": null,
          "Labels": {}
        },
        "NetworkSettings": {
          "Bridge": "",
          "SandboxID": "c3d53e2ac88856e88e26a021be1f0b4e15d2f36bbd3c8d0133ae4c8ac301960a",
          "HairpinMode": false,
          "LinkLocalIPv6Address": "",
          "LinkLocalIPv6PrefixLen": 0,
          "Ports": {
            "3000/tcp": null,
            "80/tcp": [
              {
                "HostIp": "0.0.0.0",
                "HostPort": "10080"
              },
              {
                "HostIp": "::",
                "HostPort": "10080"
              }
            ]
          },
          "SandboxKey": "/var/run/docker/netns/c3d53e2ac888",
          "SecondaryIPAddresses": null,
          "SecondaryIPv6Addresses": null,
          "EndpointID": "6a89e5eabed28d033b94fe6d7a4a0eb456df2c5147049b85a5287d8457626ca2",
          "Gateway": "172.26.0.1",
          "GlobalIPv6Address": "",
          "GlobalIPv6PrefixLen": 0,
          "IPAddress": "172.26.0.5",
          "IPPrefixLen": 16,
          "IPv6Gateway": "",
          "MacAddress": "02:42:ac:1a:00:05",
          "Networks": {
            "bridge": {
              "IPAMConfig": null,
              "Links": null,
              "Aliases": null,
              "NetworkID": "24dcbba0a149182d3afd11c92333571fb791302e1db9f8f109d5adabc7361a37",
              "EndpointID": "6a89e5eabed28d033b94fe6d7a4a0eb456df2c5147049b85a5287d8457626ca2",
              "Gateway": "172.26.0.1",
              "IPAddress": "172.26.0.5",
              "IPPrefixLen": 16,
              "IPv6Gateway": "",
              "GlobalIPv6Address": "",
              "GlobalIPv6PrefixLen": 0,
              "MacAddress": "02:42:ac:1a:00:05",
              "DriverOpts": null
            }
          }
        }
      }
    ]



```bash

```
