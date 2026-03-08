---
## Question 1 

There is a Dockerfile at /root/image/Dockerfile .

It’s a simple container which tries to make a curl call to an imaginary api with a secret token, the call will 404 , but that's okay.

Use specific version 20.04 for the base image
Remove layer caching issues with apt-get
Remove the hardcoded secret value 2e064aad-3a90–4cde-ad86–16fad1f8943e . The secret value should be passed into the container during runtime as env variable TOKEN
Make it impossible to podman exec , docker exec or kubectl exec into the container using bash
You can build the image using

```bash
cd /root/image
podman build .
```

### Solution:
```bash
# Before
controlplane:~$ cat /root/image/Dockerfile
FROM ubuntu
RUN apt-get update
RUN apt-get -y install curl
ENV URL https://google.com/this-will-fail?secret-token=
CMD ["sh", "-c", "curl --head $URL=2e064aad-3a90-4cde-ad86-16fad1f8943e"]

# After
controlplane:~$ cat Dockerfile 
FROM ubuntu:20.04
RUN apt-get update && apt-get -y install curl
ENV URL https://google.com/this-will-fail?secret-token=
RUN rm /usr/bin/bash
CMD ["sh", "-c", "curl --head $URL=$TOKEN"]
controlplane:~$ 

controlplane:~$ podman run -d -e TOKEN=2e064aad-3a90-4cde-ad86-16fad1f8943e app sleep 1d # run in background
1b762240e6f99c2c02cd6f13fb687f59d45b1eecc50be7079de6923cd2f7d19d
controlplane:~$ podman ps | grep app
1b762240e6f9  localhost/app:latest  sleep 1d    4 seconds ago  Up 4 seconds              stoic_margulis
controlplane:~$ podman exec -it 1b762240e bash
Error: runc: exec failed: unable to start container process: exec: "bash": executable file not found in $PATH: OCI runtime attempted to invoke a command that was not found
controlplane:~$ podman exec -it 1b762240e sh  
# ls  
bin  boot  dev  etc  home  lib  lib32  lib64  libx32  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
# exit
controlplane:~$ 
```