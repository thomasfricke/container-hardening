# Hardening DotNet Containers

## Example 

Check out https://github.com/thomasfricke/dotnet-docker-hardening and go into `cd samples/aspnetapp`. 

There using 

```bash 

docker build --no-cache . -t aspnetapp -f Dockerfile.alpine-x64-slim

``` 

you create a standard dotnet image based on Alpine Slim.

Using 

```bash

docker build --no-cache . -t aspnetapp-harden -f Dockerfile.alpine-x64-slim.harden 

```

you create a hardened version of that image. Looking into the dockerfile `Dockerfile.alpine-x64-slim.harden` you see the use of the hardening script. By 

```bash 

docker run --rm -d  -e ASPNETCORE_URLS='http://*:5001/' -e COMPlus_EnableDiagnostics=0 -e DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1  --name aspnetapp-harden -p 5001:5001 aspnetapp-harden

```

you create a running container which shows the result at `localhost:5001`
